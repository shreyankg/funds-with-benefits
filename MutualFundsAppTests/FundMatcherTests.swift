import XCTest
@testable import MutualFundsApp

class FundMatcherTests: XCTestCase {
    var fundMatcher: FundMatcher!
    var mockFunds: [MutualFund]!
    
    override func setUp() {
        super.setUp()
        fundMatcher = FundMatcher.shared
        mockFunds = createMockFunds()
    }
    
    override func tearDown() {
        fundMatcher = nil
        mockFunds = nil
        super.tearDown()
    }
    
    // MARK: - Direct Growth Prioritization Tests
    
    func testDirectGrowthPrioritization() {
        // Test data from Holdings_Statement_2025-07-27.pdf
        let holding = HoldingData(
            schemeName: "SBI Conservative Hybrid Fund Direct Growth",
            amcName: "SBI Mutual Fund",
            category: "Hybrid",
            subCategory: "Conservative Hybrid",
            folioNumber: "22821659",
            source: "External",
            units: 610.664,
            investedValue: 32931.93,
            currentValue: 48581.37,
            returns: 15649.44,
            xirr: 10.19,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        // Should match the Direct Growth version over regular Growth
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "101001") // Direct Growth version
    }
    
    func testDirectGrowthPrioritizationWithMultipleOptions() {
        let holding = HoldingData(
            schemeName: "Axis Small Cap Fund Direct Growth",
            amcName: "Axis Mutual Fund",
            category: "Equity",
            subCategory: "Small Cap",
            folioNumber: "91093871226",
            source: "Groww",
            units: 709.806,
            investedValue: 54949.99,
            currentValue: 87852.69,
            returns: 32902.70,
            xirr: 21.62,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        // Should prioritize Direct Growth (102002) over regular Growth (102001) 
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "102002")
    }
    
    // MARK: - AMC Name Matching Tests
    
    func testICICIPrudentialAMCMatching() {
        let holding = HoldingData(
            schemeName: "ICICI Prudential Flexicap Fund Direct Growth",
            amcName: "ICICI Prudential Mutual Fund",
            category: "Equity",
            subCategory: "Flexi Cap",
            folioNumber: "18249066",
            source: "Groww",
            units: 2272.955,
            investedValue: 27998.58,
            currentValue: 44277.16,
            returns: 16278.58,
            xirr: 17.98,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "103001")
    }
    
    func testKotakMahindraAMCMatching() {
        let holding = HoldingData(
            schemeName: "Kotak Flexicap Fund Growth",
            amcName: "Kotak Mahindra Mutual Fund", 
            category: "Equity",
            subCategory: "Flexi Cap",
            folioNumber: "6400657",
            source: "External",
            units: 2424.099,
            investedValue: 76258.14,
            currentValue: 205808.43,
            returns: 129550.29,
            xirr: 19.75,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "104001")
    }
    
    func testMotilalOswalAMCMatching() {
        let holding = HoldingData(
            schemeName: "Motilal Oswal Midcap Fund Direct Growth",
            amcName: "Motilal Oswal Mutual Fund",
            category: "Equity", 
            subCategory: "Mid Cap",
            folioNumber: "91019516133",
            source: "Groww",
            units: 239.313,
            investedValue: 26998.72,
            currentValue: 27725.73,
            returns: 727.01,
            xirr: 13.54,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "105001")
    }
    
    func testParagParikhAMCMatching() {
        let holding = HoldingData(
            schemeName: "Parag Parikh Flexi Cap Fund Direct Growth",
            amcName: "PPFAS Mutual Fund",
            category: "Equity",
            subCategory: "Flexi Cap", 
            folioNumber: "10974497",
            source: "Groww",
            units: 800.425,
            investedValue: 40944.19,
            currentValue: 73683.84,
            returns: 32739.65,
            xirr: 20.36,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "106001")
    }
    
    func testNipponIndiaAMCMatching() {
        let holding = HoldingData(
            schemeName: "Nippon India Flexi Cap Fund Direct Growth",
            amcName: "Nippon India Mutual Fund",
            category: "Equity",
            subCategory: "Flexi Cap",
            folioNumber: "477233506686",
            source: "Groww",
            units: 1309.331,
            investedValue: 13517.68,
            currentValue: 22817.19,
            returns: 9299.51,
            xirr: 15.56,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "107001")
    }
    
    // MARK: - Edge Cases and Complex Matching
    
    func testFundWithSpecialCharacters() {
        let holding = HoldingData(
            schemeName: "360 ONE Focused Fund Direct Growth",
            amcName: "360 ONE Mutual Fund",
            category: "Equity",
            subCategory: "Flexi Cap",
            folioNumber: "235188",
            source: "Groww",
            units: 1346.564,
            investedValue: 53112.7,
            currentValue: 71990.27,
            returns: 18877.58,
            xirr: 16.44,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "108001")
    }
    
