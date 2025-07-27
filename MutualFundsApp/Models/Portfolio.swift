import Foundation

struct Portfolio: Codable {
    let holdings: [HoldingData]
    let summary: PortfolioSummary
    let lastUpdated: Date
    
    init(holdings: [HoldingData]) {
        self.holdings = holdings
        self.summary = PortfolioSummary(holdings: holdings)
        self.lastUpdated = Date()
    }
    
    // Category-wise breakdown
    var categoryBreakdown: [String: CategoryAllocation] {
        var breakdown: [String: CategoryAllocation] = [:]
        
        for holding in holdings {
            let category = holding.category
            if var allocation = breakdown[category] {
                allocation.investedValue += holding.investedValue
                allocation.currentValue += holding.currentValue
                allocation.returns += holding.returns
                allocation.holdingsCount += 1
                breakdown[category] = allocation
            } else {
                breakdown[category] = CategoryAllocation(
                    category: category,
                    investedValue: holding.investedValue,
                    currentValue: holding.currentValue,
                    returns: holding.returns,
                    holdingsCount: 1
                )
            }
        }
        
        return breakdown
    }
    
    // Source-wise breakdown (Groww, External, etc.)
    var sourceBreakdown: [String: SourceAllocation] {
        var breakdown: [String: SourceAllocation] = [:]
        
        for holding in holdings {
            let source = holding.source
            if var allocation = breakdown[source] {
                allocation.investedValue += holding.investedValue
                allocation.currentValue += holding.currentValue
                allocation.returns += holding.returns
                allocation.holdingsCount += 1
                breakdown[source] = allocation
            } else {
                breakdown[source] = SourceAllocation(
                    source: source,
                    investedValue: holding.investedValue,
                    currentValue: holding.currentValue,
                    returns: holding.returns,
                    holdingsCount: 1
                )
            }
        }
        
        return breakdown
    }
    
    // Top performers by returns percentage
    var topPerformers: [HoldingData] {
        return holdings.sorted { $0.returnsPercentage > $1.returnsPercentage }.prefix(5).map { $0 }
    }
    
    // Holdings with matched scheme codes (can navigate to fund details)
    var matchedHoldings: [HoldingData] {
        return holdings.filter { $0.matchedSchemeCode != nil }
    }
    
    // Holdings without matches (might need manual matching)
    var unmatchedHoldings: [HoldingData] {
        return holdings.filter { $0.matchedSchemeCode == nil }
    }
}

struct CategoryAllocation: Codable {
    let category: String
    var investedValue: Double
    var currentValue: Double
    var returns: Double
    var holdingsCount: Int
    
    var returnsPercentage: Double {
        guard investedValue > 0 else { return 0 }
        return (returns / investedValue) * 100
    }
    
    var allocationPercentage: Double = 0 // Will be calculated when needed
}

struct SourceAllocation: Codable {
    let source: String
    var investedValue: Double
    var currentValue: Double
    var returns: Double
    var holdingsCount: Int
    
    var returnsPercentage: Double {
        guard investedValue > 0 else { return 0 }
        return (returns / investedValue) * 100
    }
    
    var allocationPercentage: Double = 0 // Will be calculated when needed
}