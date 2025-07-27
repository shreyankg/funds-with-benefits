import Foundation

struct NAVData: Codable, Identifiable {
    let id = UUID()
    let date: String
    let nav: String
    
    private enum CodingKeys: String, CodingKey {
        case date, nav
    }
    
    var navValue: Double {
        return Double(nav) ?? 0.0
    }
    
    var dateValue: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: date) ?? Date()
    }
    
    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM dd, yyyy"
        
        if let date = inputFormatter.date(from: date) {
            return outputFormatter.string(from: date)
        }
        return date
    }
}

struct FundHistory: Codable {
    let meta: FundMeta
    let data: [NAVData]
    let status: String?
    
    private enum CodingKeys: String, CodingKey {
        case meta, data, status
    }
}

struct FundMeta: Codable {
    let fund_house: String
    let scheme_type: String
    let scheme_category: String
    let scheme_code: String
    let scheme_name: String
    let isin_growth: String?
    let isin_div_reinvestment: String?
    
    private enum CodingKeys: String, CodingKey {
        case fund_house, scheme_type, scheme_category, scheme_code, scheme_name
        case isin_growth, isin_div_reinvestment
    }
    
    init(fund_house: String, scheme_type: String, scheme_category: String, scheme_code: String, scheme_name: String, isin_growth: String? = nil, isin_div_reinvestment: String? = nil) {
        self.fund_house = fund_house
        self.scheme_type = scheme_type
        self.scheme_category = scheme_category
        self.scheme_code = scheme_code
        self.scheme_name = scheme_name
        self.isin_growth = isin_growth
        self.isin_div_reinvestment = isin_div_reinvestment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        fund_house = try container.decode(String.self, forKey: .fund_house)
        scheme_type = try container.decode(String.self, forKey: .scheme_type)
        scheme_category = try container.decode(String.self, forKey: .scheme_category)
        scheme_name = try container.decode(String.self, forKey: .scheme_name)
        isin_growth = try container.decodeIfPresent(String.self, forKey: .isin_growth)
        isin_div_reinvestment = try container.decodeIfPresent(String.self, forKey: .isin_div_reinvestment)
        
        // Handle scheme_code as either Int or String
        if let schemeCodeInt = try? container.decode(Int.self, forKey: .scheme_code) {
            self.scheme_code = String(schemeCodeInt)
        } else {
            self.scheme_code = try container.decode(String.self, forKey: .scheme_code)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fund_house, forKey: .fund_house)
        try container.encode(scheme_type, forKey: .scheme_type)
        try container.encode(scheme_category, forKey: .scheme_category)
        try container.encode(scheme_code, forKey: .scheme_code)
        try container.encode(scheme_name, forKey: .scheme_name)
        try container.encodeIfPresent(isin_growth, forKey: .isin_growth)
        try container.encodeIfPresent(isin_div_reinvestment, forKey: .isin_div_reinvestment)
    }
}