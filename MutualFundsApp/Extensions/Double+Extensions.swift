import Foundation

extension Double {
    func formatted(places: Int = 2) -> String {
        return String(format: "%.\(places)f", self)
    }
    
    func formattedWithSign(places: Int = 2) -> String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.\(places)f", self))"
    }
    
    func formattedAsPercentage(places: Int = 2) -> String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.\(places)f", self))%"
    }
    
    func formattedAsCurrency(symbol: String = "₹") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: self)) ?? "\(symbol)\(self.formatted())"
    }
    
    func formattedWithCommas() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: self)) ?? self.formatted()
    }
}