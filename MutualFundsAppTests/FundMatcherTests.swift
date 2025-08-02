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
    
    func testParagParikhConservativeHybridMatching() {
        let holding = HoldingData(
            schemeName: "Parag Parikh Conservative Hybrid Fund - Direct Plan - Growth",
            amcName: "PPFAS Mutual Fund",
            category: "Hybrid",
            subCategory: "Conservative Hybrid",
            folioNumber: "12345678",
            source: "Direct",
            units: 100.0,
            investedValue: 1000.0,
            currentValue: 1200.0,
            returns: 200.0,
            xirr: 15.0,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode, "Parag Parikh Conservative Hybrid Fund should find a match")
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "148958", "Should match to the correct scheme code")
    }
    
    func testParagParikhConservativeHybridMatchingDebug() {
        // Test the exact matching with debugging to understand why it might fail
        let holding = HoldingData(
            schemeName: "Parag Parikh Conservative Hybrid Fund - Direct Plan - Growth",
            amcName: "PPFAS Mutual Fund",
            category: "Hybrid",
            subCategory: "Conservative Hybrid",
            folioNumber: "12345678",
            source: "Direct",
            units: 100.0,
            investedValue: 1000.0,
            currentValue: 1200.0,
            returns: 200.0,
            xirr: 15.0,
            matchedSchemeCode: nil
        )
        
        let targetFund = mockFunds.first { $0.schemeCode == "148958" }!
        
        // Test individual scoring components
        let holdingName = holding.schemeName.lowercased()
        let fundName = targetFund.schemeName.lowercased()
        
        print("=== DEBUGGING FUND MATCHING ===")
        print("Holding: '\(holding.schemeName)'")
        print("Fund: '\(targetFund.schemeName)'")
        print("Holding AMC: '\(holding.amcName)'")
        print("Fund House: '\(targetFund.fundHouse)'")
        
        // Test AMC matching
        let holdingAMC = holding.amcName.lowercased()
        let fundHouse = targetFund.fundHouse.lowercased()
        
        print("AMC Match Test:")
        print("  Holding AMC: '\(holdingAMC)'")
        print("  Fund House: '\(fundHouse)'")
        print("  Contains match: \(holdingAMC.contains(fundHouse) || fundHouse.contains(holdingAMC))")
        
        // Test plan type matching
        let holdingLower = holdingName
        let fundLower = fundName
        
        print("Plan Type Tests:")
        print("  Holding contains 'direct': \(holdingLower.contains("direct"))")
        print("  Fund contains 'direct': \(fundLower.contains("direct"))")
        print("  Holding contains 'growth': \(holdingLower.contains("growth"))")
        print("  Fund contains 'growth': \(fundLower.contains("growth"))")
        
        // Test the actual matching score
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        print("Match result: \(matchedHoldings.first?.matchedSchemeCode ?? "nil")")
        print("================================")
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode, "Should find a match with debugging info above")
    }
    
    func testParagParikhConservativeHybridRegularPlanMatching() {
        // Test the actual holding from the PDF: "Parag Parikh Conservative Hybrid Fund Growth" 
        // when all 4 variants are available: Direct Growth, Regular Growth, Direct IDCW, Regular IDCW
        let holding = HoldingData(
            schemeName: "Parag Parikh Conservative Hybrid Fund Growth",
            amcName: "PPFAS Mutual Fund",
            category: "Hybrid",
            subCategory: "Conservative Hybrid",
            folioNumber: "11059487",
            source: "External",
            units: 31294.977,
            investedValue: 312949.77,
            currentValue: 474003.11,
            returns: 161053.3401,
            xirr: 10.73,
            matchedSchemeCode: nil
        )
        
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds([holding], availableFunds: mockFunds)
        
        print("=== ALL 4 VARIANTS MATCHING TEST ===")
        print("Available funds:")
        print("- 148958: Direct Plan Growth (+10% bonus)")
        print("- 148959: Regular Plan Growth (+5% bonus)")  
        print("- 148960: Direct Plan IDCW (+5% bonus)")
        print("- 148961: Regular Plan IDCW (no bonus)")
        print("Holding: '\(holding.schemeName)' (no 'Direct' specified)")
        print("Expected match: Regular Plan Growth (148959)")
        print("Actual match: \(matchedHoldings.first?.matchedSchemeCode ?? "nil")")
        
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode, "Should find a match among the 4 variants")
        
        // Should match Regular Growth (148959) because:
        // 1. Exact plan type match (Growth vs Growth)
        // 2. Should not prioritize Direct since holding doesn't specify "Direct"
        // 3. Should prefer Growth over IDCW
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "148959", 
                     "Should match Regular Plan Growth (148959) when holding is 'Parag Parikh Conservative Hybrid Fund Growth' without 'Direct'")
    }
    
    // MARK: - Basic Matching Tests
    
    func testFundMatcherExactMatch() throws {
        let holding = HoldingData(
            schemeName: "SBI Large Cap Fund Direct Growth",
            amcName: "SBI Mutual Fund",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "External",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 12000.0,
            returns: 2000.0,
            xirr: 15.0
        )
        
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "SBI Large Cap Fund Direct Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let matcher = FundMatcher.shared
        let matchedHoldings = matcher.matchHoldingsWithFunds([holding], availableFunds: [fund])
        
        let holdingsCount = matchedHoldings.count
        XCTAssertEqual(holdingsCount, 1)
        let matchedSchemeCode = matchedHoldings.first?.matchedSchemeCode
        XCTAssertNotNil(matchedSchemeCode)
        XCTAssertEqual(matchedSchemeCode, "123456")
    }
    
    func testFundMatcherAMCVariations() throws {
        let holding = HoldingData(
            schemeName: "ICICI Prudential Large Cap Fund Direct Growth",
            amcName: "ICICI Prudential Mutual Fund",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "External",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 12000.0,
            returns: 2000.0,
            xirr: 15.0
        )
        
        let fund = MutualFund(
            schemeCode: "789012",
            schemeName: "ICICI Prudential Large Cap Fund Direct Growth",
            isinGrowth: "INF789012345",
            isinDivReinvestment: nil
        )
        
        let matcher = FundMatcher.shared
        let matchedHoldings = matcher.matchHoldingsWithFunds([holding], availableFunds: [fund])
        
        let holdingsCount = matchedHoldings.count
        XCTAssertEqual(holdingsCount, 1)
        let matchedSchemeCode = matchedHoldings.first?.matchedSchemeCode
        XCTAssertNotNil(matchedSchemeCode)
    }
    
    // MARK: - Plan Type Inference Tests
    
    func testFundMatcherPlanTypeInferenceLogic() throws {
        // Test the plan type inference logic with various scenarios
        let testCases = [
            // Test case 1: External fund with "Growth" should infer Regular Growth
            (
                holding: HoldingData(
                    schemeName: "Test Fund Growth",
                    amcName: "Test AMC",
                    category: "Equity",
                    subCategory: "Large Cap",
                    folioNumber: "12345",
                    source: "External",
                    units: 100.0,
                    investedValue: 1000.0,
                    currentValue: 1100.0,
                    returns: 100.0,
                    xirr: 10.0
                ),
                funds: [
                    MutualFund(schemeCode: "TEST001", schemeName: "Test Fund - Regular Plan - Growth"),
                    MutualFund(schemeCode: "TEST002", schemeName: "Test Fund - Direct Plan - Growth")
                ],
                expectedMatch: "TEST001"
            ),
            // Test case 2: External fund with "Direct Growth" should match Direct Growth
            (
                holding: HoldingData(
                    schemeName: "Test Fund Direct Growth",
                    amcName: "Test AMC",
                    category: "Equity",
                    subCategory: "Large Cap",
                    folioNumber: "12346",
                    source: "External",
                    units: 100.0,
                    investedValue: 1000.0,
                    currentValue: 1100.0,
                    returns: 100.0,
                    xirr: 10.0
                ),
                funds: [
                    MutualFund(schemeCode: "TEST001", schemeName: "Test Fund - Regular Plan - Growth"),
                    MutualFund(schemeCode: "TEST002", schemeName: "Test Fund - Direct Plan - Growth")
                ],
                expectedMatch: "TEST002"
            )
        ]
        
        let matcher = FundMatcher.shared
        
        for (index, testCase) in testCases.enumerated() {
            let matchedHoldings = matcher.matchHoldingsWithFunds([testCase.holding], availableFunds: testCase.funds)
            
            let holdingsCount = matchedHoldings.count
            XCTAssertEqual(holdingsCount, 1, "Test case \(index + 1): Should have one matched holding")
            let matchedSchemeCode = matchedHoldings.first?.matchedSchemeCode
            XCTAssertNotNil(matchedSchemeCode, "Test case \(index + 1): Should find a match")
            XCTAssertEqual(matchedSchemeCode, testCase.expectedMatch, 
                         "Test case \(index + 1): Should match expected scheme code")
        }
    }
    
    func testFundMatcherPreviouslyUnmatchedExternalFunds() throws {
        // Test all 5 previously unmatched external funds with plan type inference fix
        let testCases = [
            // Test case 1: Parag Parikh Conservative Hybrid Fund Growth
            (
                holding: HoldingData(
                    schemeName: "Parag Parikh Conservative Hybrid Fund Growth",
                    amcName: "PPFAS Mutual Fund",
                    category: "Hybrid",
                    subCategory: "Conservative Hybrid",
                    folioNumber: "11059487",
                    source: "External",
                    units: 31294.977,
                    investedValue: 312949.77,
                    currentValue: 474003.11,
                    returns: 161053.34,
                    xirr: 10.73
                ),
                funds: [
                    MutualFund(schemeCode: "148958", schemeName: "Parag Parikh Conservative Hybrid Fund - Direct Plan - Growth"),
                    MutualFund(schemeCode: "148959", schemeName: "Parag Parikh Conservative Hybrid Fund - Regular Plan - Growth")
                ],
                expectedMatch: "148959",
                description: "Parag Parikh Conservative Hybrid"
            ),
            
            // Test case 2: Kotak Balanced Advantage Fund Growth
            (
                holding: HoldingData(
                    schemeName: "Kotak Balanced Advantage Fund Growth",
                    amcName: "Kotak Mahindra Mutual Fund",
                    category: "Hybrid",
                    subCategory: "Dynamic Asset Allocation",
                    folioNumber: "6400657",
                    source: "External",
                    units: 10357.968,
                    investedValue: 147216.97,
                    currentValue: 212483.36,
                    returns: 65266.39,
                    xirr: 10.41
                ),
                funds: [
                    MutualFund(schemeCode: "119551", schemeName: "Kotak Balanced Advantage Fund - Direct Plan - Growth"),
                    MutualFund(schemeCode: "119552", schemeName: "Kotak Balanced Advantage Fund - Regular Plan - Growth")
                ],
                expectedMatch: "119552",
                description: "Kotak Balanced Advantage"
            ),
            
            // Test case 3: SBI Focused Fund Growth
            (
                holding: HoldingData(
                    schemeName: "SBI Focused Fund Growth",
                    amcName: "SBI Mutual Fund",
                    category: "Equity",
                    subCategory: "Focused",
                    folioNumber: "22186788",
                    source: "External",
                    units: 528.530,
                    investedValue: 74226.49,
                    currentValue: 185502.51,
                    returns: 111276.02,
                    xirr: 15.8
                ),
                funds: [
                    MutualFund(schemeCode: "119573", schemeName: "SBI FOCUSED FUND - DIRECT PLAN - GROWTH"),
                    MutualFund(schemeCode: "119574", schemeName: "SBI FOCUSED FUND - REGULAR PLAN - GROWTH")
                ],
                expectedMatch: "119574",
                description: "SBI Focused Fund"
            ),
            
            // Test case 4: SBI Conservative Hybrid Fund Growth
            (
                holding: HoldingData(
                    schemeName: "SBI Conservative Hybrid Fund Growth",
                    amcName: "SBI Mutual Fund",
                    category: "Hybrid",
                    subCategory: "Conservative Hybrid",
                    folioNumber: "22821659",
                    source: "External",
                    units: 2048.122,
                    investedValue: 106252.03,
                    currentValue: 149127.65,
                    returns: 42875.62,
                    xirr: 10.27
                ),
                funds: [
                    MutualFund(schemeCode: "101001", schemeName: "SBI Conservative Hybrid Fund Direct Growth"),
                    MutualFund(schemeCode: "101002", schemeName: "SBI Conservative Hybrid Fund Growth")
                ],
                expectedMatch: "101002",
                description: "SBI Conservative Hybrid Fund"
            ),
            
            // Test case 5: Axis ELSS Tax Saver Fund Growth
            (
                holding: HoldingData(
                    schemeName: "Axis ELSS Tax Saver Fund Growth",
                    amcName: "Axis Mutual Fund",
                    category: "Equity",
                    subCategory: "ELSS",
                    folioNumber: "91068138491",
                    source: "External",
                    units: 435.789,
                    investedValue: 30059.72,
                    currentValue: 41963.34,
                    returns: 11903.62,
                    xirr: 9.67
                ),
                funds: [
                    MutualFund(schemeCode: "120503", schemeName: "Axis ELSS Tax Saver Fund - Regular Plan - Growth"),
                    MutualFund(schemeCode: "120504", schemeName: "Axis ELSS Tax Saver Fund - Direct Plan - Growth")
                ],
                expectedMatch: "120503",
                description: "Axis ELSS Tax Saver Fund"
            )
        ]
        
        let matcher = FundMatcher.shared
        
        for testCase in testCases {
            let matchedHoldings = matcher.matchHoldingsWithFunds([testCase.holding], availableFunds: testCase.funds)
            
            let holdingsCount = matchedHoldings.count
            XCTAssertEqual(holdingsCount, 1, "\(testCase.description): Should have one matched holding")
            let matchedSchemeCode = matchedHoldings.first?.matchedSchemeCode
            XCTAssertNotNil(matchedSchemeCode, 
                          "\(testCase.description): Should find a match with plan type inference")
            XCTAssertEqual(matchedSchemeCode, testCase.expectedMatch, 
                         "\(testCase.description): Should match Regular Plan Growth for external fund without 'Direct'")
        }
    }
    
    // MARK: - Dividend Filtering Integration Tests
    
    func testFundMatcherWithDividendFiltering() throws {
        let fundMatcher = FundMatcher.shared
        let settings = AppSettings.shared
        
        // Create a test holding that might match both growth and dividend funds
        let testHolding = HoldingData(
            schemeName: "SBI Large Cap Fund Direct Growth",
            amcName: "SBI",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "12345",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 10.5,
            matchedSchemeCode: nil
        )
        
        let mockFunds = [
            MutualFund(schemeCode: "001", schemeName: "SBI Large Cap Fund Direct Growth"),
            MutualFund(schemeCode: "002", schemeName: "SBI Large Cap Fund Direct Dividend"),
            MutualFund(schemeCode: "003", schemeName: "HDFC Large Cap Fund Growth")
        ]
        
        // Test with dividend funds hidden
        settings.showDividendFunds = false
        let matchedHoldings1 = fundMatcher.matchHoldingsWithFunds([testHolding], availableFunds: mockFunds)
        
        // Should match the growth fund, not the dividend fund
        let holdings1Count = matchedHoldings1.count
        XCTAssertEqual(holdings1Count, 1)
        let matchedSchemeCode1 = matchedHoldings1.first?.matchedSchemeCode
        if let schemeCode = matchedSchemeCode1 {
            XCTAssertEqual(schemeCode, "001", "Should match growth fund when dividend funds are hidden")
        }
        
        // Test with dividend funds shown
        settings.showDividendFunds = true
        let matchedHoldings2 = fundMatcher.matchHoldingsWithFunds([testHolding], availableFunds: mockFunds)
        
        // Should still prefer the exact growth match
        let holdings2Count = matchedHoldings2.count
        XCTAssertEqual(holdings2Count, 1)
        let matchedSchemeCode2 = matchedHoldings2.first?.matchedSchemeCode
        if let schemeCode = matchedSchemeCode2 {
            XCTAssertEqual(schemeCode, "001", "Should still match growth fund even when dividend funds are shown")
        }
        
        // Reset to default
        settings.showDividendFunds = false
    }
    
    // MARK: - Performance Tests
    
    func testFundMatchingPerformanceOptimized() throws {
        let fundMatcher = FundMatcher.shared
        
        // Create test data similar to real-world scale
        let mockHoldings = createMockHoldingsForPerformance(count: 20) // Typical portfolio size
        let mockFunds = createMockFundsForPerformance(count: 5000) // Real API returns ~5000 funds
        
        // Measure performance of optimized version
        let startTime = Date()
        let matchedHoldings = fundMatcher.matchHoldingsWithFunds(mockHoldings, availableFunds: mockFunds)
        let endTime = Date()
        
        let timeElapsed = endTime.timeIntervalSince(startTime)
        NSLog("✅ Phase 1 Optimized matching completed in: \(String(format: "%.3f", timeElapsed))s")
        NSLog("📊 Processed \(mockHoldings.count) holdings against \(mockFunds.count) funds")
        NSLog("🎯 Average time per holding: \(String(format: "%.3f", timeElapsed / Double(mockHoldings.count)))s")
        
        // Verify results are valid
        let holdingsCount = matchedHoldings.count
        XCTAssertEqual(holdingsCount, mockHoldings.count, "All holdings should be processed")
        
        // Performance assertion: should complete under 2 seconds for 20 holdings x 5000 funds
        XCTAssertLessThan(timeElapsed, 2.0, "Optimized matching should complete within 2 seconds")
    }
    
    // MARK: - Helper Methods
    
    private func createMockHoldingsForPerformance(count: Int) -> [HoldingData] {
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
    
    private func createMockFundsForPerformance(count: Int) -> [MutualFund] {
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
            ),
            
            // Parag Parikh Conservative Hybrid Fund (All 4 variants for comprehensive testing)
            MutualFund(
                schemeCode: "148958",
                schemeName: "Parag Parikh Conservative Hybrid Fund - Direct Plan - Growth",
                isinGrowth: "INF016Q01XX2"
            ),
            MutualFund(
                schemeCode: "148959",
                schemeName: "Parag Parikh Conservative Hybrid Fund - Regular Plan - Growth",
                isinGrowth: "INF016Q01XX3"
            ),
            MutualFund(
                schemeCode: "148960",
                schemeName: "Parag Parikh Conservative Hybrid Fund - Direct Plan - IDCW",
                isinGrowth: "INF016Q01XX4"
            ),
            MutualFund(
                schemeCode: "148961",
                schemeName: "Parag Parikh Conservative Hybrid Fund - Regular Plan - IDCW",
                isinGrowth: "INF016Q01XX5"
            )
        ]
    }
}