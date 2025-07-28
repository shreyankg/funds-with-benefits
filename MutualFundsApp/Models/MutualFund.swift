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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle schemeCode as either Int or String
        if let schemeCodeInt = try? container.decode(Int.self, forKey: .schemeCode) {
            self.schemeCode = String(schemeCodeInt)
        } else {
            self.schemeCode = try container.decode(String.self, forKey: .schemeCode)
        }
        
        self.schemeName = try container.decode(String.self, forKey: .schemeName)
        self.isinGrowth = try container.decodeIfPresent(String.self, forKey: .isinGrowth)
        self.isinDivReinvestment = try container.decodeIfPresent(String.self, forKey: .isinDivReinvestment)
    }
    
    init(schemeCode: String, schemeName: String, isinGrowth: String? = nil, isinDivReinvestment: String? = nil) {
        self.schemeCode = schemeCode
        self.schemeName = schemeName
        self.isinGrowth = isinGrowth
        self.isinDivReinvestment = isinDivReinvestment
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemeCode, forKey: .schemeCode)
        try container.encode(schemeName, forKey: .schemeName)
        try container.encodeIfPresent(isinGrowth, forKey: .isinGrowth)
        try container.encodeIfPresent(isinDivReinvestment, forKey: .isinDivReinvestment)
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
    
    var isDirectPlan: Bool {
        return schemeName.lowercased().contains("direct")
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