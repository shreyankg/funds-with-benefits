import SwiftUI

struct PortfolioSummaryView: View {
    let summary: PortfolioSummary
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Portfolio Values
            VStack(spacing: 12) {
                HStack {
                    Text("Portfolio Value")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(summary.currentPortfolioValue.formatted(.currency(code: "INR")))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invested")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(summary.totalInvestments.formatted(.currency(code: "INR")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Returns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(summary.totalReturns.formatted(.currency(code: "INR")))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(summary.totalReturns >= 0 ? .green : .red)
                            
                            Text("(\(summary.returnsPercentage.formatted(.number.precision(.fractionLength(2))))%)")
                                .font(.caption)
                                .foregroundColor(summary.totalReturns >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // XIRR and Holdings Count
            HStack(spacing: 16) {
                // XIRR Card
                VStack(spacing: 8) {
                    Text("XIRR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(summary.overallXIRR.formatted(.number.precision(.fractionLength(2))))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(summary.overallXIRR >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Holdings Count Card
                VStack(spacing: 8) {
                    Text("Holdings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(summary.holdingsCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Performance Indicators
            HStack(spacing: 12) {
                performanceIndicator(
                    title: "1D Change",
                    value: calculateDailyChange(),
                    icon: "arrow.up.right"
                )
                
                Divider()
                
                performanceIndicator(
                    title: "Overall",
                    value: summary.returnsPercentage,
                    icon: summary.returnsPercentage >= 0 ? "arrow.up.right" : "arrow.down.right"
                )
                
                Divider()
                
                performanceIndicator(
                    title: "XIRR",
                    value: summary.overallXIRR,
                    icon: summary.overallXIRR >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis"
                )
            }
            .frame(height: 60)
        }
    }
    
    @ViewBuilder
    private func performanceIndicator(title: String, value: Double, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(value >= 0 ? .green : .red)
            
            Text("\(value.formatted(.number.precision(.fractionLength(2))))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(value >= 0 ? .green : .red)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func calculateDailyChange() -> Double {
        // This would ideally be calculated from real-time NAV data
        // For now, return a placeholder or calculate from available data
        return 0.0 // Placeholder
    }
}

#Preview {
    PortfolioSummaryView(
        summary: PortfolioSummary(holdings: [
            HoldingData(
                schemeName: "SBI Conservative Hybrid Fund Direct Growth",
                amcName: "SBI Mutual Fund",
                category: "Hybrid",
                subCategory: "Conservative Hybrid",
                folioNumber: "22821659",
                source: "External",
                units: 610.664,
                investedValue: 32931.93,
                currentValue: 48581.37,
                returns: 15649.44,
                xirr: 10.19
            )
        ])
    )
    .padding()
}