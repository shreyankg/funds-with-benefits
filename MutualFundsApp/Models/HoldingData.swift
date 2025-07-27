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
    let currentValue: Double
    let returns: Double
    let xirr: Double
    
    // Computed properties
    var returnsPercentage: Double {
        guard investedValue > 0 else { return 0 }
        return (returns / investedValue) * 100
    }
    
    var navPerUnit: Double {
        guard units > 0 else { return 0 }
        return currentValue / units
    }
    
    // For matching with MutualFund API data
    var matchedSchemeCode: String?
    
    private enum CodingKeys: String, CodingKey {
        case schemeName, amcName, category, subCategory, folioNumber, source
        case units, investedValue, currentValue, returns, xirr, matchedSchemeCode
    }
    
    init(schemeName: String, amcName: String, category: String, subCategory: String, 
         folioNumber: String, source: String, units: Double, investedValue: Double, 
         currentValue: Double, returns: Double, xirr: Double, matchedSchemeCode: String? = nil) {
        self.schemeName = schemeName
        self.amcName = amcName
        self.category = category
        self.subCategory = subCategory
        self.folioNumber = folioNumber
        self.source = source
        self.units = units
        self.investedValue = investedValue
        self.currentValue = currentValue
        self.returns = returns
        self.xirr = xirr
        self.matchedSchemeCode = matchedSchemeCode
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