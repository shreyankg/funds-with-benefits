# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Funds with Benefits (FWB) is a SwiftUI iOS application for tracking and analyzing Indian mutual funds. For detailed architecture and project structure, see DEVELOPER_DOCS.md.

## Build and Development Commands

### Building
- **Build in Xcode**: `⌘+B` or Product → Build
- **Run in Simulator**: `⌘+R` or Product → Run  
- **Clean Build**: `⌘+Shift+K` or Product → Clean Build Folder

### Testing

#### **Efficient Test Debugging Strategy**
**CRITICAL**: Focus on ONE test type at a time for debugging. Avoid running all tests repeatedly without code changes.

#### **Unit Tests (Recommended for debugging)**
```bash
# Unit tests with timeout and detailed output capture
timeout 180 xcodebuild test -scheme MutualFundsApp \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:MutualFundsAppTests 2>&1 | tee test_output.log

# Extract failures and key info in one pass
grep -E "(FAIL|PASS|Test Suite|Test Case|Assertion Failure|XCTAssert)" test_output.log
```

#### **UI Tests (Only when unit tests pass)**
```bash
# UI tests with timeout and output capture
timeout 180 xcodebuild test -scheme MutualFundsApp \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:MutualFundsAppUITests 2>&1 | tee ui_test_output.log

# Extract UI test results
grep -E "(FAIL|PASS|Test Suite|Test Case|UI Testing|Element)" ui_test_output.log
```

#### **All Tests (Only for final verification)**
```bash
# Complete test suite with comprehensive logging
timeout 180 xcodebuild test -scheme MutualFundsApp \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' 2>&1 | tee full_test_output.log

# Quick summary of results
grep -E "(Test Suite.*started|Test Suite.*passed|Test Suite.*failed|FAIL|Test Case.*passed|Test Case.*failed)" full_test_output.log
```

#### **Current Status**: ✅ All tests passing (38 unit tests, 14 UI tests)

## Claude Code Specific Guidelines

### Code Quality Requirements
- Always test API integration changes with real endpoints
- Maintain cache performance when modifying data models
- Ensure chart interactions remain responsive
- Follow existing error handling patterns throughout the app
- Consider offline functionality when making network-related changes
- **CRITICAL**: Always run full test suite after changes - all tests must pass before considering work complete

### When Making Changes
- Use existing patterns in the codebase (MVVM, SwiftUI best practices)
- Always run tests after changes: `⌘+U` in Xcode
- Follow the project's error handling conventions
- Maintain performance optimizations for charts and API calls

## Common Development Workflows

### Adding New Features
1. Create new SwiftUI views in appropriate `Views/` subdirectory
2. Follow existing ViewModel patterns for data management
3. Add to main navigation in `ContentView.swift`
4. Update Xcode project references and run tests

### API-Related Changes
1. Modify `APIService.swift` for new endpoints
2. Update data models with proper Codable implementations
3. Test caching behavior in `DataCache.swift`
4. Verify offline functionality still works

### Fund Matching Changes
1. Modify matching logic in `FundMatcher.swift`
2. Test with various fund name formats and AMC variations
3. Ensure dividend filtering integration works correctly
4. Run performance tests with large datasets

### Portfolio/Holdings Changes
1. Update models in `HoldingData.swift` or `Portfolio.swift`
2. Modify parsing logic in `HoldingsParser.swift` if needed
3. Test CSV export functionality in `HoldingsManager.swift`
4. Verify analytics calculations remain accurate

## Quick Reference

### Key API Endpoints
- **Base URL**: `https://api.mfapi.in/mf`
- `GET /mf` - All mutual funds list
- `GET /mf/{schemeCode}` - Individual fund history

### Important Files to Know
- `APIService.swift` - All API integration logic and AppSettings
- `DataCache.swift` - Caching system
- `MutualFund.swift` - Core data model
- `HoldingData.swift` - Portfolio holdings data model
- `FundMatcher.swift` - Fund matching algorithm with dividend filtering
- `HoldingsManager.swift` - Portfolio management (MainActor)
- `ContentView.swift` - Main app navigation
- `DEVELOPER_DOCS.md` - Complete technical documentation

### Testing Commands (Legacy - Use Testing section above for debugging)
```bash
# Run specific test (useful for isolated debugging)
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:MutualFundsAppTests/testFundMatcherExactMatch

# Run specific test class
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:FundMatcherTests
```

## Testing Best Practices & Known Issues

### **CRITICAL: Avoid Test Dependencies and Concurrency Issues**

#### **When Writing/Updating Tests**
1. **Test Isolation**: Each test MUST be completely independent
   ```swift
   // ❌ BAD - Relies on shared state
   class MyTests: XCTestCase {
       static var sharedData: [String] = []
       
       func testFirst() {
           MyTests.sharedData.append("test1")
           XCTAssertEqual(MyTests.sharedData.count, 1)
       }
   }
   
   // ✅ GOOD - Self-contained
   class MyTests: XCTestCase {
       func testFirst() {
           let localData = ["test1"]
           XCTAssertEqual(localData.count, 1)
       }
   }
   ```

2. **Avoid Shared Singletons**: Reset or mock singleton state in setUp/tearDown
   ```swift
   override func setUp() {
       super.setUp()
       // Reset any singleton state
       DataCache.shared.clearAll()
       FundMatcher.shared.clearCache()
   }
   ```

