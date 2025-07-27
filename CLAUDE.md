# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Mutual Funds App is a SwiftUI iOS application for tracking and analyzing Indian mutual funds. The app provides real-time data from the MF API (api.mfapi.in), interactive performance charts, comprehensive search functionality, and detailed fund analysis tools.

## Build and Development Commands

### Building
- **Build in Xcode**: `⌘+B` or Product → Build
- **Run in Simulator**: `⌘+R` or Product → Run  
- **Clean Build**: `⌘+Shift+K` or Product → Clean Build Folder

### Testing
- **Run All Tests**: `⌘+U` in Xcode or `xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'`
- **Unit Tests**: MutualFundsAppTests target (15+ tests) - Models, data parsing, performance calculations, caching
- **UI Tests**: MutualFundsAppUITests target (8 tests) - Navigation, search functionality, user interactions
- **Test Coverage**: Core functionality, API integration, data models, UI workflows

### Requirements
- iOS 17.0+ deployment target
- Xcode 15.0+
- Swift 5.9+
- Charts framework (native iOS)

## Architecture Overview

### Technology Stack
- **UI**: SwiftUI with MVVM pattern
- **Charts**: Native Swift Charts framework
- **Networking**: URLSession with async/await concurrency
- **Caching**: UserDefaults-based with structured data storage
- **Data Source**: MF API (api.mfapi.in) for Indian mutual funds

### Project Structure
```
MutualFundsApp/
├── MutualFundsApp.swift          # App entry point
├── ContentView.swift             # Main tab navigation
├── Models/                       # Data models and business logic
│   ├── MutualFund.swift         # Core fund model with computed properties
│   ├── NAVData.swift            # Historical NAV data with date parsing
│   └── FundDetails.swift        # Fund analysis and performance calculations
├── Views/                       # SwiftUI view components
│   ├── FundsListView.swift      # Main listing with search and filters
│   └── FundDetailView.swift     # Individual fund analysis and charts
├── Services/                    # External services and data management
│   ├── APIService.swift         # API integration with caching
│   └── DataCache.swift          # Offline functionality and performance
└── Extensions/                  # Utility extensions
    ├── Date+Extensions.swift    # Date formatting and calculations
    └── Double+Extensions.swift  # Number formatting for currency/percentages
```

## Key Implementation Details

### API Integration
**Base URL**: `https://api.mfapi.in/mf`

**Endpoints**:
- `GET /mf` - All mutual funds list
- `GET /mf/{schemeCode}` - Individual fund history

**Caching Strategy**:
- Fund list: 1 hour expiration
- Fund history: 30 minutes expiration
- Storage: UserDefaults with automatic cleanup

### Data Models

#### MutualFund
Core model representing individual mutual fund schemes with computed properties for:
- Fund house extraction from scheme name
- Category classification (Equity/Debt/Hybrid/Other)
- Plan type detection (Growth/Dividend)

#### NAVData
Historical Net Asset Value data with date parsing and formatting utilities.

#### FundDetails
Comprehensive fund analysis combining base fund data with:
- Performance calculations (returns, CAGR, volatility)
- Daily change calculations
- Time-period specific data filtering

### UI Architecture

#### Tab Structure
- **Funds Tab**: Main fund listing with search and filtering
- **Favorites Tab**: Placeholder for future favorites functionality  
- **About Tab**: App information and feature overview

#### Key Views
- **FundsListView**: Search, filter, and browse all funds
- **FundDetailView**: Interactive charts and detailed analysis
- **PerformanceChartView**: Swift Charts integration with time period selection

### Search and Filtering
- **Real-time Search**: Across fund name, scheme code, and fund house
- **Category Filters**: Equity, Debt, Hybrid, Other classifications
- **Debounced Input**: Optimized search performance
- **Pull-to-Refresh**: Manual data refresh capability

### Performance Features
- **Interactive Charts**: Using native Swift Charts framework
- **Time Periods**: 1W, 1M, 6M, 1Y, 3Y selections
- **Metrics Calculation**: Total returns, CAGR, volatility analysis
- **Real-time Updates**: Daily NAV changes and performance indicators

## Development Guidelines

### Code Patterns
- **MVVM Architecture**: Clear separation between Views, ViewModels, and Models
- **SwiftUI Best Practices**: Proper state management with @StateObject, @Published
- **Async/Await**: Modern concurrency for API calls
- **Error Handling**: Comprehensive error states with user-friendly messages

### Data Safety
- All API responses parsed with optional handling
- Date parsing with fallback mechanisms
- Number formatting with proper decimal precision
- Cache invalidation and cleanup procedures

### Performance Optimization
- **Lazy Loading**: Fund details loaded on-demand
- **Efficient Caching**: Structured cache with expiration management
- **Memory Management**: Proper object lifecycle and state cleanup
- **Chart Performance**: Data sampling for large datasets

