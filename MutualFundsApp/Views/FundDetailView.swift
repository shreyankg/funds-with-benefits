import SwiftUI
import Charts

struct FundDetailView: View {
    let fund: MutualFund
    @StateObject private var viewModel = FundDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 200)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.loadFundDetails(for: fund)
                    }
                    .frame(height: 200)
                } else if let details = viewModel.fundDetails {
                    FundHeaderView(details: details)
                    
                    TimeRangeSelector(
                        selectedRange: $viewModel.selectedTimeRange,
                        currentTimeRange: viewModel.currentTimeRange,
                        onSelectionChange: { range in
                            viewModel.selectedTimeRange = range
                            viewModel.resetZoom()
                        }
                    )
                    
                    PerformanceChartView(
                        data: viewModel.chartData,
                        selectedRange: viewModel.currentTimeRange,
                        onZoomGesture: { translation in
                            viewModel.updateZoom(dragTranslation: translation)
                        },
                        viewModel: viewModel
                    )
                    .frame(minHeight: 250, maxHeight: 400)
                    
                    if let performance = viewModel.currentPerformance {
                        PerformanceMetricsView(
                            performance: performance,
                            timeRange: viewModel.currentTimeRange
                        )
                        .padding(.top, 20)
                    }
                    
                    FundInfoView(details: details)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(fund.schemeName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            viewModel.loadFundDetails(for: fund)
        }
    }
}

