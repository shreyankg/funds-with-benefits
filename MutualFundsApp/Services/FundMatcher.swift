import Foundation

class FundMatcher: ObservableObject {
    static let shared = FundMatcher()
    
    private init() {}
    
    // Match holding names with API fund data
    func matchHoldingsWithFunds(_ holdings: [HoldingData], availableFunds: [MutualFund]) -> [HoldingData] {
        var matchedHoldings: [HoldingData] = []
        
        for holding in holdings {
            let matchedSchemeCode = findBestMatch(for: holding, in: availableFunds)
            
            var updatedHolding = holding
            if let schemeCode = matchedSchemeCode {
                // Create a new HoldingData with the matched scheme code
                updatedHolding = HoldingData(
                    schemeName: holding.schemeName,
                    amcName: holding.amcName,
                    category: holding.category,
                    subCategory: holding.subCategory,
                    folioNumber: holding.folioNumber,
                    source: holding.source,
                    units: holding.units,
                    investedValue: holding.investedValue,
                    currentValue: holding.currentValue,
                    returns: holding.returns,
                    xirr: holding.xirr,
                    matchedSchemeCode: schemeCode
                )
            }
            
            matchedHoldings.append(updatedHolding)
        }
        
        return matchedHoldings
    }
    
    // Find best matching fund for a holding
    private func findBestMatch(for holding: HoldingData, in funds: [MutualFund]) -> String? {
        let holdingName = holding.schemeName.lowercased()
        let holdingAMC = holding.amcName.lowercased()
        
        var bestMatch: MutualFund?
        var highestScore = 0.0
        
        for fund in funds {
            let score = calculateMatchScore(holding: holding, fund: fund)
            
            if score > highestScore && score > 0.7 { // Minimum 70% match required
                highestScore = score
                bestMatch = fund
            }
        }
        
        return bestMatch?.schemeCode
    }
    
    // Calculate match score between holding and fund
    private func calculateMatchScore(holding: HoldingData, fund: MutualFund) -> Double {
        let holdingName = holding.schemeName.lowercased()
        let fundName = fund.schemeName.lowercased()
        
        // Normalize names for comparison
        let normalizedHoldingName = normalizeNameForMatching(holdingName)
        let normalizedFundName = normalizeNameForMatching(fundName)
        
        var score = 0.0
        
        // 1. Exact match gets highest score
        if normalizedHoldingName == normalizedFundName {
            return 1.0
        }
        
        // 2. Check key components match
        let holdingComponents = normalizedHoldingName.components(separatedBy: .whitespaces)
        let fundComponents = normalizedFundName.components(separatedBy: .whitespaces)
        
        // AMC/Fund House matching
        let holdingAMC = holding.amcName.lowercased()
        let fundHouse = fund.fundHouse.lowercased()
        
        if matchesAMC(holdingAMC: holdingAMC, fundHouse: fundHouse) {
            score += 0.3 // 30% for AMC match
        }
        
        // Scheme name component matching
        let commonWords = Set(holdingComponents).intersection(Set(fundComponents))
        let uniqueWords = Set(holdingComponents).union(Set(fundComponents))
        
        if uniqueWords.count > 0 {
            let wordMatchRatio = Double(commonWords.count) / Double(uniqueWords.count)
            score += wordMatchRatio * 0.5 // 50% for word matching
        }
        
        // Plan type matching (Growth, Direct, etc.)
        if matchesPlanType(holdingName: holdingName, fundName: fundName) {
            score += 0.2 // 20% for plan type match
        }
        
        return score
    }
    
    // Normalize fund names for better matching
    private func normalizeNameForMatching(_ name: String) -> String {
        var normalized = name.lowercased()
        
        // Common replacements
        let replacements = [
            "direct growth": "direct-growth",
            "regular growth": "regular-growth",
            "dividend reinvestment": "dividend-reinv",
            "fund of fund": "fof",
            "fund of funds": "fof",
            "&": "and",
            "ltd": "limited",
            "ltd.": "limited",
            "  ": " " // Multiple spaces to single space
        ]
        
        for (old, new) in replacements {
            normalized = normalized.replacingOccurrences(of: old, with: new)
        }
        
        // Remove common suffixes/prefixes that might cause mismatches
        let wordsToRemove = ["plan", "scheme", "-", "(", ")", "[", "]"]
        for word in wordsToRemove {
            normalized = normalized.replacingOccurrences(of: word, with: " ")
        }
        
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Check if AMC names match
    private func matchesAMC(holdingAMC: String, fundHouse: String) -> Bool {
        let normalizedHoldingAMC = holdingAMC.lowercased()
        let normalizedFundHouse = fundHouse.lowercased()
        
        // Direct match
        if normalizedHoldingAMC.contains(normalizedFundHouse) || 
           normalizedFundHouse.contains(normalizedHoldingAMC) {
            return true
        }
        
        // Check for common AMC variations
        let amcMappings = [
            "sbi": ["sbi", "state bank"],
            "icici": ["icici", "icici prudential"],
            "axis": ["axis"],
            "hdfc": ["hdfc"],
            "kotak": ["kotak", "kotak mahindra"],
            "aditya birla": ["aditya", "birla", "aditya birla sun life"],
            "franklin": ["franklin", "franklin templeton"],
            "mirae": ["mirae", "mirae asset"],
            "nippon": ["nippon", "nippon india"],
            "tata": ["tata"],
            "dsp": ["dsp"],
            "motilal": ["motilal", "motilal oswal"],
            "parag parikh": ["parag", "parikh", "ppfas"],
            "quant": ["quant"],
            "navi": ["navi"],
            "groww": ["groww"],
            "canara": ["canara", "canara robeco"],
            "360": ["360", "360 one"],
            "mahindra": ["mahindra", "mahindra manulife"],
            "bandhan": ["bandhan"]
        ]
        
        for (key, variations) in amcMappings {
            let holdingMatchesKey = variations.contains { normalizedHoldingAMC.contains($0) }
            let fundMatchesKey = variations.contains { normalizedFundHouse.contains($0) }
            
            if holdingMatchesKey && fundMatchesKey {
                return true
            }
        }
        
        return false
    }
    
    // Check if plan types match
    private func matchesPlanType(holdingName: String, fundName: String) -> Bool {
        let holding = holdingName.lowercased()
        let fund = fundName.lowercased()
        
        // Both should have same plan type
        let planTypes = ["growth", "dividend", "idcw", "direct", "regular"]
        
        for planType in planTypes {
            let holdingHas = holding.contains(planType)
            let fundHas = fund.contains(planType)
            
            if holdingHas != fundHas {
                return false // Mismatch in plan type
            }
        }
        
        return true // All plan types match or both don't have them
    }
    
    // Get match confidence for UI display
    func getMatchConfidence(for holding: HoldingData, fund: MutualFund) -> MatchConfidence {
        let score = calculateMatchScore(holding: holding, fund: fund)
        
        switch score {
        case 0.9...1.0:
            return .high
        case 0.8..<0.9:
            return .medium
        case 0.7..<0.8:
            return .low
        default:
            return .none
        }
    }
}

enum MatchConfidence: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case none = "No Match"
    
    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "orange"
        case .low: return "yellow"
        case .none: return "red"
        }
    }
}