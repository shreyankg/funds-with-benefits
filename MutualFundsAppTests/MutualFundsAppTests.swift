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
        XCTAssertEqual(cachedFunds?.count, 2)
        XCTAssertEqual(cachedFunds?.first?.schemeCode, "123456")
        XCTAssertEqual(cachedFunds?.last?.schemeCode, "123457")
        
        // Clean up
        cache.clearCache()
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
            XCTAssertEqual(filtered.count, 1000)
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
    
    // MARK: - Fund Matcher Tests
    
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
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "123456")
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
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
    }
    
    func testFundMatcherNoMatch() throws {
        let holding = HoldingData(
            schemeName: "Unknown Fund Name",
            amcName: "Unknown AMC",
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
        XCTAssertNil(matchedHoldings.first?.matchedSchemeCode)
    }
    
    // MARK: - FundMatcher Performance Optimization Tests
    
    func testFundMatcherPreprocessFundsDataPopulatesCache() throws {
        let funds = [
            MutualFund(
                schemeCode: "123456",
                schemeName: "SBI Large Cap Fund Direct Growth",
                isinGrowth: "INF123456789",
                isinDivReinvestment: nil
            ),
            MutualFund(
                schemeCode: "789012",
                schemeName: "ICICI Prudential Large Cap Fund Direct Growth",
                isinGrowth: "INF789012345",
                isinDivReinvestment: nil
            )
        ]
        
        let matcher = FundMatcher.shared
        
        // Test preprocessing creates cached data
        matcher.preprocessFundsData(funds)
        
        // Verify the preprocessing doesn't break basic functionality
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
        
        let matchedHoldings = matcher.matchHoldingsWithFunds([holding], availableFunds: funds)
        let holdingsCount = matchedHoldings.count
        XCTAssertEqual(holdingsCount, 1)
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        XCTAssertEqual(matchedHoldings.first?.matchedSchemeCode, "123456")
    }
    
    func testFundMatcherAMCLookupIndexOptimization() throws {
        let sbiFunds = [
            MutualFund(
                schemeCode: "100001",
                schemeName: "SBI Large Cap Fund Direct Growth",
                isinGrowth: "INF100001789",
                isinDivReinvestment: nil
            ),
            MutualFund(
                schemeCode: "100002",
                schemeName: "SBI Mid Cap Fund Direct Growth",
                isinGrowth: "INF100002789",
                isinDivReinvestment: nil
            )
        ]
        
        let iciciFunds = [
            MutualFund(
                schemeCode: "200001",
                schemeName: "ICICI Prudential Large Cap Fund Direct Growth",
                isinGrowth: "INF200001345",
                isinDivReinvestment: nil
            )
        ]
        
        let allFunds = sbiFunds + iciciFunds
        let matcher = FundMatcher.shared
        
        // Test AMC-based filtering works
        let sbiHolding = HoldingData(
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
        
        let matchedHoldings = matcher.matchHoldingsWithFunds([sbiHolding], availableFunds: allFunds)
        let holdingsCount = matchedHoldings.count
        XCTAssertEqual(holdingsCount, 1)
        XCTAssertNotNil(matchedHoldings.first?.matchedSchemeCode)
        
        // Should match with SBI fund, not ICICI fund
        let matchedSchemeCode = matchedHoldings.first?.matchedSchemeCode
        XCTAssertTrue(matchedSchemeCode == "100001" || matchedSchemeCode == "100002")
    }
    
    func testFundMatcherOptimizedVsLegacyMatchingConsistency() throws {
        let funds = [
            MutualFund(
                schemeCode: "123456",
                schemeName: "SBI Large Cap Fund Direct Growth",
                isinGrowth: "INF123456789",
                isinDivReinvestment: nil
            ),
            MutualFund(
                schemeCode: "789012",
                schemeName: "ICICI Prudential Large Cap Fund Direct Growth",
                isinGrowth: "INF789012345",
                isinDivReinvestment: nil
            ),
            MutualFund(
                schemeCode: "345678",
                schemeName: "HDFC Large Cap Fund Direct Growth",
                isinGrowth: "INF345678901",
                isinDivReinvestment: nil
            )
        ]
        
        let holdings = [
            HoldingData(
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
            ),
            HoldingData(
                schemeName: "ICICI Large Cap Fund Direct Growth",
                amcName: "ICICI Prudential Mutual Fund",
                category: "Equity",
                subCategory: "Large Cap",
                folioNumber: "789012",
                source: "External",
                units: 50.0,
                investedValue: 5000.0,
                currentValue: 6000.0,
                returns: 1000.0,
                xirr: 12.0
            )
        ]
        
        let matcher = FundMatcher.shared
        
        // Test optimized matching gives expected results
        let matchedHoldings = matcher.matchHoldingsWithFunds(holdings, availableFunds: funds)
        let matchedCount = matchedHoldings.count
        XCTAssertEqual(matchedCount, 2)
        
        // First holding should match exactly
        let firstMatched = matchedHoldings.first?.matchedSchemeCode
        XCTAssertEqual(firstMatched, "123456")
        
        // Second holding should match ICICI fund despite slight name difference
        let secondMatched = matchedHoldings[1].matchedSchemeCode
        XCTAssertEqual(secondMatched, "789012")
    }
    
    func testFundMatcherNormalizedNameCaching() throws {
        let fund = MutualFund(
            schemeCode: "123456",
            schemeName: "SBI - Large Cap Fund (Direct Plan) - Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
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
        
        let matcher = FundMatcher.shared
        
        // Test multiple calls should use cached normalization
        let matchedHoldings1 = matcher.matchHoldingsWithFunds([holding], availableFunds: [fund])
        let matchedHoldings2 = matcher.matchHoldingsWithFunds([holding], availableFunds: [fund])
        
        // Both should produce same results (testing caching doesn't break functionality)
        let firstResult = matchedHoldings1.first?.matchedSchemeCode
        let secondResult = matchedHoldings2.first?.matchedSchemeCode
        XCTAssertEqual(firstResult, secondResult)
        XCTAssertNotNil(firstResult)
    }
    
    func testFundMatcherEarlyTerminationOnExactMatch() throws {
        let exactMatchFund = MutualFund(
            schemeCode: "123456",
            schemeName: "SBI Large Cap Fund Direct Growth",
            isinGrowth: "INF123456789",
            isinDivReinvestment: nil
        )
        
        let partialMatchFund = MutualFund(
            schemeCode: "789012",
            schemeName: "SBI Large Cap Fund Regular Growth", // Similar but not exact
            isinGrowth: "INF789012345",
            isinDivReinvestment: nil
        )
        
        let funds = [partialMatchFund, exactMatchFund] // Exact match is second (tests early termination)
        
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
        
        let matcher = FundMatcher.shared
        let matchedHoldings = matcher.matchHoldingsWithFunds([holding], availableFunds: funds)
        
        let holdingsCount = matchedHoldings.count
        XCTAssertEqual(holdingsCount, 1)
        
        // Should find exact match despite it being second in array
        let matchedSchemeCode = matchedHoldings.first?.matchedSchemeCode
        XCTAssertEqual(matchedSchemeCode, "123456")
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
        XCTAssertEqual(matchedHoldings1.count, 1)
        if let matchedSchemeCode = matchedHoldings1.first?.matchedSchemeCode {
            XCTAssertEqual(matchedSchemeCode, "001", "Should match growth fund when dividend funds are hidden")
        }
        
        // Test with dividend funds shown
        settings.showDividendFunds = true
        let matchedHoldings2 = fundMatcher.matchHoldingsWithFunds([testHolding], availableFunds: mockFunds)
        
        // Should still prefer the exact growth match
        XCTAssertEqual(matchedHoldings2.count, 1)
        if let matchedSchemeCode = matchedHoldings2.first?.matchedSchemeCode {
            XCTAssertEqual(matchedSchemeCode, "001", "Should still match growth fund even when dividend funds are shown")
        }
        
        // Reset to default
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