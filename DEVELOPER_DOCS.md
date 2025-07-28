# Funds with Benefits (FWB) - Developer Documentation

## Project Overview

Funds with Benefits (FWB) is an iOS application for tracking and analyzing Indian mutual funds using real-time data from the MF API (api.mfapi.in). Built with SwiftUI and MVVM architecture.

### Key Features
- Real-time mutual fund data with interactive charts
- Advanced search and filtering capabilities
- Holdings management with PDF import capability
- Offline functionality through intelligent caching

## Architecture & Tech Stack

- **UI Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with Combine
- **Charts**: Swift Charts framework
- **Networking**: URLSession with async/await
- **Data Persistence**: UserDefaults for caching

## Project Structure

```
FundsWithBenefitsApp/
├── MutualFundsApp.swift          # App entry point (FundsWithBenefitsApp)
├── ContentView.swift             # Main tab navigation
├── Models/                       # Data models
│   ├── MutualFund.swift         # Core fund model
│   ├── NAVData.swift            # Historical NAV data
│   ├── FundDetails.swift        # Fund details and metrics
│   ├── HoldingData.swift        # Holdings data model
│   └── Portfolio.swift          # Portfolio management
├── Views/                       # SwiftUI views
│   ├── SplashScreenView.swift   # App launch splash
│   ├── FundsListView.swift      # Main fund listing
│   ├── FundDetailView.swift     # Individual fund analysis
│   └── Holdings/                # Portfolio holdings views
├── Services/                    # External services
│   ├── APIService.swift         # API communication
│   ├── DataCache.swift          # Caching system
│   ├── HoldingsParser.swift     # PDF statement parsing
│   ├── HoldingsManager.swift    # Holdings data management
│   └── FundMatcher.swift        # Fund matching service
└── Extensions/                  # Utilities
    ├── Date+Extensions.swift
    └── Double+Extensions.swift
```

## API Integration

### Base API: `https://api.mfapi.in/mf`

**Endpoints:**
- `GET /mf` - All mutual funds list
- `GET /mf/{schemeCode}` - Individual fund history

**Caching Strategy:**
- Fund list: 1 hour expiration
- Fund history: 30 minutes expiration
- Storage: UserDefaults with structured data

### JSON Parsing Features
- Flexible scheme_code parsing (handles both integer and string values)
- Custom Codable implementations for API format variations
- Backward compatibility with legacy API responses

## Core Data Models

### MutualFund
```swift
struct MutualFund: Codable, Identifiable, Hashable {
    let schemeCode: String
    let schemeName: String
    let isinGrowth: String?
    let isinDivReinvestment: String?
    
    // Computed properties for fund house, category, plan type
}
```

### HoldingData & Portfolio
```swift
struct HoldingData: Codable, Identifiable {
    let schemeName: String
    let amcName: String
    let category: String
    let units: Double
    let investedValue: Double
    let currentValue: Double
    let returns: Double
    let xirr: Double
    var matchedSchemeCode: String?
}

struct Portfolio {
    let holdings: [HoldingData]
    let summary: PortfolioSummary
    let lastUpdated: Date
}
```

## Development Commands