## Common Development Tasks

### Adding New Metrics
1. Extend `FundPerformance` struct in `FundDetails.swift`
2. Implement calculation logic in `FundDetails.performanceForPeriod()`
3. Update `PerformanceMetricsView` to display new metrics
4. Add formatting extensions in `Double+Extensions.swift`

### Modifying API Integration
1. Update endpoint definitions in `APIService.swift`
2. Modify data models in `Models/` directory
3. Update caching logic in `DataCache.swift`
4. Test with different API responses

### Enhancing Search Functionality
1. Modify filtering logic in `FundsViewModel.filterFunds()`
2. Add new search criteria to `MutualFund` computed properties
3. Update UI in `SearchBar` and `CategoryFilterView`
4. Test search performance with large datasets

### Chart Customization
1. Modify `PerformanceChartView` for new chart types
2. Update time period logic in `FundDetailViewModel`
3. Add new chart interactions and formatting
4. Test across different screen sizes

### Adding New Views
1. Create SwiftUI view in `Views/` directory
2. Add to navigation structure in `ContentView.swift`
3. Create corresponding ViewModel if needed
4. Update Xcode project references

## API Data Structure

### Fund List Response
```json
[
  {
    "schemeCode": "101206",
    "schemeName": "SBI Overnight Fund - Regular Plan - Growth", 
    "isinGrowth": "INF200K01LQ9",
    "isinDivReinvestment": null
  }
]
```

### Fund History Response
```json
{
  "meta": {
    "fund_house": "SBI Mutual Fund",
    "scheme_type": "Open Ended Schemes",
    "scheme_category": "Debt Scheme - Overnight Fund",
    "scheme_code": "101206",
    "scheme_name": "SBI Overnight Fund - Regular Plan - Growth"
  },
  "data": [
    {
      "date": "27-01-2025",
      "nav": "1054.5678"
    }
  ]
}
```

## Error Handling Strategy

### Network Errors
- Connection timeouts with retry mechanisms
- Invalid URL handling with fallback options
- HTTP error status code management
- JSON parsing error recovery

### User Experience
- Loading states for all async operations
- Error messages with actionable retry options
- Offline mode with cached data access
- Empty states for no data scenarios

## Testing Strategy

### Unit Testing Focus
- Data model parsing and calculations
- Performance metric calculations
- Date and number formatting utilities
- Cache management functionality

### Integration Testing
- API service integration with real endpoints
- Cache storage and retrieval mechanisms
- View model state management
- Navigation flow testing

### Manual Testing Checklist
- [ ] Fund list loads and displays correctly
- [ ] Search functionality works across all criteria
- [ ] Fund details load with proper error handling
- [ ] Charts render correctly for all time periods
- [ ] Performance metrics calculate accurately
- [ ] Offline mode works with cached data
- [ ] App handles network errors gracefully

## Future Enhancement Guidelines

### Favorites System Implementation
1. Create `FavoritesManager` service class
2. Add Core Data model for persistent storage
3. Update `MutualFund` model with favorite status
4. Implement favorites UI in dedicated tab

### Portfolio Tracking Addition
1. Create `Portfolio` and `Holding` data models
2. Add investment tracking API integration
3. Implement portfolio performance calculations
4. Design portfolio overview and detail views

### Notification System
1. Add UserNotifications framework
2. Create notification service for price alerts
3. Implement background data refresh
4. Add notification preferences UI

## Development Best Practices

### Performance Guidelines
- Use lazy loading for expensive operations
- Implement proper caching with expiration
- Monitor memory usage during development
- Optimize chart rendering for large datasets

### Code Quality
- Follow Swift API Design Guidelines
- Use comprehensive error handling
- Write descriptive variable and function names
- Add inline documentation for complex logic

### User Experience
- Provide immediate feedback for user actions
- Implement proper loading and error states
- Ensure accessibility compliance
- Test on various screen sizes and orientations

## Troubleshooting Common Issues

### API Integration Problems
- Verify internet connectivity before API calls
- Check API endpoint availability and response format
- Validate JSON parsing with updated models
- Clear cache if data appears stale

### Performance Issues
- Monitor memory usage with Instruments
- Check for retain cycles in ViewModels
- Optimize heavy calculations on background threads
- Review chart rendering performance

### UI Rendering Problems
- Test SwiftUI previews for layout issues
- Verify iOS version compatibility
- Check for state management problems
- Test on different device screen sizes

---

**Important Notes for Claude Code:**
- Always test API integration changes with real endpoints
- Maintain cache performance when modifying data models
- Ensure chart interactions remain responsive
- Follow existing error handling patterns throughout the app
- Consider offline functionality when making network-related changes

**Last Updated**: January 2025  
**App Version**: 1.0.0  
**Minimum iOS**: 17.0