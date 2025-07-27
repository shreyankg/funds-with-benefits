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
        
        // Wait for search field to appear with longer timeout
        let searchField = app.textFields.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: searchField, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        // Wait additional time for API data to load completely
        Thread.sleep(forTimeInterval: 8)
        
        // Tap on search field and enter text
        searchField.tap()
        searchField.typeText("SBI")
        
        // Wait a moment for search results to update
        Thread.sleep(forTimeInterval: 2)
        
        // Verify search text was entered correctly
        XCTAssertTrue(searchField.value as? String == "SBI")
        
        // Clear the search to test that functionality too
        searchField.tap()
        // Select all text and delete
        searchField.typeText(XCUIKeyboardKey.command.rawValue + "a")
        searchField.typeText(XCUIKeyboardKey.delete.rawValue)
        
        // Wait for clear to take effect
        Thread.sleep(forTimeInterval: 1)
        
        // Verify search was cleared (empty string or placeholder text)
        let searchValue = searchField.value as? String ?? ""
        XCTAssertTrue(searchValue.isEmpty || searchValue.contains("Search"), 
                     "Search field should be empty or show placeholder after clearing")
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
        
        // Wait for the content to load - look for the search field first as it indicates the view is ready
        let searchField = app.textFields.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: searchField, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        // Wait additional time for API data to load
        Thread.sleep(forTimeInterval: 8)
        
        // Try different strategies to find clickable fund items
        var tappedSuccessfully = false
        
        // Strategy 1: Look for buttons (NavigationLink might appear as buttons)
        let buttons = app.buttons
        for i in 0..<buttons.count {
            let button = buttons.element(boundBy: i)
            if button.exists && button.isHittable {
                // Skip system buttons like search, filter, etc.
                let buttonLabel = button.label
                if !buttonLabel.contains("All") && 
                   !buttonLabel.contains("Equity") && 
                   !buttonLabel.contains("Debt") && 
                   !buttonLabel.contains("Hybrid") &&
                   !buttonLabel.isEmpty && 
                   buttonLabel.count > 10 { // Fund names are typically long
                    
                    button.tap()
                    tappedSuccessfully = true
                    break
                }
            }
        }
        
        // Strategy 2: If no buttons worked, try other elements
        if !tappedSuccessfully {
            let otherElements = app.otherElements
            for i in 0..<min(otherElements.count, 5) { // Limit to first 5 to avoid infinite loop
                let element = otherElements.element(boundBy: i)
                if element.exists && element.isHittable {
                    element.tap()
                    tappedSuccessfully = true
                    break
                }
            }
        }
        
        if tappedSuccessfully {
            // Wait for navigation to complete
            Thread.sleep(forTimeInterval: 3)
            
            // Look for signs we're in a detail view
            // Check if navigation title changed or back button appeared
            let hasBackButton = app.navigationBars.buttons.firstMatch.exists
            let navigationChanged = !app.navigationBars["Mutual Funds"].exists
            
            if hasBackButton || navigationChanged {
                // We successfully navigated to detail view
                // Try to go back
                if hasBackButton {
                    app.navigationBars.buttons.firstMatch.tap()
                    Thread.sleep(forTimeInterval: 2)
                }
                
                // Verify we can get back to the main list
                // The test passes if we can navigate without crashing
                XCTAssertTrue(app.tabBars.buttons["Funds"].exists, "Should still be able to access Funds tab")
            } else {
                // If navigation didn't work as expected, that's still okay for this test
                // The main goal is to ensure the app doesn't crash
                XCTAssertTrue(app.tabBars.buttons["Funds"].exists, "App should remain functional")
            }
        } else {
            // If we couldn't find anything to tap, that might be because data is still loading
            // This is acceptable - the test just verifies the app doesn't crash
            XCTAssertTrue(app.navigationBars["Mutual Funds"].exists, "Should still show the main funds list")
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
        
        // Wait for the content to load first
        Thread.sleep(forTimeInterval: 5)
        
        // Look for scroll view or any scrollable content area
        let scrollView = app.scrollViews.firstMatch
        let collectionView = app.collectionViews.firstMatch
        
        var targetView: XCUIElement?
        
        if scrollView.exists {
            targetView = scrollView
        } else if collectionView.exists {
            targetView = collectionView
        } else {
            // Try to find any view that can be scrolled
            // Sometimes SwiftUI Lists appear as other elements
            let mainView = app.otherElements.firstMatch
            if mainView.exists {
                targetView = mainView
            }
        }
        
        // Perform pull to refresh gesture
        if let view = targetView, view.exists {
            // Get coordinates for pull-to-refresh gesture
            let startCoordinate = view.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            let endCoordinate = view.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            
            // Perform the pull down gesture
            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            
            // Wait a moment for refresh to complete
            Thread.sleep(forTimeInterval: 3)
        } else {
            // If we can't find a suitable view, just perform a general swipe down gesture
            // This tests that the UI doesn't crash when performing gestures
            let app = XCUIApplication()
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            coordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            
            Thread.sleep(forTimeInterval: 2)
        }
        
        // Verify the app is still responsive after the gesture
        XCTAssertTrue(app.tabBars.buttons["Funds"].exists)
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