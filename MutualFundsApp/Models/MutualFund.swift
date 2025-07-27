import Foundation

struct MutualFund: Codable, Identifiable, Hashable {
    let id = UUID()
    let schemeCode: String
    let schemeName: String
    let isinGrowth: String?
    let isinDivReinvestment: String?
    
    private enum CodingKeys: String, CodingKey {
        case schemeCode, schemeName, isinGrowth, isinDivReinvestment
    }
    
    var fundHouse: String {
        let components = schemeName.components(separatedBy: " ")
        if let firstComponent = components.first {
            return firstComponent
        }
        return "Unknown"
    }
    
    var isGrowthPlan: Bool {
        return schemeName.lowercased().contains("growth")
    }
    
    var isDividendPlan: Bool {
        return schemeName.lowercased().contains("dividend") || 
               schemeName.lowercased().contains("idcw")
    }
    
    var category: String {
        let name = schemeName.lowercased()
        if name.contains("equity") || name.contains("large cap") || name.contains("mid cap") || name.contains("small cap") {
            return "Equity"
        } else if name.contains("debt") || name.contains("liquid") || name.contains("bond") {
            return "Debt"
        } else if name.contains("hybrid") || name.contains("balanced") {
            return "Hybrid"
        } else {
            return "Other"
        }
    }
}