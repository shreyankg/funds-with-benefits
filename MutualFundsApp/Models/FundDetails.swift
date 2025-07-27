import Foundation

struct FundDetails {
    let fund: MutualFund
    let history: [NAVData]
    let meta: FundMeta?
    
    var currentNAV: Double {
        return history.first?.navValue ?? 0.0
    }
    
    var previousNAV: Double {
        return history.count > 1 ? history[1].navValue : 0.0
    }
    
    var dailyChange: Double {
        return currentNAV - previousNAV
    }
    
    var dailyChangePercentage: Double {
        guard previousNAV > 0 else { return 0.0 }
        return (dailyChange / previousNAV) * 100
    }
    
    var formattedDailyChange: String {
        let sign = dailyChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", dailyChange))"
    }
    
    var formattedDailyChangePercentage: String {
        let sign = dailyChangePercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", dailyChangePercentage))%"
    }
    
    func performanceForPeriod(_ period: TimeRange) -> FundPerformance? {
        let filteredData = getDataForPeriod(period)
        guard filteredData.count >= 2,
              let latestValue = filteredData.first?.navValue,
              let oldestValue = filteredData.last?.navValue else {
            return nil
        }
        
        let totalReturn = ((latestValue - oldestValue) / oldestValue) * 100
        let days = Calendar.current.dateComponents([.day], 
                                                  from: filteredData.last!.dateValue, 
                                                  to: filteredData.first!.dateValue).day ?? 0
        
        let annualizedReturn: Double
        if days > 0 {
            let years = Double(days) / 365.25
            annualizedReturn = (pow(latestValue / oldestValue, 1.0 / years) - 1) * 100
        } else {
            annualizedReturn = 0
        }
        
        return FundPerformance(
            totalReturn: totalReturn,
            annualizedReturn: annualizedReturn,
            volatility: calculateVolatility(filteredData)
        )
    }
    
    private func getDataForPeriod(_ period: TimeRange) -> [NAVData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch period {
        case .oneWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .threeYears:
            startDate = calendar.date(byAdding: .year, value: -3, to: endDate) ?? endDate
        }
        
        return history.filter { navData in
            navData.dateValue >= startDate
        }.sorted { $0.dateValue > $1.dateValue }
    }
    
    private func calculateVolatility(_ data: [NAVData]) -> Double {
        guard data.count > 1 else { return 0.0 }
        
        let returns = data.enumerated().compactMap { index, current -> Double? in
            guard index < data.count - 1 else { return nil }
            let previous = data[index + 1]
            return (current.navValue - previous.navValue) / previous.navValue
        }
        
        guard !returns.isEmpty else { return 0.0 }
        
        let meanReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - meanReturn, 2) }.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance) * sqrt(252) * 100 // Annualized volatility in percentage
    }
}

struct FundPerformance {
    let totalReturn: Double
    let annualizedReturn: Double
    let volatility: Double
    
    var formattedTotalReturn: String {
        let sign = totalReturn >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", totalReturn))%"
    }
    
    var formattedAnnualizedReturn: String {
        let sign = annualizedReturn >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", annualizedReturn))%"
    }
    
    var formattedVolatility: String {
        return "\(String(format: "%.2f", volatility))%"
    }
}

enum TimeRange: String, CaseIterable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
    
    var displayName: String {
        return rawValue
    }
}