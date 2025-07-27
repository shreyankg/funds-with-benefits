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
}

struct FundMeta: Codable {
    let fund_house: String
    let scheme_type: String
    let scheme_category: String
    let scheme_code: String
    let scheme_name: String
}