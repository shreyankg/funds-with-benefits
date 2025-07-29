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
- **Run All Tests**: `⌘+U` in Xcode or `xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'`
- **Run Unit Tests Only**: `xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:MutualFundsAppTests`
- **Current Status**: ✅ All tests passing (38 unit tests, 14 UI tests)

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

### Testing Commands
```bash
# Run all tests
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'

# Run only unit tests
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:MutualFundsAppTests

# Run specific test
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:MutualFundsAppTests/testFundMatcherExactMatch
```

## Testing Best Practices & Known Issues

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

---

**Note**: This file provides Claude Code-specific guidance. For complete technical documentation, architecture details, and development workflows, refer to `DEVELOPER_DOCS.md`.