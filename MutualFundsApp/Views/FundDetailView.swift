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
                        selectedRange: $viewModel.selectedTimeRange
                    )
                    
                    PerformanceChartView(
                        data: viewModel.chartData,
                        selectedRange: viewModel.selectedTimeRange
                    )
                    .frame(minHeight: 300, maxHeight: 600)
                    
                    if let performance = viewModel.currentPerformance {
                        PerformanceMetricsView(
                            performance: performance,
                            timeRange: viewModel.selectedTimeRange
                        )
                    }
                    
                    FundInfoView(details: details)
                }
            }
            .padding()
        }
        .navigationTitle(fund.schemeName)
        .navigationBarTitleDisplayMode(.inline)
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

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedRange = range
                    }) {
                        Text(range.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedRange == range ?
                                Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedRange == range ?
                                .white : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PerformanceChartView: View {
    let data: [NAVData]
    let selectedRange: TimeRange
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Chart")
                    .font(.headline)
                
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
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Date", navData.dateValue),
                            y: .value("NAV", navData.navValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: max(250, geometry.size.height * 0.7))
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
            .padding()
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
        switch selectedRange {
        case .oneWeek: return .day
        case .oneMonth: return .weekOfYear
        case .sixMonths: return .month
        case .oneYear: return .month
        case .threeYears: return .year
        }
    }
    
    private func formatXAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedRange {
        case .oneWeek:
            formatter.dateFormat = "MMM d"
        case .oneMonth:
            formatter.dateFormat = "MMM d"
        case .sixMonths:
            formatter.dateFormat = "MMM"
        case .oneYear:
            formatter.dateFormat = "MMM"
        case .threeYears:
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
            
            HStack(spacing: 20) {
                MetricCard(
                    title: "Total Return",
                    value: performance.formattedTotalReturn,
                    subtitle: timeRange.displayName,
                    color: performance.totalReturn >= 0 ? .green : .red
                )
                
                MetricCard(
                    title: "Annualized Return",
                    value: performance.formattedAnnualizedReturn,
                    subtitle: "CAGR",
                    color: performance.annualizedReturn >= 0 ? .green : .red
                )
            }
            
            MetricCard(
                title: "Volatility",
                value: performance.formattedVolatility,
                subtitle: "Risk Measure",
                color: .orange
            )
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
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