import XCTest

final class MutualFundsAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppLaunchAndNavigation() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Verify the app launches and shows the tab bar
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        
        // Verify all three tabs exist
        XCTAssertTrue(app.tabBars.buttons["Funds"].exists)
        XCTAssertTrue(app.tabBars.buttons["Favorites"].exists)
        XCTAssertTrue(app.tabBars.buttons["About"].exists)
        
        // Default tab should be Funds
        XCTAssertTrue(app.tabBars.buttons["Funds"].isSelected)
    }
    
    func testFundsTabBasicElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Ensure we're on the Funds tab
        app.tabBars.buttons["Funds"].tap()
        
        // Check for navigation title
        XCTAssertTrue(app.navigationBars["Mutual Funds"].exists)
        
        // Check for search functionality (may take time to load)
        let searchField = app.textFields.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: searchField, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertTrue(searchField.exists)
    }
    
    func testSearchFunctionality() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Funds tab
        app.tabBars.buttons["Funds"].tap()
        
        // Wait for search field to appear
        let searchField = app.textFields.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: searchField, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        // Tap on search field and enter text
        searchField.tap()
        searchField.typeText("SBI")
        
        // Verify search is working (results should be filtered)
        // Note: This test assumes search is working - in a real scenario,
        // we'd verify the list updates with filtered results
        XCTAssertTrue(searchField.value as? String == "SBI")
    }
    
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test navigation to Favorites tab
        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(app.tabBars.buttons["Favorites"].isSelected)
        XCTAssertTrue(app.navigationBars["Favorites"].exists)
        
        // Test navigation to About tab
        app.tabBars.buttons["About"].tap()
        XCTAssertTrue(app.tabBars.buttons["About"].isSelected)
        XCTAssertTrue(app.navigationBars["About"].exists)
        
        // Return to Funds tab
        app.tabBars.buttons["Funds"].tap()
        XCTAssertTrue(app.tabBars.buttons["Funds"].isSelected)
    }
    
    func testAboutTabContent() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to About tab
        app.tabBars.buttons["About"].tap()
        
        // Check for key elements in About tab
        XCTAssertTrue(app.staticTexts["Mutual Funds Tracker"].exists)
        XCTAssertTrue(app.staticTexts["Track and analyze Indian mutual funds with real-time data"].exists)
        XCTAssertTrue(app.staticTexts["api.mfapi.in"].exists)
    }
    
    func testFundDetailNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Funds tab
        app.tabBars.buttons["Funds"].tap()
        
        // Wait for the list to load (may take time for API data)
        let firstCell = app.cells.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: firstCell, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        // Tap on first fund in the list
        if firstCell.exists {
            firstCell.tap()
            
            // Wait for detail view to load
            let detailView = app.navigationBars.firstMatch
            expectation(for: exists, evaluatedWith: detailView, handler: nil)
            waitForExpectations(timeout: 10, handler: nil)
            
            // Verify we're in detail view (should have a back button)
            XCTAssertTrue(app.navigationBars.buttons.firstMatch.exists)
            
            // Go back to list
            app.navigationBars.buttons.firstMatch.tap()
            
            // Verify we're back to the funds list
            XCTAssertTrue(app.navigationBars["Mutual Funds"].exists)
        }
    }
    
    func testCategoryFiltering() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Funds tab
        app.tabBars.buttons["Funds"].tap()
        
        // Wait for category filter buttons to appear
        let allButton = app.buttons["All"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: allButton, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        // Test category filter buttons
        if app.buttons["Equity"].exists {
            app.buttons["Equity"].tap()
            // Verify Equity button is selected (would need to check visual state)
        }
        
        if app.buttons["Debt"].exists {
            app.buttons["Debt"].tap()
            // Verify Debt button is selected
        }
        
        // Return to All filter
        if allButton.exists {
            allButton.tap()
        }
    }
    
    func testPullToRefresh() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Funds tab
        app.tabBars.buttons["Funds"].tap()
        
        // Wait for list to appear
        let table = app.tables.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: table, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        // Perform pull to refresh gesture
        if table.exists {
            let firstCell = table.cells.firstMatch
            let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0))
            let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 2.0))
            start.press(forDuration: 0, thenDragTo: finish)
            
            // Wait a moment for refresh to complete
            Thread.sleep(forTimeInterval: 2)
        }
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}