struct FundHeaderView: View {
    let details: FundDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current NAV")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("₹\(details.currentNAV.formatted(places: 4))")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily Change")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(details.formattedDailyChange)
                            .font(.headline)
                            .foregroundColor(details.dailyChange >= 0 ? .green : .red)
                        
                        Text(details.formattedDailyChangePercentage)
                            .font(.headline)
                            .foregroundColor(details.dailyChange >= 0 ? .green : .red)
                    }
                }
            }
            
            if let meta = details.meta {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meta.fund_house)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(meta.scheme_category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StartDateSelector: View {
    @ObservedObject var viewModel: FundDetailViewModel
    @State private var refreshTrigger = false
    @State private var lastSelectedDate: Date?
    
    var body: some View {
        DatePicker(
            "",
            selection: Binding(
                get: { viewModel.chartStartDate },
                set: { newDate in
                    let calendar = Calendar.current
                    let currentDate = viewModel.chartStartDate
                    
                    // Check if this is a complete date selection (day changed)
                    // vs just month/year navigation
                    let isDaySelection = lastSelectedDate == nil || 
                        !calendar.isDate(newDate, inSameDayAs: currentDate)
                    
                    // Check if user actually picked a different day (not just month/year navigation)
                    let isActualDateChange = lastSelectedDate == nil ||
                        !calendar.isDate(newDate, inSameDayAs: lastSelectedDate!)
                    
                    viewModel.updateZoomFromStartDate(newDate)
                    lastSelectedDate = newDate
                    
                    // Only dismiss if this was a complete date (day) selection
                    if isDaySelection && isActualDateChange {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            refreshTrigger.toggle()
                        }
                    }
                }
            ),
            in: dateRange,
            displayedComponents: [.date]
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .font(.caption2)
        .scaleEffect(0.9)
        .id(refreshTrigger)
        .onAppear {
            lastSelectedDate = viewModel.chartStartDate
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let endDate = Date()
        let calendar = Calendar.current
        
        // Earliest date: fund inception or 10 years ago, whichever is more recent
        let earliestAllowed = calendar.date(byAdding: .day, value: -viewModel.maxAllowedZoomDays, to: endDate) ?? endDate
        let fundInception = viewModel.fundInceptionDate ?? earliestAllowed
        let startDate = max(earliestAllowed, fundInception)
        
        // Latest date: 5 days ago (minimum zoom)
        let latestDate = calendar.date(byAdding: .day, value: -viewModel.minZoomDays, to: endDate) ?? endDate
        
        return startDate...latestDate
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    let currentTimeRange: TimeRange
    let onSelectionChange: (TimeRange) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(sortedRangesWithCustom.enumerated()), id: \.element) { index, timeRange in
                    if case .custom = timeRange {
                        // Custom range display
                        Text(timeRange.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } else {
                        // Standard range button
                        Button(action: {
                            onSelectionChange(timeRange)
                        }) {
                            Text(timeRange.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    isRangeActive(timeRange) ?
                                    Color.blue : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    isRangeActive(timeRange) ?
                                    .white : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var sortedRangesWithCustom: [TimeRange] {
        var ranges: [TimeRange] = []
        let standardRanges = TimeRange.allCases.sorted { $0.days < $1.days }
        
        if isCustomRange {
            // When custom range is shown, exclude 6M from standard ranges
            let filteredStandardRanges = standardRanges.filter { $0 != .sixMonths }
            let customDays = currentTimeRange.days
            var inserted = false
            
            for standardRange in filteredStandardRanges {
                // Insert custom range before the first standard range that has more days
                if !inserted && customDays < standardRange.days {
                    ranges.append(currentTimeRange)
                    inserted = true
                }
                ranges.append(standardRange)
            }
            
            // If custom range has more days than all standard ranges, add it at the end
            if !inserted {
                ranges.append(currentTimeRange)
            }
        } else {
            // When no custom range, show all standard ranges (including 6M)
            ranges = standardRanges
        }
        
        return ranges
    }
    
    private func isRangeActive(_ range: TimeRange) -> Bool {
        return currentTimeRange == range
    }
    
    private var isCustomRange: Bool {
        return !TimeRange.allCases.contains(currentTimeRange)
    }
}

struct PerformanceChartView: View {
    let data: [NAVData]
    let selectedRange: TimeRange
    let onZoomGesture: ((CGSize) -> Void)?
    @ObservedObject var viewModel: FundDetailViewModel
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    private var chartColor: Color {
        guard let firstValue = data.first?.navValue,
              let lastValue = data.last?.navValue else {
            return .blue // Default color when no data
        }
        return lastValue >= firstValue ? .green : .red
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StartDateSelector(viewModel: viewModel)
                    
                    Spacer()
                    
                    Text("Performance Chart")
                        .font(.headline)
                }
                
                if data.isEmpty {
                    Text("No data available for selected period")
                        .foregroundColor(.secondary)
                        .frame(height: max(200, geometry.size.height * 0.6))
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(data) { navData in
                        LineMark(
                            x: .value("Date", navData.dateValue),
                            y: .value("NAV", navData.navValue)
                        )
                        .foregroundStyle(chartColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Date", navData.dateValue),
                            y: .value("NAV", navData.navValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [chartColor.opacity(0.3), chartColor.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .opacity(isDragging ? 0.7 : 1.0)
                    .scaleEffect(isDragging ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                isDragging = false
                                onZoomGesture?(value.translation)
                                dragOffset = .zero
                            }
                    )
                    .frame(height: max(200, geometry.size.height * 0.6))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: xAxisStride)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatXAxisDate(date))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let navValue = value.as(Double.self) {
                                    Text("₹\(navValue.formatted(places: 2))")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: yAxisDomain)
                }
            }
            .padding(.horizontal, 4)
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }
        
        let navValues = data.map { $0.navValue }
        let minValue = navValues.min() ?? 0
        let maxValue = navValues.max() ?? 100
        
        // Add 5% padding to top and bottom for better visualization
        let range = maxValue - minValue
        let padding = max(range * 0.05, 0.01) // Minimum padding of 0.01
        
        let paddedMin = max(0, minValue - padding) // Don't go below 0 for NAV
        let paddedMax = maxValue + padding
        
        return paddedMin...paddedMax
    }
    
    private var xAxisStride: Calendar.Component {
        let days = selectedRange.days
        if days <= 7 {
            return .day
        } else if days <= 30 {
            return .weekOfYear
        } else if days <= 180 {
            return .month
        } else if days <= 365 {
            return .month
        } else {
            return .year
        }
    }
    
    private func formatXAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let days = selectedRange.days
        
        if days <= 7 {
            formatter.dateFormat = "MMM d"
        } else if days <= 30 {
            formatter.dateFormat = "MMM d"
        } else if days <= 180 {
            formatter.dateFormat = "MMM"
        } else if days <= 365 {
            formatter.dateFormat = "MMM"
        } else {
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: date)
    }
}

struct PerformanceMetricsView: View {
    let performance: FundPerformance
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
            
            HStack(spacing: 12) {
                MetricCard(
                    title: "Total Return",
                    value: performance.formattedTotalReturn,
                    subtitle: "",
                    color: performance.totalReturn >= 0 ? .green : .red
                )
                
                MetricCard(
                    title: "Volatility",
                    value: performance.formattedVolatility,
                    subtitle: "",
                    color: .orange
                )
                
                MetricCard(
                    title: "CAGR",
                    value: performance.formattedAnnualizedReturn,
                    subtitle: "",
                    color: performance.annualizedReturn >= 0 ? .green : .red
                )
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct FundInfoView: View {
    let details: FundDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fund Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "Scheme Code", value: details.fund.schemeCode)
                
                if let isin = details.fund.isinGrowth {
                    InfoRow(label: "ISIN (Growth)", value: isin)
                }
                
                if let isin = details.fund.isinDivReinvestment {
                    InfoRow(label: "ISIN (Dividend)", value: isin)
                }
                
                if let meta = details.meta {
                    InfoRow(label: "Fund House", value: meta.fund_house)
                    InfoRow(label: "Scheme Type", value: meta.scheme_type)
                    InfoRow(label: "Category", value: meta.scheme_category)
                }
                
                InfoRow(label: "Plan Type", value: details.fund.isGrowthPlan ? "Growth" : "Other")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        FundDetailView(fund: MutualFund(
            schemeCode: "101206",
            schemeName: "SBI Overnight Fund - Regular Plan - Growth",
            isinGrowth: "INF200K01LQ9",
            isinDivReinvestment: nil
        ))
    }
}