    func testFundOfFundsMatching() {
        let holding = HoldingData(
            schemeName: "Kotak Global Innovation FoF Direct Growth",
            amcName: "Kotak Mahindra Mutual Fund",
            category: "Equity",
            subCategory: "International",
            folioNumber: "8964150",
            source: "Groww",
            units: 8770.002,
            investedValue: 72196.56,
            currentValue: 103917.51,
            returns: 31720.95,
            xirr: 12.21,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "109001")
    }
    
    func testELSSFundMatching() {
        let holding = HoldingData(
            schemeName: "Axis ELSS Tax Saver Fund Growth",
            amcName: "Axis Mutual Fund",
            category: "Equity",
            subCategory: "ELSS",
            folioNumber: "91068138491",
            source: "External",
            units: 435.789,
            investedValue: 30059.72,
            currentValue: 41963.34,
            returns: 11903.63,
            xirr: 9.67,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        // Should match regular Growth version since no Direct version exists
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "110001")
    }
    
    func testCannotMatchLowScore() {
        let holding = HoldingData(
            schemeName: "Completely Different Fund Name",
            amcName: "Nonexistent AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "External",
            units: 100.0,
            investedValue: 1000.0,
            currentValue: 1100.0,
            returns: 100.0,
            xirr: 10.0,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        // Should not match due to low score (below 0.7 threshold)
        XCTAssertNil(matchedHoldings.first?.matchedSchemeCode)
    }
    
    func testMatchConfidenceLevels() {
        let holding = HoldingData(
            schemeName: "SBI Conservative Hybrid Fund Direct Growth",
            amcName: "SBI Mutual Fund",
            category: "Hybrid",
            subCategory: "Conservative Hybrid",
            folioNumber: "22821659",
            source: "External",
            units: 610.664,
            investedValue: 32931.93,
            currentValue: 48581.37,
            returns: 15649.44,
            xirr: 10.19,
            matchedSchemeCode: nil
        )
        
        let matchedFund = mockFunds.first { $0.schemeCode == "101001" }!
        let confidence = fundMatcher.getMatchConfidence(for: holding, fund: matchedFund)
        
        // Should have high confidence for exact match
        XCTAssertEqual(confidence, .high)
    }
    
    // MARK: - Enhanced Fund Name Matching Tests
    
    func testEnhancedFundNameSimilarity() {
        let holding = HoldingData(
            schemeName: "Mirae Asset Large & Midcap Fund Direct Growth",
            amcName: "Mirae Asset Mutual Fund",
            category: "Equity",
            subCategory: "Large & MidCap",
            folioNumber: "77740249741",
            source: "Groww",
            units: 657.514,
            investedValue: 83601.84,
            currentValue: 110548.49,
            returns: 26946.65,
            xirr: 16.32,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "111001")
    }
    
    func testFundNameVariationMatching() {
        // Test flexicap vs flexi cap variations
        let holding = HoldingData(
            schemeName: "ICICI Prudential Flexicap Fund Direct Growth",
            amcName: "ICICI Prudential Mutual Fund",
            category: "Equity",
            subCategory: "Flexi Cap",
            folioNumber: "18249066",
            source: "Groww",
            units: 2272.955,
            investedValue: 27998.58,
            currentValue: 44277.16,
            returns: 16278.58,
            xirr: 17.98,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        // Should match even with slight name variations
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "103001")
    }
    
    func testSimilarFundNamesDistinction() {
        // Test that similar but different funds are distinguished
        let holding1 = HoldingData(
            schemeName: "Axis Small Cap Fund Direct Growth",
            amcName: "Axis Mutual Fund",
            category: "Equity",
            subCategory: "Small Cap",
            folioNumber: "91093871226",
            source: "Groww",
            units: 709.806,
            investedValue: 54949.99,
            currentValue: 87852.69,
            returns: 32902.70,
            xirr: 21.62,
            matchedSchemeCode: nil
        )
        
        let holding2 = HoldingData(
            schemeName: "Axis Innovation Fund Direct Growth",
            amcName: "Axis Mutual Fund",
            category: "Equity",
            subCategory: "Thematic",
            folioNumber: "91093871226",
            source: "Groww",
            units: 3169.974,
            investedValue: 37682.03,
            currentValue: 62638.69,
            returns: 24956.65,
            xirr: 16.57,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding1, holding2], availableFunds: mockFunds)
        
        // Both should find matches but to different funds
        XCTAssertNotNil(matchedHoldings[0].matchedSchemeCode)
        XCTAssertNotNil(matchedHoldings[1].matchedSchemeCode)
        XCTAssertNotEqual(matchedHoldings[0].matchedSchemeCode, matchedHoldings[1].matchedSchemeCode)
        
        // Should match to their respective fund types
        XCTAssertEqual(matchedHoldings[0].matchedSchemeCode, "102002") // Small Cap
        XCTAssertEqual(matchedHoldings[1].matchedSchemeCode, "112001") // Innovation/Thematic
    }
    