### Building & Testing
```bash
# Build in Xcode: ⌘+B
# Run in Simulator: ⌘+R
# Run All Tests: ⌘+U

# Command line testing
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

### Test Coverage
**Unit Tests (21 tests)**: Models, API integration, data parsing, performance calculations, holdings functionality
**UI Tests (9 tests)**: Navigation, search, user interactions, holdings interface

## Key Implementation Details

### Fund Matching Algorithm
The app uses a sophisticated multi-factor matching system in `FundMatcher.swift` to match portfolio holdings with API fund data:

**Scoring Components:**
- **AMC/Fund House matching**: 25% weight
- **Fund name similarity**: 45% weight (using Levenshtein distance, core name extraction, financial terms recognition)
- **Plan type matching**: 20% weight (Direct vs Regular, Growth vs Dividend/IDCW)
- **Category matching**: 10% weight (Equity, Debt, Hybrid)

**Bonus System:**
- **Direct plans**: +5% bonus (lower expense ratios)
- **Growth plans**: +5% bonus (more common than dividend/IDCW)
- **Combined Direct Growth**: +10% total bonus

**Matching Process:**
1. Normalize fund names (remove dashes, standardize terms)
2. Extract core fund names (remove plan suffixes)
3. Calculate multi-factor similarity scores
4. Apply plan type and category bonuses
5. Select best match above 70% threshold

### Performance Optimization
- Lazy loading of fund details
- Efficient caching with automatic expiration
- Debounced search to minimize API calls
- Chart performance optimization for large datasets
- Portfolio refresh uses cached data instead of API re-fetching

### Error Handling
- Comprehensive network error handling
- JSON parsing error recovery with fallback mechanisms
- Graceful handling of API format variations
- Fund matching fallback for unmatched holdings

### Testing Strategy
- Extensive unit test coverage for models and services
- UI test automation for critical user workflows
- Integration tests for API and cache management
- Manual testing checklist for release validation

## Common Development Tasks

### Adding New Metrics
1. Extend `FundPerformance` struct in `FundDetails.swift`
2. Implement calculation logic in performance methods
3. Update UI components to display new metrics
4. Add formatting extensions in `Double+Extensions.swift`

### Modifying Holdings System
1. Update data models in `Models/` directory
2. Modify parsing logic in `HoldingsParser.swift`
3. Update matching algorithms in `FundMatcher.swift`
4. Test with different statement formats

### API Integration Changes
1. Update endpoint definitions in `APIService.swift`
2. Modify data models with custom Codable implementations
3. Update caching logic in `DataCache.swift`
4. Test with different API response formats

## Troubleshooting

### Common Issues
1. **Network Errors**: Check connectivity, verify API endpoints, clear cache
2. **JSON Parsing**: Check for API format changes, verify custom Codable implementations
3. **UI Test Flakiness**: Ensure adequate wait times, use multiple element detection strategies
4. **Performance**: Monitor memory usage, check for retain cycles, optimize computations

### Debug Tools
- Xcode Instruments for performance profiling
- Network debugging for API issues
- Memory profiling for optimization

## TEMPORARY: Next Priority Items & Performance Optimization Plan

### IMMEDIATE PRIORITY: Fix Failing Tests
Before implementing any performance optimizations, these failing tests need to be addressed:

**UI Tests:**
- `MutualFundsAppUITests.testPortfolioTabWithMockData()` - Portfolio tab UI testing with mock data
- `MutualFundsAppUITests.testTabNavigation()` - Tab navigation functionality

**Unit Tests:**
- `MutualFundsAppTests.testHoldingsManagerPortfolioStorage()` - Portfolio storage functionality
- `MutualFundsAppTests.testHoldingsManagerCSVExport()` - CSV export functionality  
- `MutualFundsAppTests.testHoldingsManagerAnalytics()` - Portfolio analytics calculations

These test failures likely relate to the recent changes in background refresh logic and loading states. Must be fixed before proceeding with performance work.

### Portfolio Refresh Performance Optimization Plan

#### Current Performance Bottlenecks
1. **Fund Matching Algorithm - O(n×m) Complexity**: For each holding (n), iterate through all funds (m ≈ 3000-5000+ schemes)
2. **String Processing Overhead**: Multiple expensive operations per comparison (normalization, Levenshtein distance, regex)
3. **Redundant Computations**: Same fund names normalized repeatedly, no memoization
4. **API Data Volume**: Large datasets with no early termination or indexing

#### Optimization Plan

**Phase 1 (Immediate Impact - 70-80% performance gain):**
- **Fund Data Preprocessing**: Cache normalized names, create lookup indices by AMC/category
- **Smart Matching**: AMC-first filtering (reduces search space by ~90%), early termination for exact matches
- **Basic Memoization**: Cache normalized strings and similarity scores
- **Tiered Approach**: Fast filters before expensive similarity calculations

**Phase 2 (Fine-tuning - Additional 10-15% gain):**
- **Parallel Processing**: Concurrent queues for independent holding matches
- **Advanced Caching**: Persistent matching cache between app sessions
- **Progressive UI**: Stream results as matches are found, chunked processing
- **Optimized Algorithms**: Early termination Levenshtein, score thresholding

#### Expected Results
- **Current**: O(n × m × k) where n=holdings, m=funds (~5000), k=string processing cost
- **Optimized**: O(n × (m/10) × k/5) with caching and indexing
- **Estimated speedup**: 20-50x faster (refresh time: 5-15s → <1s)

---

**Version**: 0.0.1 (FWB Branding Update)  
**iOS Target**: 17.0+  
**Last Updated**: July 2025