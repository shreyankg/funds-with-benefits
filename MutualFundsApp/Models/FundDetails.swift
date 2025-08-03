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
        let startDate = calendar.date(byAdding: .day, value: -period.days, to: endDate) ?? endDate
        
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

enum TimeRange: Equatable, CaseIterable, Hashable {
    case oneWeek
    case oneMonth
    case sixMonths
    case oneYear
    case threeYears
    case custom(days: Int)
    
    static var allCases: [TimeRange] {
        return [.oneWeek, .oneMonth, .sixMonths, .oneYear, .threeYears]
    }
    
    var days: Int {
        switch self {
        case .oneWeek:
            return 7
        case .oneMonth:
            return 30
        case .sixMonths:
            return 180
        case .oneYear:
            return 365
        case .threeYears:
            return 1095
        case .custom(let days):
            return days
        }
    }
    
    var displayName: String {
        switch self {
        case .oneWeek:
            return "1W"
        case .oneMonth:
            return "1M"
        case .sixMonths:
            return "6M"
        case .oneYear:
            return "1Y"
        case .threeYears:
            return "3Y"
        case .custom(let days):
            return formatCustomPeriod(days: days)
        }
    }
    
    private func formatCustomPeriod(days: Int) -> String {
        if days < 30 {
            let weeks = Double(days) / 7.0
            return String(format: "%.1fW", weeks)
        } else if days < 365 {
            let months = Double(days) / 30.0
            return String(format: "%.1fM", months)
        } else {
            let years = Double(days) / 365.0
            return String(format: "%.1fY", years)
        }
    }
    
    init(days: Int) {
        switch days {
        case 7:
            self = .oneWeek
        case 30:
            self = .oneMonth
        case 180:
            self = .sixMonths
        case 365:
            self = .oneYear
        case 1095:
            self = .threeYears
        default:
            self = .custom(days: days)
        }
    }
}