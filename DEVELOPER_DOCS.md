# Funds with Benefits (FWB) - Developer Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Development Setup](#development-setup)
5. [API Integration](#api-integration)
6. [Data Models](#data-models)
7. [UI Components](#ui-components)
8. [Performance Optimization](#performance-optimization)
9. [Testing Strategy](#testing-strategy)
10. [Deployment](#deployment)
11. [Future Enhancements](#future-enhancements)

## Project Overview

Funds with Benefits (FWB) is a comprehensive iOS application for tracking and analyzing Indian mutual funds using real-time data from the MF API (api.mfapi.in). Built with SwiftUI and modern iOS development practices, it empowers investors with intelligent insights and benefits through powerful fund analysis and performance tracking tools.

### Key Features
- Real-time mutual fund data from Indian markets
- Interactive performance charts with multiple timeframes
- Advanced search and filtering capabilities
- Comprehensive fund analysis with performance metrics
- Offline functionality through intelligent caching
- Modern SwiftUI interface with responsive design

## Architecture

### Design Pattern: MVVM (Model-View-ViewModel)
The app follows the MVVM architecture pattern to ensure clean separation of concerns and maintainable code.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │    │   ViewModel     │    │     Model       │
│   (SwiftUI)     │◄──►│  (Observable)   │◄──►│  (Data Layer)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack
- **UI Framework**: SwiftUI (iOS 17+)
- **Charts**: Swift Charts framework
- **Networking**: URLSession with async/await
- **Data Persistence**: UserDefaults for caching
- **Architecture**: MVVM with Combine for reactive programming
- **Deployment Target**: iOS 17.0+

## Project Structure

```
FundsWithBenefitsApp/
├── MutualFundsApp.swift          # App entry point (FundsWithBenefitsApp struct)
├── ContentView.swift             # Main tab view controller
├── Models/                       # Data models and business logic
│   ├── MutualFund.swift         # Core fund model
│   ├── NAVData.swift            # Historical NAV data
│   └── FundDetails.swift        # Combined fund details and metrics
├── Views/                       # SwiftUI views
│   ├── SplashScreenView.swift   # App launch splash with FWB branding
│   ├── FundsListView.swift      # Main fund listing with search
│   └── FundDetailView.swift     # Individual fund analysis
├── Services/                    # External services and data access
│   ├── APIService.swift         # API communication layer
│   └── DataCache.swift          # Caching and offline functionality
└── Extensions/                  # Swift extensions and utilities
    ├── Date+Extensions.swift    # Date formatting and utilities
    └── Double+Extensions.swift  # Number formatting utilities
```

## Development Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Swift 5.9 or later
- Active internet connection for API access

### Getting Started
1. **Clone/Open Project**
   ```bash
   cd /Users/sgupta/Projects/funds-with-benefits
   open MutualFundsApp.xcodeproj
   ```

2. **Build Configuration**
   - Ensure deployment target is set to iOS 17.0
   - Verify Swift version is 5.9+
   - Check that Charts framework is available

3. **Run the App**
   - Select simulator or connected device
   - Build and run (⌘+R)

### Development Environment
- **Simulator**: iPhone 15 Pro (recommended for testing)
- **Physical Device**: Any iPhone running iOS 17+
- **Network**: Required for initial data fetching

## API Integration

### Base API
- **URL**: `https://api.mfapi.in/mf`
- **Format**: REST API with JSON responses
- **Authentication**: None required
- **Rate Limiting**: Not specified, but implemented client-side caching

### Endpoints

#### 1. Get All Funds
```
GET https://api.mfapi.in/mf
Response: Array of MutualFund objects
```

#### 2. Get Fund History
```
GET https://api.mfapi.in/mf/{schemeCode}
Response: FundHistory object with metadata and NAV history
```

### Error Handling
The `APIService` implements comprehensive error handling:
- Network connectivity issues
- JSON parsing errors
- Invalid URLs
- HTTP status errors

### JSON Parsing Robustness
Enhanced JSON parsing with custom Codable implementations to handle API format variations:
- **Flexible scheme_code parsing**: Handles both integer and string values from API
- **MutualFund model**: Custom decoder for `schemeCode` field variations
- **FundMeta model**: Custom decoder for `scheme_code` field variations  
- **Backward compatibility**: Supports legacy and updated API response formats
- **Error resilience**: Graceful handling of unexpected data types

### Caching Strategy
- **Fund List**: Cached for 1 hour
- **Fund History**: Cached for 30 minutes
- **Cache Storage**: UserDefaults with structured data
- **Cache Management**: Automatic expiration and cleanup

## Data Models

### Core Models

#### MutualFund
```swift
struct MutualFund: Codable, Identifiable, Hashable {
    let schemeCode: String        // Unique identifier
    let schemeName: String        // Fund name
    let isinGrowth: String?       // ISIN for growth plans
    let isinDivReinvestment: String? // ISIN for dividend plans
    
    // Computed Properties
    var fundHouse: String         // Extracted fund house
    var category: String          // Fund category (Equity/Debt/Hybrid)
    var isGrowthPlan: Bool       // Plan type detection
    var isDividendPlan: Bool     // Plan type detection
}
```

#### NAVData
```swift
struct NAVData: Codable, Identifiable {
    let date: String              // DD-MM-YYYY format
    let nav: String               // NAV value as string
    
    // Computed Properties
    var navValue: Double          // Parsed NAV value
    var dateValue: Date           // Parsed date
    var formattedDate: String     // User-friendly date format
}
```

#### FundDetails
```swift
struct FundDetails {
    let fund: MutualFund          // Base fund information
    let history: [NAVData]        // Historical NAV data
    let meta: FundMeta?           // Additional metadata
    
    // Performance Calculations
    var currentNAV: Double
    var dailyChange: Double
    var dailyChangePercentage: Double
    
    // Methods
    func performanceForPeriod(_ period: TimeRange) -> FundPerformance?
}
```

### Supporting Models

#### TimeRange
```swift
enum TimeRange: String, CaseIterable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
}
```

#### FundPerformance
```swift
struct FundPerformance {
    let totalReturn: Double       // Total return percentage
    let annualizedReturn: Double  // CAGR
    let volatility: Double        // Risk measure
}
```

## UI Components

### View Hierarchy

#### ContentView (Root)
- Tab-based navigation
- Three tabs: Funds, Favorites, About
- Global app state management

#### FundsListView
- Main fund listing interface
- Real-time search functionality
- Category-based filtering
- Pull-to-refresh capability
- Navigation to fund details

#### FundDetailView
- Comprehensive fund analysis
- Interactive performance charts
- Time period selection
- Performance metrics display
- Fund information details

### Reusable Components

#### SearchBar
```swift
struct SearchBar: View {
    @Binding var text: String
    // Debounced search implementation
}
```

#### CategoryFilterView
```swift
struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selectedCategory: String
    // Horizontal scrollable filter buttons
}
```

#### PerformanceChartView
```swift
struct PerformanceChartView: View {
    let data: [NAVData]
    let selectedRange: TimeRange
    // Interactive charts using Swift Charts
}
```

## Performance Optimization

### Caching Strategy
1. **Multi-level Caching**
   - Fund list cached for 1 hour
   - Individual fund history cached for 30 minutes
   - Automatic cache invalidation

2. **Memory Management**
   - Lazy loading of fund details
   - Efficient data structures
   - Proper object lifecycle management

3. **Network Optimization**
   - Cache-first approach
   - Minimal API calls
   - Background data fetching

### UI Performance
1. **List Optimization**
   - Efficient SwiftUI Lists
   - Minimal view updates
   - Proper state management

2. **Chart Performance**
   - Data sampling for large datasets
   - Efficient chart rendering
   - Smooth animations

## Testing Strategy

### Unit Testing (MutualFundsAppTests)
- **Models**: Data parsing, calculations, and computed properties
- **Services**: API integration, caching, and error handling
- **Extensions**: Date formatting and number utilities
- **Performance**: Search filtering and data processing

**Test Coverage**:
- MutualFund model properties and categorization
- MutualFund JSON parsing with integer/string scheme codes
- NAVData parsing and date conversion
- FundMeta JSON parsing with flexible scheme_code handling
- FundHistory complete parsing with metadata
- FundDetails performance calculations
- DataCache storage and retrieval
- Double formatting extensions
- JSON encoding/decoding round-trip tests

**Running Tests**:
```bash
# Command line
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'

# Xcode
⌘+U (Run All Tests)
```

### UI Testing (MutualFundsAppUITests)
- **Navigation**: Tab switching and view transitions
- **Search**: Real-time filtering and user input
- **Lists**: Fund browsing and detail navigation
- **User Interactions**: Pull-to-refresh, category filtering

**Test Coverage**:
- App launch and basic navigation
- Search functionality with text input and clearing
- Tab navigation between Funds, Favorites, About
- Fund detail view navigation (robust element detection)
- Category filtering interactions
- Pull-to-refresh gestures (multiple scrollable element strategies)

**Recent Improvements**:
- Fixed `testFundDetailNavigation()` with multiple element detection strategies
- Fixed `testPullToRefresh()` with fallback scrollable element handling
- Enhanced `testSearchFunctionality()` with improved timeouts and search clearing tests
- Enhanced test robustness for SwiftUI NavigationLink and List components
- Added longer wait times for API data loading in tests
- Improved JSON parsing flexibility for API response variations

**Test Reliability Enhancements**:
- Extended timeouts from 10s to 15s for API-dependent tests
- Added 8-second data loading waits for comprehensive fund list loading
- Multiple fallback strategies for SwiftUI element detection
- Robust handling of different SwiftUI component hierarchies
- Comprehensive search field interaction testing including clear functionality

### Integration Testing
- **API Integration**: Network calls and error handling
- **Cache Management**: Data persistence and retrieval
- **Performance**: Memory usage and responsiveness

### Manual Testing Checklist
- [ ] App launches successfully
- [ ] Fund list loads from API
- [ ] Search functionality works across all criteria
- [ ] Fund details display correctly with charts
- [ ] Charts render properly for all time periods
- [ ] Offline mode works (cached data accessible)
- [ ] Error states display appropriately with retry options
- [ ] Performance is acceptable for large fund lists
- [ ] Category filters work correctly
- [ ] Pull-to-refresh updates data successfully

## Deployment

### Build Configuration
1. **Release Settings**
   - Optimization level: `-O`
   - Swift compilation mode: `wholemodule`
   - Strip debug symbols: Enabled

2. **App Store Preparation**
   - Bundle identifier: `com.example.MutualFundsApp`
   - Version management
   - App icons and screenshots
   - App Store metadata

### Distribution
1. **TestFlight** (Internal testing)
2. **App Store** (Public release)
3. **Enterprise** (Corporate distribution)

## Future Enhancements

### Planned Features
1. **Favorites System**
   - Save preferred funds
   - Quick access list
   - Personalized dashboard

2. **Portfolio Tracking**
   - Investment tracking
   - Performance monitoring
   - Alerts and notifications

3. **Advanced Analytics**
   - Fund comparison tools
   - Risk analysis
   - Investment recommendations

4. **Data Export**
   - CSV/Excel export
   - Performance reports
   - Historical data download

### Technical Improvements
1. **Core Data Integration**
   - Local database storage
   - Offline-first architecture
   - Better data management

2. **Push Notifications**
   - Price alerts
   - Performance updates
   - Market news

3. **Widget Support**
   - Home screen widgets
   - Quick fund overview
   - Performance at a glance

4. **Machine Learning**
   - Trend analysis
   - Prediction models
   - Personalized recommendations

### API Enhancements
1. **Real-time Data**
   - WebSocket integration
   - Live price updates
   - Real-time notifications

2. **Additional Data Sources**
   - Multiple API providers
   - Data validation
   - Fallback mechanisms

## Contributing Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Comprehensive documentation
- Unit test coverage

### Git Workflow
- Feature branches for new development
- Pull request reviews
- Semantic versioning
- Conventional commit messages

### Development Process
1. Create feature branch
2. Implement changes with tests
3. Update documentation
4. Submit pull request
5. Code review and approval
6. Merge to main branch

## Troubleshooting

### Common Issues
1. **Network Errors**
   - Check internet connectivity
   - Verify API endpoint availability
   - Clear app cache

2. **JSON Parsing Errors**
   - Check for API format changes (integer vs string scheme codes)
   - Verify model compatibility with API responses
   - Review custom Codable implementations for flexibility
   - Test with different API response formats

3. **Performance Issues**
   - Monitor memory usage
   - Check for retain cycles
   - Optimize heavy computations

4. **UI Test Flakiness**
   - Ensure adequate wait times for API data loading
   - Use multiple element detection strategies for SwiftUI components
   - Test with different simulator configurations
   - Verify element accessibility identifiers

5. **UI Problems**
   - Test on different screen sizes
   - Verify iOS version compatibility
   - Check SwiftUI preview issues

### Debug Tools
- Xcode Instruments
- Network debugging
- Memory profiling
- Performance monitoring

---

**Last Updated**: July 2025
**Version**: 1.0.0
**Contact**: Development Team