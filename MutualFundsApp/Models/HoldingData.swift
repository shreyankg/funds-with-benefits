import Foundation

struct HoldingData: Codable, Identifiable, Hashable {
    let id = UUID()
    let schemeName: String
    let amcName: String
    let category: String
    let subCategory: String
    let folioNumber: String
    let source: String
    let units: Double
    let investedValue: Double
    
    // Original values from holdings file (for reference)
    let originalCurrentValue: Double
    let originalReturns: Double
    let originalXirr: Double
    
    // Live calculated values using latest NAV
    var latestNAV: Double?
    var statementDate: Date?
    
    // Live calculated properties using latest NAV
    var currentValue: Double {
        guard let nav = latestNAV, units > 0 else {
            return originalCurrentValue // Fallback to original if no NAV
        }
        return units * nav
    }
    
    var returns: Double {
        return currentValue - investedValue
    }
    
    var returnsPercentage: Double {
        guard investedValue > 0 else { return 0 }
        return (returns / investedValue) * 100
    }
    
    var xirr: Double {
        // Calculate XIRR using simple annualized return if we have statement date
        guard let statementDate = statementDate, 
              investedValue > 0,
              currentValue > 0 else {
            return originalXirr // Fallback to original
        }
        
        let daysDifference = Date().timeIntervalSince(statementDate) / (24 * 60 * 60)
        let yearsDifference = daysDifference / 365.25
        
        guard yearsDifference > 0 else {
            return originalXirr
        }
        
        // Simple annualized return calculation: ((Current/Invested)^(1/years) - 1) * 100
        let annualizedReturn = pow(currentValue / investedValue, 1.0 / yearsDifference) - 1.0
        return annualizedReturn * 100
    }
    
    var navPerUnit: Double {
        guard units > 0 else { return 0 }
        return currentValue / units
    }
    
    // For matching with MutualFund API data
    var matchedSchemeCode: String?
    
    private enum CodingKeys: String, CodingKey {
        case schemeName, amcName, category, subCategory, folioNumber, source
        case units, investedValue, originalCurrentValue, originalReturns, originalXirr
        case matchedSchemeCode, latestNAV, statementDate
    }
    
    init(schemeName: String, amcName: String, category: String, subCategory: String, 
         folioNumber: String, source: String, units: Double, investedValue: Double, 
         currentValue: Double, returns: Double, xirr: Double, matchedSchemeCode: String? = nil,
         latestNAV: Double? = nil, statementDate: Date? = nil) {
        self.schemeName = schemeName
        self.amcName = amcName
        self.category = category
        self.subCategory = subCategory
        self.folioNumber = folioNumber
        self.source = source
        self.units = units
        self.investedValue = investedValue
        self.originalCurrentValue = currentValue
        self.originalReturns = returns
        self.originalXirr = xirr
        self.matchedSchemeCode = matchedSchemeCode
        self.latestNAV = latestNAV
        self.statementDate = statementDate
    }
    
    // Helper function to create from parsed data
    static func from(parsedData: [String: String]) -> HoldingData? {
        guard let schemeName = parsedData["schemeName"],
              let amcName = parsedData["amcName"],
              let category = parsedData["category"],
              let subCategory = parsedData["subCategory"],
              let folioNumber = parsedData["folioNumber"],
              let source = parsedData["source"],
              let unitsStr = parsedData["units"],
              let investedValueStr = parsedData["investedValue"],
              let currentValueStr = parsedData["currentValue"],
              let returnsStr = parsedData["returns"],
              let xirrStr = parsedData["xirr"],
              let units = Double(unitsStr),
              let investedValue = Double(investedValueStr),
              let currentValue = Double(currentValueStr),
              let returns = Double(returnsStr),
              let xirr = Double(xirrStr.replacingOccurrences(of: "%", with: "")) else {
            return nil
        }
        
        return HoldingData(
            schemeName: schemeName.trimmingCharacters(in: .whitespacesAndNewlines),
            amcName: amcName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            subCategory: subCategory.trimmingCharacters(in: .whitespacesAndNewlines),
            folioNumber: folioNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            source: source.trimmingCharacters(in: .whitespacesAndNewlines),
            units: units,
            investedValue: investedValue,
            currentValue: currentValue,
            returns: returns,
            xirr: xirr
            // Note: No statementDate set, so it defaults to nil and xirr will use originalXirr
        )
    }
}

// Portfolio summary calculations
struct PortfolioSummary: Codable {
    let totalInvestments: Double
    let currentPortfolioValue: Double
    let totalReturns: Double
    let returnsPercentage: Double
    let overallXIRR: Double
    let holdingsCount: Int
    
    init(holdings: [HoldingData]) {
        self.holdingsCount = holdings.count
        self.totalInvestments = holdings.reduce(0) { $0 + $1.investedValue }
        self.currentPortfolioValue = holdings.reduce(0) { $0 + $1.currentValue }
        self.totalReturns = holdings.reduce(0) { $0 + $1.returns }
        
        if totalInvestments > 0 {
            self.returnsPercentage = (totalReturns / totalInvestments) * 100
        } else {
            self.returnsPercentage = 0
        }
        
        // Calculate weighted average XIRR based on invested amounts
        let totalInvested = self.totalInvestments
        if totalInvested > 0 {
            let weightedXIRR = holdings.reduce(0) { result, holding in
                let weight = holding.investedValue / totalInvested
                return result + (holding.xirr * weight)
            }
            self.overallXIRR = weightedXIRR
        } else {
            self.overallXIRR = 0
        }
    }
}