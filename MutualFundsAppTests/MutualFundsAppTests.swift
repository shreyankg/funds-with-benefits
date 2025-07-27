import XCTest
@testable import MutualFundsApp

final class MutualFundsAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
}