    func testCategoryMatchingBonus() {
        let holding = HoldingData(
            schemeName: "Nippon India Short Duration Fund Direct Growth",
            amcName: "Nippon India Mutual Fund",
            category: "Debt",
            subCategory: "Short Duration",
            folioNumber: "477233506686",
            source: "Groww",
            units: 171.154,
            investedValue: 7721.13,
            currentValue: 9916.34,
            returns: 2195.20,
            xirr: 7.8,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "113001")
    }
    
    func testFOFFundMatching() {
        let holding = HoldingData(
            schemeName: "Motilal Oswal Nasdaq 100 FOF Direct Growth",
            amcName: "Motilal Oswal Mutual Fund",
            category: "Equity",
            subCategory: "International",
            folioNumber: "91019516133",
            source: "Groww",
            units: 509.447,
            investedValue: 10873.75,
            currentValue: 21682.52,
            returns: 10808.77,
            xirr: 17.9,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "114001")
    }
    
    func testThematicFundMatching() {
        let holding = HoldingData(
            schemeName: "DSP Natural Resources and New Energy Fund Direct Plan Growth",
            amcName: "DSP Mutual Fund",
            category: "Equity",
            subCategory: "Thematic",
            folioNumber: "6438363",
            source: "Groww",
            units: 775.596,
            investedValue: 54070.12,
            currentValue: 77475.06,
            returns: 23404.94,
            xirr: 16.7,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "115001")
    }
    
    // MARK: - Helper Methods
    
    private func createMockFunds() -> [MutualFund] {
        return [
            // SBI Funds - Direct Growth should be prioritized
            MutualFund(
                schemeCode: "101001", 
                schemeName: "SBI Conservative Hybrid Fund Direct Growth",
                isinGrowth: "INF200K01XX1"
            ),
            MutualFund(
                schemeCode: "101002",
                schemeName: "SBI Conservative Hybrid Fund Growth", 
                isinGrowth: "INF200K01XX2"
            ),
            
            // Axis Small Cap - Multiple options
            MutualFund(
                schemeCode: "102001",
                schemeName: "Axis Small Cap Fund Growth",
                isinGrowth: "INF846K01XX1"
            ),
            MutualFund(
                schemeCode: "102002", 
                schemeName: "Axis Small Cap Fund Direct Growth",
                isinGrowth: "INF846K01XX2"
            ),
            
            // ICICI Prudential 
            MutualFund(
                schemeCode: "103001",
                schemeName: "ICICI Prudential Flexicap Fund Direct Growth",
                isinGrowth: "INF109K01XX1"
            ),
            
            // Kotak Mahindra
            MutualFund(
                schemeCode: "104001",
                schemeName: "Kotak Flexicap Fund Growth", 
                isinGrowth: "INF174K01XX1"
            ),
            
            // Motilal Oswal
            MutualFund(
                schemeCode: "105001",
                schemeName: "Motilal Oswal Midcap Fund Direct Growth",
                isinGrowth: "INF360L01XX1"
            ),
            
            // Parag Parikh (PPFAS)
            MutualFund(
                schemeCode: "106001",
                schemeName: "Parag Parikh Flexi Cap Fund Direct Growth",
                isinGrowth: "INF016Q01XX1"
            ),
            
            // Nippon India
            MutualFund(
                schemeCode: "107001", 
                schemeName: "Nippon India Flexi Cap Fund Direct Growth",
                isinGrowth: "INF204K01XX1"
            ),
            
            // 360 ONE 
            MutualFund(
                schemeCode: "108001",
                schemeName: "360 ONE Focused Fund Direct Growth",
                isinGrowth: "INF111D01XX1"
            ),
            
            // Kotak FoF
            MutualFund(
                schemeCode: "109001",
                schemeName: "Kotak Global Innovation FoF Direct Growth", 
                isinGrowth: "INF174K01XX2"
            ),
            
            // Axis ELSS (only Growth version)
            MutualFund(
                schemeCode: "110001",
                schemeName: "Axis ELSS Tax Saver Fund Growth",
                isinGrowth: "INF846K01XX3"
            ),
            
            // Additional funds for enhanced name matching tests
            MutualFund(
                schemeCode: "111001",
                schemeName: "Mirae Asset Large & Mid Cap Fund Direct Growth",
                isinGrowth: "INF769K01XX1"
            ),
            
            MutualFund(
                schemeCode: "112001",
                schemeName: "Axis Innovation Fund Direct Growth",
                isinGrowth: "INF846K01XX4"
            ),
            
            MutualFund(
                schemeCode: "113001",
                schemeName: "Nippon India Short Duration Fund Direct Growth",
                isinGrowth: "INF204K01XX2"
            ),
            
            MutualFund(
                schemeCode: "114001",
                schemeName: "Motilal Oswal Nasdaq 100 FOF Direct Growth",
                isinGrowth: "INF360L01XX2"
            ),
            
            MutualFund(
                schemeCode: "115001",
                schemeName: "DSP Natural Resources and New Energy Fund Direct Growth",
                isinGrowth: "INF740K01XX1"
            )
        ]
    }
}