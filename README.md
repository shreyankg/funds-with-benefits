# Funds with Benefits (FWB)

A comprehensive iOS app for tracking and analyzing Indian mutual funds using real-time data from the MF API. Empowering your investment journey with intelligent insights and benefits.

## Features

### 📊 **Fund Discovery**
- Complete list of Indian mutual funds
- Real-time search by fund name, scheme code, or fund house
- Category-based filtering (Equity, Debt, Hybrid, Other)
- Growth and Dividend plan identification

### 📈 **Performance Analysis**
- Interactive charts with multiple timeframes (1W, 1M, 6M, 1Y, 3Y)
- Real-time NAV data and daily changes
- Total returns and annualized returns (CAGR)
- Volatility analysis and risk metrics

### 🎯 **Detailed Fund Information**
- Current NAV with daily change indicators
- Fund house and category information
- ISIN codes for growth and dividend plans
- Historical performance metrics

### 🔍 **Smart Search & Filters**
- Instant search across fund names, codes, and fund houses
- Category filters for focused browsing
- Responsive and intuitive user interface

## Technical Stack

- **Platform**: iOS 17.0+
- **Framework**: SwiftUI with MVVM architecture
- **Charts**: Native Charts framework for interactive visualizations
- **Networking**: URLSession with async/await
- **Data Source**: [MF API](https://api.mfapi.in/mf) for real-time mutual fund data

## Project Structure

```
FundsWithBenefitsApp/
├── MutualFundsApp.swift          # App entry point (renamed to FundsWithBenefitsApp)
├── ContentView.swift             # Main tab view
├── Models/
│   ├── MutualFund.swift         # Core fund model
│   ├── NAVData.swift            # Historical NAV data
│   └── FundDetails.swift        # Combined detail model
├── Views/
│   ├── SplashScreenView.swift   # App launch splash screen with FWB branding
│   ├── FundsListView.swift      # Main list with search
│   └── FundDetailView.swift     # Individual fund details
├── Services/
│   ├── APIService.swift         # API interactions
│   └── DataCache.swift          # Caching and offline functionality
└── Extensions/
    ├── Date+Extensions.swift    # Date utilities
    └── Double+Extensions.swift  # Number formatting
```

## Key Features Implementation

### 🔍 **Search & Filtering**
- Debounced search to minimize API calls
- Multi-criteria filtering (name, code, fund house, category)
- Real-time results with smooth animations

### 📊 **Performance Charts**
- Interactive line charts using Swift Charts
- Time period selection with dynamic data filtering
- Zoom and pan capabilities
- Performance metrics calculation

### 📱 **User Experience**
- Pull-to-refresh functionality
- Loading states and error handling
- Responsive design for all iPhone sizes
- Intuitive navigation and interaction patterns

## Data Source

This app uses the [MF API (api.mfapi.in)](https://api.mfapi.in/mf) which provides:

- **Fund List**: Complete catalog of Indian mutual funds
- **Historical Data**: Daily NAV history for performance analysis
- **Fund Metadata**: Fund house, category, and scheme information
- **Real-time Updates**: Latest NAV values and daily changes

## Performance Metrics

The app calculates several key financial metrics:

- **Total Return**: Percentage gain/loss over selected period
- **CAGR**: Compound Annual Growth Rate for annualized returns
- **Volatility**: Risk measure based on price fluctuations
- **Daily Change**: Day-over-day NAV change with percentages

## Getting Started

1. Open the project in Xcode 15+
2. Ensure iOS 17.0+ deployment target
3. Build and run on simulator or device
4. The app will automatically fetch the latest mutual fund data

## Future Enhancements

- Favorites functionality for quick fund access
- Portfolio tracking and performance comparison
- Push notifications for significant fund movements
- Advanced filtering options (AUM, expense ratio)
- Fund comparison tools
- Export functionality for data analysis

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Internet connection for real-time data

## License

MIT License

Copyright (c) 2025 Funds with Benefits

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

**Note**: This project is created for educational and personal use. The mutual fund data is provided by MF API and subject to their terms of service.

---

## About Funds with Benefits (FWB)

FWB represents a new approach to mutual fund investing - combining powerful analysis tools with user-friendly design to make investment decisions easier and more informed. Our mission is to democratize access to professional-grade investment insights.

**Built with ❤️ for Indian investors seeking better mutual fund analysis tools with real benefits.**