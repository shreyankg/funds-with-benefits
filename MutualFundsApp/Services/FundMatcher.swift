import Foundation

class FundMatcher: ObservableObject {
    static let shared = FundMatcher()
    
    // Performance optimization: Cache preprocessing results
    private var fundPreprocessingCache: [String: PreprocessedFund] = [:]
    private var amcLookupIndex: [String: [MutualFund]] = [:]
    private var normalizedNameCache: [String: String] = [:]
    private var similarityScoreCache: [String: Double] = [:]
    
    private struct PreprocessedFund {
        let fund: MutualFund
        let normalizedName: String
        let normalizedAMC: String
        let coreName: String
        let keyTerms: Set<String>
    }
    
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
        
        var bestMatch: MutualFund?
        var highestScore = 0.0
        
        for fund in funds {
            var score = calculateMatchScore(holding: holding, fund: fund)
            
            // Prioritize Direct and Growth plans separately
            if fund.isDirectPlan {
                score += 0.05 // 5% bonus for Direct plans (lower expense ratios)
            }
            
            if fund.isGrowthPlan {
                score += 0.05 // 5% bonus for Growth plans (more common than dividend)
            }
            
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
        
        // 2. AMC/Fund House matching (25% weight)
        let holdingAMC = holding.amcName.lowercased()
        let fundHouse = fund.fundHouse.lowercased()
        
        if matchesAMC(holdingAMC: holdingAMC, fundHouse: fundHouse) {
            score += 0.25 // 25% for AMC match
        }
        
        // 3. Enhanced fund name similarity matching (45% weight)
        let fundNameScore = calculateFundNameSimilarity(
            holdingName: normalizedHoldingName,
            fundName: normalizedFundName
        )
        score += fundNameScore * 0.45
        
        // 4. Plan type matching (20% weight)
        if matchesPlanType(holdingName: holdingName, fundName: fundName) {
            score += 0.2 // 20% for plan type match
        }
        
        // 5. Category matching bonus (10% weight)
        let categoryScore = calculateCategoryMatch(holding: holding, fund: fund)
        score += categoryScore * 0.1
        
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
        
        for (_, variations) in amcMappings {
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
    
    // Enhanced fund name similarity calculation
    private func calculateFundNameSimilarity(holdingName: String, fundName: String) -> Double {
        // Remove common suffixes/prefixes for core name comparison
        let holdingCore = extractCoreFundName(holdingName)
        let fundCore = extractCoreFundName(fundName)
        
        var similarity = 0.0
        
        // 1. Core name exact match (highest weight)
        if holdingCore == fundCore {
            similarity += 0.4
        }
        
        // 2. Word-based similarity matching
        let holdingWords = Set(holdingCore.components(separatedBy: .whitespaces).filter { !$0.isEmpty })
        let fundWords = Set(fundCore.components(separatedBy: .whitespaces).filter { !$0.isEmpty })
        
        let commonWords = holdingWords.intersection(fundWords)
        let totalWords = holdingWords.union(fundWords)
        
        if !totalWords.isEmpty {
            let jaccardSimilarity = Double(commonWords.count) / Double(totalWords.count)
            similarity += jaccardSimilarity * 0.3
        }
        
        // 3. Key financial terms matching (gives bonus for similar fund types)
        let keyTerms = extractKeyFinancialTerms(holdingCore, fundCore)
        similarity += keyTerms * 0.2
        
        // 4. String distance similarity (for partial matches)
        let distanceSimilarity = calculateLevenshteinSimilarity(holdingCore, fundCore)
        similarity += distanceSimilarity * 0.1
        
        return min(similarity, 1.0) // Cap at 1.0
    }
    
    // Extract core fund name by removing common prefixes/suffixes
    private func extractCoreFundName(_ name: String) -> String {
        var core = name
        
        // Remove plan type suffixes
        let planSuffixes = ["direct growth", "growth", "direct plan growth", "plan growth", 
                           "dividend", "idcw", "regular growth", "regular plan growth"]
        for suffix in planSuffixes {
            if core.hasSuffix(suffix) {
                core = String(core.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Remove fund type suffixes
        let fundSuffixes = ["fund", "scheme"]
        for suffix in fundSuffixes {
            if core.hasSuffix(suffix) {
                core = String(core.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        return core.trimmingCharacters(in: .whitespaces)
    }
    
    // Extract and match key financial terms
    private func extractKeyFinancialTerms(_ holding: String, _ fund: String) -> Double {
        let financialTerms = [
            // Fund categories
            "flexi cap", "flexicap", "large cap", "mid cap", "midcap", "small cap", "smallcap",
            "multi cap", "multicap", "value", "growth", "blend", "focused", "conservative",
            
            // Investment styles  
            "equity", "debt", "hybrid", "balanced", "liquid", "overnight", "short duration",
            "medium duration", "long duration", "gilt", "credit", "dynamic", "aggressive",
            
            // Sectoral/Thematic
            "banking", "pharma", "technology", "infrastructure", "consumption", "energy",
            "healthcare", "financial", "auto", "metals", "fmcg", "textile", "realty",
            
            // Specialty
            "elss", "tax saver", "pension", "retirement", "child", "arbitrage", "index",
            "etf", "fof", "fund of fund", "international", "global", "emerging", "dividend",
            "momentum", "alpha", "beta", "innovation", "opportunities", "special situations"
        ]
        
        let holdingTerms = Set(financialTerms.filter { holding.contains($0) })
        let fundTerms = Set(financialTerms.filter { fund.contains($0) })
        
        let commonTerms = holdingTerms.intersection(fundTerms)
        let totalTerms = holdingTerms.union(fundTerms)
        
        guard !totalTerms.isEmpty else { return 0.0 }
        
        return Double(commonTerms.count) / Double(totalTerms.count)
    }
    
    // Calculate Levenshtein distance similarity
    private func calculateLevenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        
        guard maxLength > 0 else { return 1.0 }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    // Levenshtein distance implementation
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a1 = Array(s1)
        let a2 = Array(s2)
        
        var distances = Array(0...a2.count)
        
        for (i, char1) in a1.enumerated() {
            var newDistances = [i + 1]
            
            for (j, char2) in a2.enumerated() {
                let cost = char1 == char2 ? 0 : 1
                let minDistance = min(
                    distances[j + 1] + 1,     // deletion
                    newDistances[j] + 1,      // insertion  
                    distances[j] + cost       // substitution
                )
                newDistances.append(minDistance)
            }
            
            distances = newDistances
        }
        
        return distances.last ?? 0
    }
    
    // Calculate category matching score
    private func calculateCategoryMatch(holding: HoldingData, fund: MutualFund) -> Double {
        let holdingCategory = holding.category.lowercased()
        let fundCategory = fund.category.lowercased()
        
        // Exact category match
        if holdingCategory == fundCategory {
            return 1.0
        }
        
        // Partial category matches (e.g., "Equity" matches with equity subcategories)
        let categoryMappings: [String: Set<String>] = [
            "equity": ["equity", "large cap", "mid cap", "small cap", "flexi cap", "multi cap", "value", "thematic", "sectoral"],
            "debt": ["debt", "liquid", "overnight", "short duration", "medium duration", "long duration", "gilt", "credit"],
            "hybrid": ["hybrid", "balanced", "conservative", "aggressive", "dynamic asset allocation", "multi asset"],
            "commodities": ["commodities", "gold", "silver", "commodity"]
        ]
        
        for (_, variants) in categoryMappings {
            let holdingMatches = variants.contains { holdingCategory.contains($0) }
            let fundMatches = variants.contains { fundCategory.contains($0) }
            
            if holdingMatches && fundMatches {
                return 0.8 // High similarity for same category family
            }
        }
        
        return 0.0 // No category match
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