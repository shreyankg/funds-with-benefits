import Foundation
import PDFKit
import UniformTypeIdentifiers

class HoldingsParser: ObservableObject {
    static let shared = HoldingsParser()
    
    private init() {}
    
    enum ParsingError: Error, LocalizedError {
        case unsupportedFileType
        case pdfReadError
        case dataExtractionError
        case invalidDataFormat
        
        var errorDescription: String? {
            switch self {
            case .unsupportedFileType:
                return "Unsupported file type. Please upload a PDF or CSV file."
            case .pdfReadError:
                return "Failed to read PDF file. Please check if the file is corrupted."
            case .dataExtractionError:
                return "Failed to extract holdings data from the file."
            case .invalidDataFormat:
                return "The file format is not recognized as a valid holdings statement."
            }
        }
    }
    
    // Main parsing function
    func parseHoldingsFile(from url: URL) async throws -> [HoldingData] {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try await parsePDFFile(from: url)
        case "csv":
            return try await parseCSVFile(from: url)
        default:
            throw ParsingError.unsupportedFileType
        }
    }
    
    // Parse PDF holdings statement
    private func parsePDFFile(from url: URL) async throws -> [HoldingData] {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ParsingError.pdfReadError
        }
        
        var extractedText = ""
        
        // Extract text from all pages
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageText = page.string else {
                continue
            }
            extractedText += pageText + "\n"
        }
        
        return try parseHoldingsText(extractedText)
    }
    
    // Parse CSV holdings file
    private func parseCSVFile(from url: URL) async throws -> [HoldingData] {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        return try parseCSVContent(csvContent)
    }
    
    // Parse extracted text to find holdings data
    internal func parseHoldingsText(_ text: String) throws -> [HoldingData] {
        var holdings: [HoldingData] = []
        let lines = text.components(separatedBy: .newlines)
        
        var isInHoldingsSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for holdings section start
            if trimmedLine.contains("HOLDINGS AS ON") || trimmedLine.contains("Scheme Name") {
                isInHoldingsSection = true
                continue
            }
            
            // Skip empty lines or header lines
            if trimmedLine.isEmpty || 
               trimmedLine.contains("Scheme Name") ||
               trimmedLine.contains("AMC") ||
               trimmedLine.contains("Category") {
                continue
            }
            
            // Try to parse holding data from line
            if isInHoldingsSection {
                if let holding = parseHoldingLine(trimmedLine) {
                    holdings.append(holding)
                }
            }
        }
        
        if holdings.isEmpty {
            throw ParsingError.dataExtractionError
        }
        
        return holdings
    }
    
    // Parse individual holding line from PDF text
    private func parseHoldingLine(_ line: String) -> HoldingData? {
        // The PDF format has columns separated by spaces
        // Pattern: SchemeName AMC Category SubCategory FolioNo Source Units InvestedValue CurrentValue Returns XIRR
        
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        // Need at least 11 components for a valid holding
        guard components.count >= 11 else { return nil }
        
        // Find the indices of numeric values (usually the last 5 values)
        var numericIndices: [Int] = []
        for (index, component) in components.enumerated().reversed() {
            if Double(component.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: ",", with: "")) != nil {
                numericIndices.insert(index, at: 0)
                if numericIndices.count == 5 { break } // We need 5 numeric values
            }
        }
        
        guard numericIndices.count == 5 else { return nil }
        
        // Extract numeric values
        let xirrStr = components[numericIndices[4]].replacingOccurrences(of: "%", with: "")
        let returnsStr = components[numericIndices[3]].replacingOccurrences(of: ",", with: "")
        let currentValueStr = components[numericIndices[2]].replacingOccurrences(of: ",", with: "")
        let investedValueStr = components[numericIndices[1]].replacingOccurrences(of: ",", with: "")
        let unitsStr = components[numericIndices[0]].replacingOccurrences(of: ",", with: "")
        
        guard let units = Double(unitsStr),
              let investedValue = Double(investedValueStr),
              let currentValue = Double(currentValueStr),
              let returns = Double(returnsStr),
              let xirr = Double(xirrStr) else {
            return nil
        }
        
        // Extract text values (everything before the numeric values)
        let textComponents = Array(components[0..<numericIndices[0]])
        guard textComponents.count >= 6 else { return nil }
        
        // Extract scheme name and AMC name
        var amcName = ""
        var category = ""
        var subCategory = ""
        var folioNumber = ""
        var source = ""
        
        // Work backwards to identify components
        if textComponents.count >= 6 {
            source = textComponents[textComponents.count - 1]
            folioNumber = textComponents[textComponents.count - 2]
            subCategory = textComponents[textComponents.count - 3]
            category = textComponents[textComponents.count - 4]
            
            // The remaining components contain Scheme Name + AMC Name
            let remainingComponents = Array(textComponents[0..<(textComponents.count - 4)])
            
            // Better parsing logic: Look for known AMC patterns that end with "Mutual Fund"
            var schemeComponents: [String] = []
            var amcComponents: [String] = []
            var foundAMC = false
            
            // Known AMC patterns that typically end with "Mutual Fund"
            let amcPatterns = [
                "SBI Mutual Fund",
                "Axis Mutual Fund", 
                "ICICI Prudential Mutual Fund",
                "HDFC Mutual Fund",
                "Kotak Mahindra Mutual Fund",
                "Aditya Birla Sun Life Mutual Fund",
                "Franklin Templeton Mutual Fund",
                "Mirae Asset Mutual Fund",
                "Nippon India Mutual Fund",
                "Tata Mutual Fund",
                "DSP Mutual Fund",
                "Motilal Oswal Mutual Fund",
                "PPFAS Mutual Fund",
                "Quant Mutual Fund",
                "Navi Mutual Fund",
                "Groww Mutual Fund",
                "Canara Robeco Mutual Fund",
                "360 ONE Mutual Fund",
                "Mahindra Mutual Fund",
                "Bandhan Mutual Fund"
            ]
            
            // Try to find AMC by matching known patterns
            let fullText = remainingComponents.joined(separator: " ")
            
            for pattern in amcPatterns {
                if let amcRange = fullText.range(of: pattern) {
                    let schemeText = String(fullText[..<amcRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let amcText = String(fullText[amcRange]).trimmingCharacters(in: .whitespaces)
                    
                    if !schemeText.isEmpty {
                        schemeComponents = schemeText.components(separatedBy: " ")
                        amcComponents = amcText.components(separatedBy: " ")
                        foundAMC = true
                        break
                    }
                }
            }
            
            // Fallback: If no known AMC pattern found, use heuristic
            if !foundAMC && remainingComponents.count > 0 {
                // Look for "Mutual Fund" as end of AMC name
                var foundMutualFund = false
                for i in stride(from: remainingComponents.count - 1, through: 1, by: -1) {
                    if i < remainingComponents.count - 1 && 
                       remainingComponents[i] == "Mutual" && 
                       remainingComponents[i + 1] == "Fund" {
                        schemeComponents = Array(remainingComponents[0..<i])
                        amcComponents = Array(remainingComponents[i...])
                        foundMutualFund = true
                        break
                    }
                }
                
                // Final fallback: Split roughly in middle, but preserve common scheme patterns
                if !foundMutualFund {
                    let totalComponents = remainingComponents.count
                    if totalComponents >= 4 {
                        // Assume last 2-3 components are AMC
                        let amcStartIndex = max(1, totalComponents - 3)
                        schemeComponents = Array(remainingComponents[0..<amcStartIndex])
                        amcComponents = Array(remainingComponents[amcStartIndex...])
                    } else {
                        // Very short, put most in scheme name
                        schemeComponents = Array(remainingComponents[0..<max(1, totalComponents - 1)])
                        amcComponents = Array(remainingComponents[max(1, totalComponents - 1)...])
                    }
                }
            }
            
            let schemeName = schemeComponents.joined(separator: " ")
            amcName = amcComponents.joined(separator: " ")
            
            if !schemeName.isEmpty && !amcName.isEmpty {
                return HoldingData(
                    schemeName: schemeName,
                    amcName: amcName,
                    category: category,
                    subCategory: subCategory,
                    folioNumber: folioNumber,
                    source: source,
                    units: units,
                    investedValue: investedValue,
                    currentValue: currentValue,
                    returns: returns,
                    xirr: xirr
                )
            }
        }
        
        return nil
    }
    
    // Parse CSV content
    private func parseCSVContent(_ content: String) throws -> [HoldingData] {
        let lines = content.components(separatedBy: .newlines)
        var holdings: [HoldingData] = []
        
        // Skip header line
        for line in lines.dropFirst() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            let columns = parseCSVLine(trimmedLine)
            if let holding = parseCSVColumns(columns) {
                holdings.append(holding)
            }
        }
        
        if holdings.isEmpty {
            throw ParsingError.dataExtractionError
        }
        
        return holdings
    }
    
    // Parse CSV line handling quoted values
    private func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        
        columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
        return columns
    }
    
    // Parse CSV columns to HoldingData
    private func parseCSVColumns(_ columns: [String]) -> HoldingData? {
        // Expected CSV format: SchemeName,AMC,Category,SubCategory,FolioNo,Source,Units,InvestedValue,CurrentValue,Returns,XIRR
        guard columns.count >= 11 else { return nil }
        
        let data: [String: String] = [
            "schemeName": columns[0],
            "amcName": columns[1],
            "category": columns[2],
            "subCategory": columns[3],
            "folioNumber": columns[4],
            "source": columns[5],
            "units": columns[6],
            "investedValue": columns[7],
            "currentValue": columns[8],
            "returns": columns[9],
            "xirr": columns[10]
        ]
        
        return HoldingData.from(parsedData: data)
    }
}