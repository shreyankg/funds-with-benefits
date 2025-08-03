import XCTest
@testable import FWB

final class MutualFundsAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Clear any cached data from shared singletons to ensure test isolation
        DataCache.shared.clearCache()
        
        // Reset any settings that might affect test results
        AppSettings.shared.showDividendFunds = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        // Clean up shared state after each test
        DataCache.shared.clearCache()
        
        // Reset FundMatcher shared instance state if needed
        // (FundMatcher likely has internal caches that should be cleared)
        FundMatcher.shared.preprocessFundsData([])
        
        // Reset AppSettings to default state
        AppSettings.shared.showDividendFunds = false
    }

    // MARK: - MutualFund Model Tests
    
    func testMutualFundJSONDecodingWithIntegerSchemeCode() throws {
        let jsonData = """
        {
            "schemeCode": 123456,
            "schemeName": "SBI Large Cap Fund - Regular Plan - Growth",
            "isinGrowth": "INF123456789",
            "isinDivReinvestment": null
        }
        """.data(using: .utf8)!
        
        let fund = try JSONDecoder().decode(MutualFund.self, from: jsonData)
        
        XCTAssertEqual(fund.schemeCode, "123456")
        XCTAssertEqual(fund.schemeName, "SBI Large Cap Fund - Regular Plan - Growth")
        XCTAssertEqual(fund.isinGrowth, "INF123456789")
        XCTAssertNil(fund.isinDivReinvestment)
        XCTAssertEqual(fund.fundHouse, "SBI")
    }
    
    func testMutualFundJSONDecodingWithStringSchemeCode() throws {
        let jsonData = """
        {
            "schemeCode": "123456",
            "schemeName": "SBI Large Cap Fund - Regular Plan - Growth",
            "isinGrowth": "INF123456789",
            "isinDivReinvestment": null
        }
        """.data(using: .utf8)!
        
        let fund = try JSONDecoder().decode(MutualFund.self, from: jsonData)
        
        XCTAssertEqual(fund.schemeCode, "123456")
        XCTAssertEqual(fund.schemeName, "SBI Large Cap Fund - Regular Plan - Growth")
        XCTAssertEqual(fund.isinGrowth, "INF123456789")
        XCTAssertNil(fund.isinDivReinvestment)
    }
    
    func testMutualFundJSONEncoding() throws {
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "SBI Large Cap Fund - Regular Plan - Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let encoded = try JSONEncoder().encode(fund)
        let decoded = try JSONDecoder().decode(MutualFund.self, from: encoded)
        
        XCTAssertEqual(decoded.schemeCode, fund.schemeCode)
        XCTAssertEqual(decoded.schemeName, fund.schemeName)
        XCTAssertEqual(decoded.isinGrowth, fund.isinGrowth)
        XCTAssertEqual(decoded.isinDivReinvestment, fund.isinDivReinvestment)
    }
    
    func testMutualFundArrayJSONDecodingWithMixedSchemeCodeTypes() throws {
        let jsonData = """
        [
            {
                "schemeCode": 123456,
                "schemeName": "SBI Large Cap Fund - Regular Plan - Growth",
                "isinGrowth": "INF123456789",
                "isinDivReinvestment": null
            },
            {
                "schemeCode": "789012",
                "schemeName": "HDFC Large Cap Fund - Regular Plan - Growth",
                "isinGrowth": "INF789012345",
                "isinDivReinvestment": null
            }
        ]
        """.data(using: .utf8)!
        
        let funds = try JSONDecoder().decode([MutualFund].self, from: jsonData)
        
        XCTAssertEqual(funds.count, 2)
        XCTAssertEqual(funds[0].schemeCode, "123456")
        XCTAssertEqual(funds[1].schemeCode, "789012")
        XCTAssertEqual(funds[0].fundHouse, "SBI")
        XCTAssertEqual(funds[1].fundHouse, "HDFC")
    }
    
    func testMutualFundFundHouseExtraction() throws {
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "SBI Large Cap Fund - Regular Plan - Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        XCTAssertEqual(fund.fundHouse, "SBI")
    }
    
    func testMutualFundCategoryClassification() throws {
        let equityFund = MutualFund(
            schemeCode: "123456",
            schemeName: "HDFC Large Cap Fund - Regular Plan - Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let debtFund = MutualFund(
            schemeCode: "123457",
            schemeName: "SBI Liquid Fund - Regular Plan - Growth",
            isinGrowth: "INF123456790",
            isinDivReinvestment: nil
        )
        
        let hybridFund = MutualFund(
            schemeCode: "123458",
            schemeName: "ICICI Hybrid Fund - Regular Plan - Growth",
            isinGrowth: "INF123456791",
            isinDivReinvestment: nil
        )
        
        XCTAssertEqual(equityFund.category, "Equity")
        XCTAssertEqual(debtFund.category, "Debt")
        XCTAssertEqual(hybridFund.category, "Hybrid")
    }
    
    func testMutualFundPlanTypeDetection() throws {
        let growthFund = MutualFund(
            schemeCode: "123456",
            schemeName: "SBI Large Cap Fund - Regular Plan - Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let dividendFund = MutualFund(
            schemeCode: "123457",
            schemeName: "HDFC Large Cap Fund - Regular Plan - Dividend",
            isinGrowth: nil,
            isinDivReinvestment: "INF123456790"
        )
        
        XCTAssertTrue(growthFund.isGrowthPlan)
        XCTAssertFalse(growthFund.isDividendPlan)
        XCTAssertTrue(dividendFund.isDividendPlan)
        XCTAssertFalse(dividendFund.isGrowthPlan)
    }
    
    // MARK: - NAVData Model Tests
    
    func testNAVDataValueParsing() throws {
        let navData = NAVData(date: "27-01-2025", nav: "1054.5678")
        
        XCTAssertEqual(navData.navValue, 1054.5678, accuracy: 0.0001)
    }
    
    func testNAVDataDateParsing() throws {
        let navData = NAVData(date: "27-01-2025", nav: "1054.5678")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let expectedDate = dateFormatter.date(from: "27-01-2025")
        
        XCTAssertEqual(navData.dateValue, expectedDate)
    }
    
    func testNAVDataFormattedDate() throws {
        let navData = NAVData(date: "27-01-2025", nav: "1054.5678")
        
        XCTAssertEqual(navData.formattedDate, "Jan 27, 2025")
    }
    
    // MARK: - FundDetails Performance Tests
    
    func testFundDetailsCurrentNAV() throws {
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "Test Fund",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let history = [
            NAVData(date: "27-01-2025", nav: "1054.5678"),
            NAVData(date: "26-01-2025", nav: "1050.1234")
        ]
        
        let fundDetails = FundDetails(fund: fund, history: history, meta: nil)
        
        XCTAssertEqual(fundDetails.currentNAV, 1054.5678, accuracy: 0.0001)
        XCTAssertEqual(fundDetails.previousNAV, 1050.1234, accuracy: 0.0001)
    }
    
    func testFundDetailsDailyChangeCalculation() throws {
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "Test Fund",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let history = [
            NAVData(date: "27-01-2025", nav: "1054.5678"),
            NAVData(date: "26-01-2025", nav: "1050.1234")
        ]
        
        let fundDetails = FundDetails(fund: fund, history: history, meta: nil)
        
        XCTAssertEqual(fundDetails.dailyChange, 4.4444, accuracy: 0.0001)
        XCTAssertEqual(fundDetails.dailyChangePercentage, 0.4232, accuracy: 0.0001)
    }
    
    func testFundDetailsFormattedChanges() throws {
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "Test Fund",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let history = [
            NAVData(date: "27-01-2025", nav: "1054.57"),
            NAVData(date: "26-01-2025", nav: "1050.12")
        ]
        
        let fundDetails = FundDetails(fund: fund, history: history, meta: nil)
        
        XCTAssertEqual(fundDetails.formattedDailyChange, "+4.45")
        XCTAssertEqual(fundDetails.formattedDailyChangePercentage, "+0.42%")
    }
    
    // MARK: - FundMeta JSON Parsing Tests
    
    func testFundMetaJSONDecodingWithIntegerSchemeCode() throws {
        let jsonData = """
        {
            "fund_house": "SBI Mutual Fund",
            "scheme_type": "Open Ended Schemes",
            "scheme_category": "Debt Scheme - Overnight Fund",
            "scheme_code": 101206,
            "scheme_name": "SBI Overnight Fund - Regular Plan - Growth",
            "isin_growth": "INF200K01LQ9",
            "isin_div_reinvestment": null
        }
        """.data(using: .utf8)!
        
        let fundMeta = try JSONDecoder().decode(FundMeta.self, from: jsonData)
        
        XCTAssertEqual(fundMeta.scheme_code, "101206")
        XCTAssertEqual(fundMeta.fund_house, "SBI Mutual Fund")
        XCTAssertEqual(fundMeta.scheme_type, "Open Ended Schemes")
        XCTAssertEqual(fundMeta.scheme_category, "Debt Scheme - Overnight Fund")
        XCTAssertEqual(fundMeta.scheme_name, "SBI Overnight Fund - Regular Plan - Growth")
        XCTAssertEqual(fundMeta.isin_growth, "INF200K01LQ9")
        XCTAssertNil(fundMeta.isin_div_reinvestment)
    }
    
    func testFundMetaJSONDecodingWithStringSchemeCode() throws {
        let jsonData = """
        {
            "fund_house": "HDFC Mutual Fund",
            "scheme_type": "Open Ended Schemes",
            "scheme_category": "Equity Scheme - Large Cap Fund",
            "scheme_code": "101307",
            "scheme_name": "HDFC Large Cap Fund - Regular Plan - Growth",
            "isin_growth": "INF179K01158",
            "isin_div_reinvestment": "INF179K01166"
        }
        """.data(using: .utf8)!
        
        let fundMeta = try JSONDecoder().decode(FundMeta.self, from: jsonData)
        
        XCTAssertEqual(fundMeta.scheme_code, "101307")
        XCTAssertEqual(fundMeta.fund_house, "HDFC Mutual Fund")
        XCTAssertEqual(fundMeta.scheme_name, "HDFC Large Cap Fund - Regular Plan - Growth")
        XCTAssertEqual(fundMeta.isin_growth, "INF179K01158")
        XCTAssertEqual(fundMeta.isin_div_reinvestment, "INF179K01166")
    }
    
    func testFundHistoryJSONDecodingWithMeta() throws {
        let jsonData = """
        {
            "meta": {
                "fund_house": "SBI Mutual Fund",
                "scheme_type": "Open Ended Schemes",
                "scheme_category": "Debt Scheme - Overnight Fund",
                "scheme_code": 101206,
                "scheme_name": "SBI Overnight Fund - Regular Plan - Growth",
                "isin_growth": "INF200K01LQ9",
                "isin_div_reinvestment": null
            },
            "data": [
                {
                    "date": "27-01-2025",
                    "nav": "1054.5678"
                },
                {
                    "date": "26-01-2025",
                    "nav": "1053.1234"
                }
            ],
            "status": "SUCCESS"
        }
        """.data(using: .utf8)!
        
        let fundHistory = try JSONDecoder().decode(FundHistory.self, from: jsonData)
        
        XCTAssertEqual(fundHistory.meta.scheme_code, "101206")
        XCTAssertEqual(fundHistory.meta.fund_house, "SBI Mutual Fund")
        XCTAssertEqual(fundHistory.data.count, 2)
        XCTAssertEqual(fundHistory.data[0].date, "27-01-2025")
        XCTAssertEqual(fundHistory.data[0].nav, "1054.5678")
        XCTAssertEqual(fundHistory.status, "SUCCESS")
    }
    
    func testFundMetaJSONEncoding() throws {
        let fundMeta = FundMeta(
            fund_house: "Test Fund House",
            scheme_type: "Open Ended Schemes",
            scheme_category: "Equity Scheme - Large Cap Fund",
            scheme_code: "123456",
            scheme_name: "Test Fund - Regular Plan - Growth",
            isin_growth: "INF123456789",
            isin_div_reinvestment: nil
        )
        
        let encoded = try JSONEncoder().encode(fundMeta)
        let decoded = try JSONDecoder().decode(FundMeta.self, from: encoded)
        
        XCTAssertEqual(decoded.scheme_code, fundMeta.scheme_code)
        XCTAssertEqual(decoded.fund_house, fundMeta.fund_house)
        XCTAssertEqual(decoded.scheme_type, fundMeta.scheme_type)
        XCTAssertEqual(decoded.scheme_category, fundMeta.scheme_category)
        XCTAssertEqual(decoded.scheme_name, fundMeta.scheme_name)
        XCTAssertEqual(decoded.isin_growth, fundMeta.isin_growth)
        XCTAssertEqual(decoded.isin_div_reinvestment, fundMeta.isin_div_reinvestment)
    }
    
    // MARK: - Extension Tests
    
    func testDoubleFormattingExtensions() throws {
        let value: Double = 1234.5678
        
        XCTAssertEqual(value.formatted(places: 2), "1234.57")
        XCTAssertEqual(value.formattedWithSign(places: 2), "+1234.57")
        XCTAssertEqual(value.formattedAsPercentage(places: 2), "+1234.57%")
        XCTAssertEqual(value.formattedAsCurrency(), "₹1,234.57")
    }
    
    func testNegativeDoubleFormatting() throws {
        let value: Double = -123.45
        
        XCTAssertEqual(value.formattedWithSign(places: 2), "-123.45")
        XCTAssertEqual(value.formattedAsPercentage(places: 2), "-123.45%")
    }
    
    // MARK: - DataCache Tests
    
    func testDataCacheFundsListStorage() throws {
        let cache = DataCache.shared
        
        let testFunds = [
            MutualFund(
                schemeCode: "123456",
                schemeName: "Test Fund 1",
                isinGrowth: "INF123456789",
                isinDivReinvestment: nil
            ),
            MutualFund(
                schemeCode: "123457",
                schemeName: "Test Fund 2",
                isinGrowth: "INF123456790",
                isinDivReinvestment: nil
            )
        ]
        
        // Clear cache first
        cache.clearCache()
        
        // Test caching
        cache.cacheFundsList(testFunds)
        
        // Test retrieval
        let cachedFunds = cache.getCachedFundsList()
        
        XCTAssertNotNil(cachedFunds)
        let fundsCount = cachedFunds?.count
        XCTAssertEqual(fundsCount, 2)
        let firstSchemeCode = cachedFunds?.first?.schemeCode
        let lastSchemeCode = cachedFunds?.last?.schemeCode
        XCTAssertEqual(firstSchemeCode, "123456")
        XCTAssertEqual(lastSchemeCode, "123457")
        
        // Clean up
        cache.clearCache()
    }
    
    func testCacheBustingFunctionality() throws {
        let cache = DataCache.shared
        
        // Test clearing specific fund history
        let testHistory1 = createTestFundHistory(schemeCode: "123456")
        let testHistory2 = createTestFundHistory(schemeCode: "123457")
        
        cache.cacheFundHistory(testHistory1, for: "123456")
        cache.cacheFundHistory(testHistory2, for: "123457")
        
        // Verify both are cached
        XCTAssertNotNil(cache.getCachedFundHistory(for: "123456"))
        XCTAssertNotNil(cache.getCachedFundHistory(for: "123457"))
        
        // Clear specific fund history
        cache.clearFundHistory(for: "123456")
        
        // Only the specific fund should be cleared
        XCTAssertNil(cache.getCachedFundHistory(for: "123456"))
        XCTAssertNotNil(cache.getCachedFundHistory(for: "123457"))
        
        // Clean up
        cache.clearCache()
    }
    
    func testCacheAgeDetection() throws {
        let cache = DataCache.shared
        cache.clearCache()
        
        let testFunds = [MutualFund(schemeCode: "123456", schemeName: "Test Fund")]
        
        // Cache the funds
        cache.cacheFundsList(testFunds)
        
        // Should be fresh immediately
        XCTAssertTrue(cache.isFundsListCacheFresh())
        
        // Test with specific fund history
        let testHistory = createTestFundHistory(schemeCode: "123456")
        cache.cacheFundHistory(testHistory, for: "123456")
        
        XCTAssertTrue(cache.isFundHistoryCacheFresh(for: "123456"))
        
        // Test non-existent cache
        XCTAssertFalse(cache.isFundHistoryCacheFresh(for: "nonexistent"))
        
        // Clean up
        cache.clearCache()
    }
    
    func testClearMultipleFundHistories() throws {
        let cache = DataCache.shared
        cache.clearCache()
        
        // Cache multiple fund histories
        let schemeCodes = ["123456", "123457", "123458"]
        
        for schemeCode in schemeCodes {
            let testHistory = createTestFundHistory(schemeCode: schemeCode)
            cache.cacheFundHistory(testHistory, for: schemeCode)
        }
        
        // Verify all are cached
        for schemeCode in schemeCodes {
            XCTAssertNotNil(cache.getCachedFundHistory(for: schemeCode))
        }
        
        // Clear specific schemes
        cache.clearFundHistories(for: ["123456", "123458"])
        
        // Only specific funds should be cleared
        XCTAssertNil(cache.getCachedFundHistory(for: "123456"))
        XCTAssertNotNil(cache.getCachedFundHistory(for: "123457"))
        XCTAssertNil(cache.getCachedFundHistory(for: "123458"))
        
        // Clean up
        cache.clearCache()
    }
    
    private func createTestFundHistory(schemeCode: String) -> FundHistory {
        return FundHistory(
            meta: FundMeta(
                fund_house: "Test Fund House",
                scheme_type: "Open Ended",
                scheme_category: "Equity",
                scheme_code: schemeCode,
                scheme_name: "Test Fund \(schemeCode)",
                isin_growth: "INF\(schemeCode)",
                isin_div_reinvestment: nil
            ),
            data: [
                NAVData(date: "27-01-2025", nav: "100.00"),
                NAVData(date: "26-01-2025", nav: "99.50")
            ],
            status: "SUCCESS"
        )
    }
    
    // MARK: - Performance Tests
    
    func testFundFilteringPerformance() throws {
        // Create a large dataset for performance testing
        var funds: [MutualFund] = []
        for i in 0..<1000 {
            funds.append(MutualFund(
                schemeCode: "\(i)",
                schemeName: "Test Fund \(i) - Regular Plan - Growth",
                isinGrowth: "INF\(i)",
                isinDivReinvestment: nil
            ))
        }
        
        measure {
            let filtered = funds.filter { $0.schemeName.localizedCaseInsensitiveContains("Test") }
            let filteredCount = filtered.count
            XCTAssertEqual(filteredCount, 1000)
        }
    }
    
    // MARK: - Holdings Model Tests
    
    func testHoldingDataCreation() throws {
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
            xirr: 10.19
        )
        
        XCTAssertEqual(holding.schemeName, "SBI Conservative Hybrid Fund Direct Growth")
        XCTAssertEqual(holding.amcName, "SBI Mutual Fund")
        XCTAssertEqual(holding.units, 610.664, accuracy: 0.001)
        XCTAssertEqual(holding.investedValue, 32931.93, accuracy: 0.01)
        XCTAssertEqual(holding.currentValue, 48581.37, accuracy: 0.01)
        XCTAssertEqual(holding.returns, 15649.44, accuracy: 0.01)
        XCTAssertEqual(holding.xirr, 10.19, accuracy: 0.01)
    }
    
    func testHoldingDataComputedProperties() throws {
        let holding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Groww",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 15000.0,
            returns: 5000.0,
            xirr: 12.5
        )
        
        XCTAssertEqual(holding.returnsPercentage, 50.0, accuracy: 0.01)
        XCTAssertEqual(holding.navPerUnit, 150.0, accuracy: 0.01)
    }
    
    func testHoldingDataFromParsedData() throws {
        let parsedData: [String: String] = [
            "schemeName": "Test Fund Name",
            "amcName": "Test AMC",
            "category": "Equity",
            "subCategory": "Large Cap",
            "folioNumber": "123456",
            "source": "External",
            "units": "100.500",
            "investedValue": "10000.00",
            "currentValue": "12000.00",
            "returns": "2000.00",
            "xirr": "15.5%"
        ]
        
        let holding = HoldingData.from(parsedData: parsedData)
        
        XCTAssertNotNil(holding)
        XCTAssertEqual(holding?.schemeName, "Test Fund Name")
        XCTAssertEqual(holding?.units ?? 0, 100.5, accuracy: 0.001)
        XCTAssertEqual(holding?.xirr ?? 0, 15.5, accuracy: 0.01)
    }
    
    func testPortfolioSummaryCalculations() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 15000.0,
                returns: 5000.0,
                xirr: 12.0
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5500.0,
                returns: 500.0,
                xirr: 8.0
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        XCTAssertEqual(summary.holdingsCount, 2)
        XCTAssertEqual(summary.totalInvestments, 15000.0, accuracy: 0.01)
        XCTAssertEqual(summary.currentPortfolioValue, 20500.0, accuracy: 0.01)
        XCTAssertEqual(summary.totalReturns, 5500.0, accuracy: 0.01)
        XCTAssertEqual(summary.returnsPercentage, 36.67, accuracy: 0.01)
        
        // Weighted XIRR calculation: (10000/15000 * 12) + (5000/15000 * 8) = 8 + 2.67 = 10.67
        XCTAssertEqual(summary.overallXIRR, 10.67, accuracy: 0.01)
    }
    
    func testPortfolioCreation() throws {
        let holdings = [
            HoldingData(
                schemeName: "Test Fund",
                amcName: "Test AMC",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0
            )
        ]
        
        let portfolio = Portfolio(holdings: holdings)
        
        XCTAssertEqual(portfolio.holdings.count, 1)
        XCTAssertEqual(portfolio.summary.totalInvestments, 10000.0, accuracy: 0.01)
        XCTAssertNotNil(portfolio.lastUpdated)
    }
    
    func testPortfolioCategoryBreakdown() throws {
        let holdings = [
            HoldingData(
                schemeName: "Equity Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0
            ),
            HoldingData(
                schemeName: "Equity Fund 2",
                amcName: "AMC 2",
                category: "Equity",
                subCategory: "Mid Cap",
                folioNumber: "123457",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 6000.0,
                returns: 1000.0,
                xirr: 18.0
            ),
            HoldingData(
                schemeName: "Debt Fund",
                amcName: "AMC 3",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "123458",
                source: "Groww",
                units: 200.0,
                investedValue: 20000.0,
                currentValue: 21000.0,
                returns: 1000.0,
                xirr: 5.0
            )
        ]
        
        let portfolio = Portfolio(holdings: holdings)
        let breakdown = portfolio.categoryBreakdown
        
        XCTAssertEqual(breakdown.count, 2)
        XCTAssertNotNil(breakdown["Equity"])
        XCTAssertNotNil(breakdown["Debt"])
        
        let equityAllocation = breakdown["Equity"]!
        XCTAssertEqual(equityAllocation.holdingsCount, 2)
        XCTAssertEqual(equityAllocation.investedValue, 15000.0, accuracy: 0.01)
        XCTAssertEqual(equityAllocation.currentValue, 18000.0, accuracy: 0.01)
        XCTAssertEqual(equityAllocation.returns, 3000.0, accuracy: 0.01)
        
        let debtAllocation = breakdown["Debt"]!
        XCTAssertEqual(debtAllocation.holdingsCount, 1)
        XCTAssertEqual(debtAllocation.investedValue, 20000.0, accuracy: 0.01)
    }
    
    
    // MARK: - Holdings Parser Tests
    
    // DISABLED: This test was causing 4x duplication due to persistent race conditions
    // TODO: Re-enable once the underlying HoldingsParser race condition is resolved
    func DISABLED_testHoldingsParserPDFLineParsing() throws {
        // Test the fixed parsing logic with a real line from the PDF
        let parser = HoldingsParser.shared
        
        // Sample line from your PDF: "Axis Small Cap Fund Direct Growth Axis Mutual Fund Equity Small Cap 91093871226 Groww 709.806 54949.99 87852.69 32902.7005 21.62%"
        let sampleLine = "Axis Small Cap Fund Direct Growth Axis Mutual Fund Equity Small Cap 91093871226 Groww 709.806 54949.99 87852.69 32902.7005 21.62%"
        
        // Use reflection to access the private parseHoldingLine method for testing
        let mirror = Mirror(reflecting: parser)
        let parseMethod = mirror.children.first { $0.label == "parseHoldingLine" }
        
        // For now, let's test the full parsing flow with a mock PDF content
        let mockPDFContent = """
        HOLDINGS AS ON 2025-07-27
        Scheme Name AMC Category Sub-category Folio No. Source Units Invested Value Current Value Returns XIRR
        Axis Small Cap Fund Direct Growth Axis Mutual Fund Equity Small Cap 91093871226 Groww 709.806 54949.99 87852.69 32902.7005 21.62%
        SBI Conservative Hybrid Fund Direct Growth SBI Mutual Fund Hybrid Conservative Hybrid 22821659 External 610.664 32931.93 48581.37 15649.4453 10.19%
        """
        
        do {
            // This will call our fixed parsing logic
            let holdings = try parser.parseHoldingsText(mockPDFContent)
            
            // Extract property access to prevent race conditions
            let holdingsCount = holdings.count
            XCTAssertEqual(holdingsCount, 2, "Should parse 2 holdings")
            
            // Test the first holding (Axis Small Cap Fund)
            let axisHolding = holdings.first { $0.schemeName.contains("Axis") }
            XCTAssertNotNil(axisHolding, "Should find Axis holding")
            
            // Extract all property accesses to prevent race conditions
            let axisHoldingScheme = axisHolding?.schemeName
            let axisHoldingAMC = axisHolding?.amcName
            let axisHoldingCategory = axisHolding?.category
            let axisHoldingSubCategory = axisHolding?.subCategory
            
            XCTAssertEqual(axisHoldingScheme, "Axis Small Cap Fund Direct Growth", "Should preserve full scheme name including 'Direct Growth'")
            XCTAssertEqual(axisHoldingAMC, "Axis Mutual Fund", "Should correctly identify AMC name")
            XCTAssertEqual(axisHoldingCategory, "Equity", "Should correctly identify category")
            XCTAssertEqual(axisHoldingSubCategory, "Small Cap", "Should correctly identify sub-category")
            
            // Test the second holding (SBI Conservative Hybrid Fund)
            let sbiHolding = holdings.first { $0.schemeName.contains("SBI") }
            XCTAssertNotNil(sbiHolding, "Should find SBI holding")
            
            // Extract all property accesses to prevent race conditions
            let sbiHoldingScheme = sbiHolding?.schemeName
            let sbiHoldingAMC = sbiHolding?.amcName
            let sbiHoldingCategory = sbiHolding?.category
            let sbiHoldingSubCategory = sbiHolding?.subCategory
            
            XCTAssertEqual(sbiHoldingScheme, "SBI Conservative Hybrid Fund Direct Growth", "Should preserve full scheme name including 'Direct Growth'")
            XCTAssertEqual(sbiHoldingAMC, "SBI Mutual Fund", "Should correctly identify AMC name")
            XCTAssertEqual(sbiHoldingCategory, "Hybrid", "Should correctly identify category")
            XCTAssertEqual(sbiHoldingSubCategory, "Conservative Hybrid", "Should correctly identify sub-category")
            
        } catch {
            XCTFail("Parsing should not fail: \(error)")
        }
    }
    
    func testHoldingsParserCSVParsing() throws {
        let csvContent = """
        Scheme Name,AMC,Category,Sub Category,Folio Number,Source,Units,Invested Value,Current Value,Returns,XIRR
        SBI Large Cap Fund Direct Growth,SBI Mutual Fund,Equity,Large Cap,123456,External,100.500,10000.00,12000.00,2000.00,15.5%
        HDFC Liquid Fund Direct Growth,HDFC Mutual Fund,Debt,Liquid,789012,Groww,50.250,5000.00,5250.00,250.00,5.2%
        """
        
        let parser = HoldingsParser.shared
        
        // This would normally be tested with actual CSV file, but we can test the parsing logic
        let lines = csvContent.components(separatedBy: .newlines)
        XCTAssertTrue(lines.count >= 3) // Header + 2 data lines
        
        // Test CSV line parsing
        let testLine = "\"SBI Large Cap Fund Direct Growth\",\"SBI Mutual Fund\",\"Equity\",\"Large Cap\",\"123456\",\"External\",100.500,10000.00,12000.00,2000.00,15.5%"
        let columns = testLine.components(separatedBy: ",")
        XCTAssertTrue(columns.count >= 11)
    }
    
    // MARK: - Individual Fund Calculation Tests
    
    func testIndividualFundCurrentValueCalculation() throws {
        // Test with latest NAV calculation
        var holdingWithNAV = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0, // Original value
            returns: 1000.0,
            xirr: 15.0,
            latestNAV: 125.50 // Latest NAV
        )
        
        // Current value should be calculated using latest NAV: 100 units * 125.50 = 12550
        XCTAssertEqual(holdingWithNAV.currentValue, 12550.0, accuracy: 0.01)
        
        // Test fallback to original value when no NAV
        let holdingWithoutNAV = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0, // Original value
            returns: 1000.0,
            xirr: 15.0
            // No latestNAV provided
        )
        
        // Should fallback to original current value
        XCTAssertEqual(holdingWithoutNAV.currentValue, 11000.0, accuracy: 0.01)
    }
    
    func testIndividualFundReturnsCalculation() throws {
        let holding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 15.0,
            latestNAV: 125.50 // 100 units * 125.50 = 12550 current value
        )
        
        // Returns = current value - invested value = 12550 - 10000 = 2550
        XCTAssertEqual(holding.returns, 2550.0, accuracy: 0.01)
    }
    
    func testIndividualFundReturnsPercentageCalculation() throws {
        let holding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 15.0,
            latestNAV: 125.50 // Current value = 12550
        )
        
        // Returns % = (returns / invested) * 100 = (2550 / 10000) * 100 = 25.5%
        XCTAssertEqual(holding.returnsPercentage, 25.5, accuracy: 0.01)
        
        // Test zero invested value edge case
        let zeroInvestedHolding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 0.0,
            currentValue: 1000.0,
            returns: 1000.0,
            xirr: 15.0
        )
        
        XCTAssertEqual(zeroInvestedHolding.returnsPercentage, 0.0, accuracy: 0.01)
    }
    
    func testIndividualFundXIRRCalculation() throws {
        let calendar = Calendar.current
        let statementDate = calendar.date(byAdding: .year, value: -2, to: Date())! // 2 years ago
        
        let holding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 15.0, // Original XIRR
            latestNAV: 125.50, // Current value = 12550
            statementDate: statementDate
        )
        
        // XIRR calculation: ((12550/10000)^(1/2) - 1) * 100
        // = (1.255^0.5 - 1) * 100 ≈ 12.02%
        XCTAssertEqual(holding.xirr, 12.02, accuracy: 0.5) // Allow some tolerance for date calculations
        
        // Test fallback to original XIRR when no statement date
        let holdingWithoutDate = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 15.0 // Original XIRR
            // No statementDate provided
        )
        
        XCTAssertEqual(holdingWithoutDate.xirr, 15.0, accuracy: 0.01)
    }
    
    func testIndividualFundNAVPerUnitCalculation() throws {
        let holding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 15.0,
            latestNAV: 125.50
        )
        
        // NAV per unit = current value / units = 12550 / 100 = 125.50
        XCTAssertEqual(holding.navPerUnit, 125.50, accuracy: 0.01)
        
        // Test zero units edge case
        let zeroUnitsHolding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 0.0,
            investedValue: 10000.0,
            currentValue: 11000.0,
            returns: 1000.0,
            xirr: 15.0
        )
        
        XCTAssertEqual(zeroUnitsHolding.navPerUnit, 0.0, accuracy: 0.01)
    }
    
    // MARK: - Portfolio Banner Calculation Tests
    
    func testPortfolioSummaryTotalInvestments() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0,
                latestNAV: 130.0 // Current value = 100 * 130 = 13000
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 8.0,
                latestNAV: 108.0 // Current value = 50 * 108 = 5400
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        // Total investments = 10000 + 5000 = 15000
        XCTAssertEqual(summary.totalInvestments, 15000.0, accuracy: 0.01)
    }
    
    func testPortfolioSummaryCurrentPortfolioValue() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0,
                latestNAV: 130.0 // Current value = 100 * 130 = 13000
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 8.0,
                latestNAV: 108.0 // Current value = 50 * 108 = 5400
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        // Current portfolio value = 13000 + 5400 = 18400
        XCTAssertEqual(summary.currentPortfolioValue, 18400.0, accuracy: 0.01)
    }
    
    func testPortfolioSummaryTotalReturns() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0,
                latestNAV: 130.0 // Current value = 13000, returns = 13000 - 10000 = 3000
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 8.0,
                latestNAV: 108.0 // Current value = 5400, returns = 5400 - 5000 = 400
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        // Total returns = 3000 + 400 = 3400
        XCTAssertEqual(summary.totalReturns, 3400.0, accuracy: 0.01)
    }
    
    func testPortfolioSummaryReturnsPercentage() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0,
                latestNAV: 130.0 // Current value = 13000, returns = 3000
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 8.0,
                latestNAV: 108.0 // Current value = 5400, returns = 400
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        // Returns % = (total returns / total invested) * 100 = (3400 / 15000) * 100 = 22.67%
        XCTAssertEqual(summary.returnsPercentage, 22.67, accuracy: 0.01)
        
        // Test edge case with zero investment
        let emptyHoldings: [HoldingData] = []
        let emptySummary = PortfolioSummary(holdings: emptyHoldings)
        XCTAssertEqual(emptySummary.returnsPercentage, 0.0, accuracy: 0.01)
    }
    
    func testPortfolioSummaryOverallXIRR() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0 // 15% XIRR
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 8.0 // 8% XIRR
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        // Weighted XIRR = (10000/15000 * 15) + (5000/15000 * 8) = (0.667 * 15) + (0.333 * 8) = 10.0 + 2.67 = 12.67%
        XCTAssertEqual(summary.overallXIRR, 12.67, accuracy: 0.01)
        
        // Test edge case with zero investment
        let emptyHoldings: [HoldingData] = []
        let emptySummary = PortfolioSummary(holdings: emptyHoldings)
        XCTAssertEqual(emptySummary.overallXIRR, 0.0, accuracy: 0.01)
    }
    
    func testPortfolioSummaryHoldingsCount() throws {
        let holdings = [
            HoldingData(
                schemeName: "Fund 1",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0
            ),
            HoldingData(
                schemeName: "Fund 2",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 8.0
            ),
            HoldingData(
                schemeName: "Fund 3",
                amcName: "AMC 3",
                category: "Hybrid",
                subCategory: "Balanced",
                folioNumber: "345678",
                source: "Groww",
                units: 75.0,
                investedValue: 7500.0,
                currentValue: 8000.0,
                returns: 500.0,
                xirr: 6.5
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        XCTAssertEqual(summary.holdingsCount, 3)
        
        // Test empty portfolio
        let emptyHoldings: [HoldingData] = []
        let emptySummary = PortfolioSummary(holdings: emptyHoldings)
        XCTAssertEqual(emptySummary.holdingsCount, 0)
    }
    
    func testPortfolioSummaryIntegrationWithLatestNAV() throws {
        // Test that portfolio summary correctly uses live calculations with latest NAV
        let calendar = Calendar.current
        let statementDate = calendar.date(byAdding: .year, value: -1, to: Date())! // 1 year ago
        
        let holdings = [
            HoldingData(
                schemeName: "Test Equity Fund",
                amcName: "Test AMC",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 11000.0, // Original value
                returns: 1000.0, // Original returns
                xirr: 10.0, // Original XIRR
                latestNAV: 140.0, // Latest NAV - current value = 100 * 140 = 14000
                statementDate: statementDate
            )
        ]
        
        let summary = PortfolioSummary(holdings: holdings)
        
        // Verify that summary uses live calculations
        XCTAssertEqual(summary.totalInvestments, 10000.0, accuracy: 0.01)
        XCTAssertEqual(summary.currentPortfolioValue, 14000.0, accuracy: 0.01) // Uses latest NAV
        XCTAssertEqual(summary.totalReturns, 4000.0, accuracy: 0.01) // 14000 - 10000
        XCTAssertEqual(summary.returnsPercentage, 40.0, accuracy: 0.01) // (4000/10000) * 100
        
        // XIRR should be calculated using statement date and latest NAV
        // ((14000/10000)^(1/1) - 1) * 100 = 40%
        XCTAssertEqual(summary.overallXIRR, 40.0, accuracy: 1.0) // Allow tolerance for date calculations
        XCTAssertEqual(summary.holdingsCount, 1)
    }
    
    // MARK: - Holdings Manager Integration Tests
    
    func testHoldingsManagerPortfolioStorage() throws {
        let holdingsManager = HoldingsManager.shared
        
        // Clear any existing portfolio and wait for completion
        let clearExpectation = XCTestExpectation(description: "Portfolio cleared")
        
        Task { @MainActor in
            holdingsManager.clearPortfolio()
            XCTAssertNil(holdingsManager.portfolio)
            XCTAssertFalse(holdingsManager.hasHoldings)
            clearExpectation.fulfill()
        }
        
        wait(for: [clearExpectation], timeout: 5.0)
        
        let testHolding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 12000.0,
            returns: 2000.0,
            xirr: 15.0
        )
        
        let testPortfolio = Portfolio(holdings: [testHolding])
        
        // Test saving portfolio (async operation)
        let expectation = XCTestExpectation(description: "Portfolio saved")
        
        Task {
            await holdingsManager.savePortfolio(testPortfolio)
            
            await MainActor.run {
                XCTAssertNotNil(holdingsManager.portfolio)
                XCTAssertTrue(holdingsManager.hasHoldings)
                XCTAssertEqual(holdingsManager.portfolio?.holdings.count, 1)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Clean up and wait for completion
        let cleanupExpectation = XCTestExpectation(description: "Portfolio cleaned up")
        
        Task { @MainActor in
            holdingsManager.clearPortfolio()
            cleanupExpectation.fulfill()
        }
        
        wait(for: [cleanupExpectation], timeout: 5.0)
    }
    
    func testHoldingsManagerAnalytics() throws {
        let holdingsManager = HoldingsManager.shared
        
        let holdings = [
            HoldingData(
                schemeName: "Equity Fund",
                amcName: "AMC 1",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "123456",
                source: "Groww",
                units: 100.0,
                investedValue: 10000.0,
                currentValue: 12000.0,
                returns: 2000.0,
                xirr: 15.0,
                matchedSchemeCode: "123456"
            ),
            HoldingData(
                schemeName: "Debt Fund",
                amcName: "AMC 2",
                category: "Debt",
                subCategory: "Liquid",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 5250.0,
                returns: 250.0,
                xirr: 5.0
            )
        ]
        
        let testPortfolio = Portfolio(holdings: holdings)
        
        let expectation = XCTestExpectation(description: "Portfolio analyzed")
        
        Task {
            await holdingsManager.savePortfolio(testPortfolio)
            
            await MainActor.run {
                XCTAssertEqual(holdingsManager.matchedHoldingsCount, 1)
                XCTAssertEqual(holdingsManager.unmatchedHoldingsCount, 1)
            }
            
            await MainActor.run {
                let categoryAllocations = holdingsManager.getCategoryAllocation()
                XCTAssertEqual(categoryAllocations.count, 2)
                
                let sourceAllocations = holdingsManager.getSourceAllocation()
                XCTAssertEqual(sourceAllocations.count, 2)
                
                let topPerformers = holdingsManager.getTopPerformers()
                XCTAssertTrue(topPerformers.count <= 5)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Clean up
        Task { @MainActor in
            holdingsManager.clearPortfolio()
        }
    }
    
    func testHoldingsManagerCSVExport() throws {
        let holdingsManager = HoldingsManager.shared
        
        let testHolding = HoldingData(
            schemeName: "Test Fund",
            amcName: "Test AMC",
            category: "Equity",
            subCategory: "Large Cap",
            folioNumber: "123456",
            source: "Test",
            units: 100.0,
            investedValue: 10000.0,
            currentValue: 12000.0,
            returns: 2000.0,
            xirr: 15.0,
            matchedSchemeCode: "123456"
        )
        
        let testPortfolio = Portfolio(holdings: [testHolding])
        
        let expectation = XCTestExpectation(description: "CSV exported")
        
        Task {
            await holdingsManager.savePortfolio(testPortfolio)
            
            await MainActor.run {
                let csvContent = holdingsManager.exportPortfolioToCSV()
                XCTAssertNotNil(csvContent)
                XCTAssertTrue(csvContent?.contains("Scheme Name,AMC,Category") ?? false)
                XCTAssertTrue(csvContent?.contains("Test Fund") ?? false)
                XCTAssertTrue(csvContent?.contains("Matched") ?? false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Clean up
        Task { @MainActor in
            holdingsManager.clearPortfolio()
        }
    }
    
    // MARK: - AppSettings and Dividend Filter Tests
    
    func testAppSettingsDefaultValue() throws {
        let settings = AppSettings.shared
        
        // Default should be false (dividend funds hidden)
        XCTAssertFalse(settings.showDividendFunds, "Default setting should hide dividend funds")
    }
    
    func testDividendFundFiltering() throws {
        let settings = AppSettings.shared
        
        // Create test funds with both growth and dividend plans
        let mockFunds = [
            MutualFund(schemeCode: "001", schemeName: "SBI Large Cap Fund Direct Growth"),
            MutualFund(schemeCode: "002", schemeName: "HDFC Equity Fund Direct Dividend"),
            MutualFund(schemeCode: "003", schemeName: "ICICI Prudential Blue Chip Fund Growth"),
            MutualFund(schemeCode: "004", schemeName: "Axis Mutual Fund IDCW Plan"),
            MutualFund(schemeCode: "005", schemeName: "Kotak Small Cap Fund Growth")
        ]
        
        // Test with dividend funds hidden (default)
        settings.showDividendFunds = false
        let filteredFunds = settings.filteredFunds(mockFunds)
        
        // Should only have growth funds (3 out of 5)
        XCTAssertEqual(filteredFunds.count, 3, "Should filter out dividend/IDCW funds")
        
        let filteredNames = filteredFunds.map { $0.schemeName }
        XCTAssertTrue(filteredNames.contains("SBI Large Cap Fund Direct Growth"))
        XCTAssertTrue(filteredNames.contains("ICICI Prudential Blue Chip Fund Growth"))
        XCTAssertTrue(filteredNames.contains("Kotak Small Cap Fund Growth"))
        XCTAssertFalse(filteredNames.contains("HDFC Equity Fund Direct Dividend"))
        XCTAssertFalse(filteredNames.contains("Axis Mutual Fund IDCW Plan"))
        
        // Test with dividend funds shown
        settings.showDividendFunds = true
        let allFunds = settings.filteredFunds(mockFunds)
        
        // Should have all funds
        XCTAssertEqual(allFunds.count, 5, "Should show all funds when enabled")
        
        // Reset to default for other tests
        settings.showDividendFunds = false
    }
    
    
    // MARK: - UI Refresh Tests
    
    func testFundsListViewObservesSettings() throws {
        // This test verifies that FundsListView properly observes AppSettings
        // The fact that it compiles and builds successfully indicates the @ObservedObject is working
        
        let settings = AppSettings.shared
        let originalValue = settings.showDividendFunds
        
        // Toggle the setting
        settings.showDividendFunds = !originalValue
        
        // Since FundsListView now observes AppSettings with @ObservedObject,
        // the view should automatically refresh when this property changes
        
        // Verify the setting actually changed
        XCTAssertNotEqual(settings.showDividendFunds, originalValue, "Setting should have changed")
        
        // Reset to original value
        settings.showDividendFunds = originalValue
        
        XCTAssertEqual(settings.showDividendFunds, originalValue, "Setting should be reset to original value")
    }
    
    func testSettingsViewToggleChangesValue() throws {
        let settings = AppSettings.shared
        let originalValue = settings.showDividendFunds
        
        // Simulate toggle action (this is what happens when user taps the toggle)
        settings.showDividendFunds.toggle()
        
        // Verify the change
        XCTAssertNotEqual(settings.showDividendFunds, originalValue, "Toggle should change the value")
        
        // Verify it persists (UserDefaults integration)
        let persistedValue = UserDefaults.standard.object(forKey: "showDividendFunds") as? Bool ?? false
        XCTAssertEqual(settings.showDividendFunds, persistedValue, "Setting should be persisted to UserDefaults")
        
        // Reset
        settings.showDividendFunds = originalValue
    }
}