3. **Async Test Patterns**: Use proper async/await patterns for MainActor classes
   ```swift
   // ✅ GOOD - Proper async testing
   func testAsyncFunction() async throws {
       let expectation = XCTestExpectation(description: "Async operation")
       
       Task {
           await MainActor.run {
               // Perform test operations
               let result = await myAsyncFunction()
               XCTAssertNotNil(result)
           }
           expectation.fulfill()
       }
       
       await fulfillment(of: [expectation], timeout: 5.0)
   }
   ```

4. **Race Condition Prevention**: Extract property access before assertions
   ```swift
   // ❌ BAD - Can cause race conditions
   XCTAssertEqual(matchedHoldings.count, 1)
   
   // ✅ GOOD - Extract to local variable first
   let holdingsCount = matchedHoldings.count
   XCTAssertEqual(holdingsCount, 1)
   ```

#### **Test Debugging Rules**
- **Never run the same test multiple times** without changing code
- **Always capture full output** with `tee` commands above
- **Use focused test runs** (unit tests only) for faster feedback
- **Fix one test at a time** before moving to others

### Test Race Conditions (RESOLVED)
If you encounter tests that pass individually but fail when run in parallel, this indicates a race condition or shared state issue. The FundMatcher tests previously had this issue.

**Solution Pattern**: Extract property access to explicit variables before assertions:
```swift
// ❌ Problematic (can cause race conditions):
XCTAssertEqual(matchedHoldings.count, 1)

// ✅ Correct (prevents race conditions):
let holdingsCount = matchedHoldings.count
XCTAssertEqual(holdingsCount, 1)
```

### MainActor Async Testing
For tests involving `HoldingsManager` or other `@MainActor` classes, use proper async patterns:
```swift
let expectation = XCTestExpectation(description: "Async operation")
Task {
    await holdingsManager.someAsyncOperation()
    await MainActor.run {
        // Perform assertions here
        XCTAssertEqual(holdingsManager.someProperty, expectedValue)
    }
    expectation.fulfill()
}
wait(for: [expectation], timeout: 5.0)
```

## Quick Troubleshooting

### Test Failures
- **Individual tests pass, parallel tests fail**: Race condition - extract property access to variables
- **MainActor warnings**: Use `await MainActor.run` or `@MainActor` annotation
- **Async test timeouts**: Increase timeout values, ensure proper expectation handling
- **Build failures**: Clean build folder (`⌘+Shift+K`), check for missing imports

### Performance Issues
- **Slow fund matching**: Check `FundMatcher.swift` preprocessing cache
- **UI lag**: Verify SwiftUI view updates are on main thread
- **Memory leaks**: Look for retain cycles in Combine subscriptions

### API Issues
- **Network failures**: Check `APIService.swift` error handling
- **JSON parsing errors**: Verify `Codable` implementations handle API variations
- **Cache problems**: Clear DataCache, check expiration logic

## API Exploration Best Practices

### Before Making API Changes

**CRITICAL**: The best way to explore and understand API structure is to download the API data locally first, then explore it instead of making multiple API calls during development.

#### Recommended Workflow:
1. **Check for existing local API data** (e.g., `mutual_funds_api_data.json` in project root)
2. **Download API data locally** if not available:
   ```bash
   # Download complete fund list for exploration
   curl https://api.mfapi.in/mf > mutual_funds_api_data.json
   
   # Download individual fund data for testing
   curl https://api.mfapi.in/mf/119551 > sample_fund_data.json
   ```
3. **Explore the JSON structure** using local files
4. **Plan your changes** based on actual data structure
5. **Only then make API integration changes**

### Current API Limitations & First-Word Matching Optimization

#### Why First-Word Extraction Exists
The `fundHouse` property in `MutualFund.swift` extracts the first word from scheme names. **This is NOT true AMC parsing** - it's a simple matching optimization technique that serves **one primary purpose**:

1. **Portfolio Matching Performance** (Only Purpose): 
   - Reduces search space by 90% in `FundMatcher.swift`
   - Provides 20-50x performance improvement
   - Creates rough groupings for faster fund matching

**Important**: The first word is often not the actual AMC name, making this technique useful only for performance optimization, not for accurate AMC identification.

#### Current API Structure
The `https://api.mfapi.in/mf` API provides minimal fields:
```json
{
  "schemeCode": "119551",
  "schemeName": "Aditya Birla Sun Life Frontline Equity Fund - Growth - Direct Plan",
  "isinGrowth": "INF209K01LX6",
  "isinDivReinvestment": null
}
```

**No dedicated AMC/fund house field** is provided. The current first-word extraction is a performance optimization, not true AMC parsing.

#### Alternative API Research
- Most free Indian mutual fund APIs have similar limitations
- No widely available API provides structured AMC data
- Current first-word matching approach is optimal for performance, not accuracy

### When Exploring APIs
- **Always download sample data locally first**
- **Avoid making repeated API calls during development**
- **Cache API responses** for consistent testing
- **Document API limitations** you discover

---

**Note**: This file provides Claude Code-specific guidance. For complete technical documentation, architecture details, and development workflows, refer to `DEVELOPER_DOCS.md`.