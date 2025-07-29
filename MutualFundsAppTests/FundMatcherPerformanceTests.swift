//
//  FundMatcherPerformanceTests.swift
//  MutualFundsAppTests
//
//  Created for performance testing FundMatcher optimizations
//

import XCTest
@testable import FWB

class FundMatcherPerformanceTests: XCTestCase {
    
    func testFundMatchingPerformanceOptimized() throws {
        let fundMatcher = FundMatcher.shared
        
        // Create test data similar to real-world scale
        let mockHoldings = createMockHoldings(count: 20) // Typical portfolio size
        let mockFunds = createMockFunds(count: 5000) // Real API returns ~5000 funds
        
        // Measure performance of optimized version
        let startTime = Date()
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds(mockHoldings, availableFunds: mockFunds)
        let endTime = Date()
        
        let timeElapsed = endTime.timeIntervalSince(startTime)
        NSLog("✅ Phase 1 Optimized matching completed in: \(String(format: "%.3f", timeElapsed))s")
        NSLog("📊 Processed \(mockHoldings.count) holdings against \(mockFunds.count) funds")
        NSLog("🎯 Average time per holding: \(String(format: "%.3f", timeElapsed / Double(mockHoldings.count)))s")
        
        // Verify results are valid
        XCTAssertEqual(matchedHoldings.count, mockHoldings.count, "All holdings should be processed")
        
        // Performance assertion: should complete under 2 seconds for 20 holdings x 5000 funds
        XCTAssertLessThan(timeElapsed, 2.0, "Optimized matching should complete within 2 seconds")
    }
    
    private func createMockHoldings(count: Int) -> [HoldingData] {
        let amcNames = ["ICICI Prudential", "HDFC", "SBI", "Axis", "Kotak Mahindra", "Aditya Birla", "Franklin Templeton", "Mirae Asset"]
        let categories = ["Equity", "Debt", "Hybrid"]
        let schemes = ["Flexicap Fund", "Large Cap Fund", "Mid Cap Fund", "Liquid Fund", "Balanced Fund"]
        
        return (0..<count).map { i in
            let amcName = amcNames[i % amcNames.count]
            let category = categories[i % categories.count]
            let scheme = schemes[i % schemes.count]
            
            return HoldingData(
                schemeName: "\(amcName) \(scheme) Direct Growth",
                amcName: amcName,
                category: category,
                subCategory: "\(category) Subcategory",
                folioNumber: "FOL\(String(format: "%06d", i))",
                source: "Test Data",
                units: Double.random(in: 100...10000),
                investedValue: Double.random(in: 10000...500000),
                currentValue: Double.random(in: 9000...600000),
                returns: Double.random(in: -10000...100000),
                xirr: Double.random(in: -20...30),
                matchedSchemeCode: nil
            )
        }
    }
    
    private func createMockFunds(count: Int) -> [MutualFund] {
        let amcNames = ["ICICI Prudential", "HDFC", "SBI", "Axis", "Kotak Mahindra", "Aditya Birla Sun Life", "Franklin Templeton", "Mirae Asset"]
        let categories = ["Equity", "Debt", "Hybrid"]
        let schemes = ["Flexicap Fund", "Large Cap Fund", "Mid Cap Fund", "Small Cap Fund", "Liquid Fund", "Balanced Fund", "Value Fund", "Growth Fund"]
        let planTypes = ["Direct", "Regular"]
        let optionTypes = ["Growth", "Dividend"]
        
        return (0..<count).map { i in
            let amcName = amcNames[i % amcNames.count]
            let category = categories[i % categories.count]
            let scheme = schemes[i % schemes.count]
            let planType = planTypes[i % planTypes.count]
            let optionType = optionTypes[i % optionTypes.count]
            
            return MutualFund(
                schemeCode: String(format: "%06d", i),
                schemeName: "\(amcName) \(scheme) \(planType) Plan \(optionType)",
                isinGrowth: "INF\(String(format: "%09d", i))91",
                isinDivReinvestment: nil
            )
        }
    }
}