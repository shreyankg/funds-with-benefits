# Funds with Benefits (FWB) - Developer Documentation

## Project Overview

iOS app for tracking Indian mutual funds with real-time data from api.mfapi.in. SwiftUI + MVVM architecture.

**Key Features**: Fund data with interactive zoom charts, holdings management, high-performance fund matching (99%+), portfolio sorting, settings-based upload

**Tech Stack**: SwiftUI (iOS 17+), MVVM + Combine, Swift Charts, URLSession async/await, UserDefaults caching

## Key Files

**Models**: `MutualFund.swift`, `HoldingData.swift`, `Portfolio.swift`, `FundDetails.swift`  
**Services**: `APIService.swift`, `DataCache.swift`, `HoldingsManager.swift`, `FundMatcher.swift`  
**Views**: `FundsListView.swift`, `FundDetailView.swift`, `Holdings/`, `ContentView.swift` (4-tab navigation)

## API & Caching

**API**: `https://api.mfapi.in/mf` - GET /mf (fund list), GET /mf/{code} (fund history)

**Cache Policy**:
- Fund list: 24h expiration
- Fund history: 24h (configurable), individual views: 4h  
- Storage: UserDefaults
- **Enhanced**: Selective cache busting, age detection, force refresh

## Cache Management (August 2025)

**Key Methods**: `clearFundHistory(for:)`, `isFundHistoryCacheFresh(for:maxAge:)`, API `forceRefresh` params

**Portfolio Refresh**: Auto-busts individual fund caches → fresh NAV → live calculations

**Files**: `DataCache.swift`, `APIService.swift`, `HoldingsManager.swift`, `FundDetailViewModel.swift`

## Development

**Build**: ⌘+B, ⌘+R, ⌘+U  
**CLI Test**: `xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'`

**Test Status**: 38/38 unit tests, 24/24 UI tests passing ✅ (updated for recent UI changes)

**Portfolio Tests** (12): Individual fund calculations + portfolio banner calculations + integration tests  
**Chart Zoom Tests** (6 new): Interactive zoom gestures, time range display, limits, state management  
**UI Tests Updated**: Settings tab content, portfolio sorting terminology, fund detail navigation

## Fund Matching (FundMatcher.swift)

**Performance**: 99%+ accuracy, 20-50x faster, <1s refresh time

**Algorithm**: Multi-factor scoring (AMC 25%, core name 25%, financial terms 25%, plan type 25%)

**Optimization**: AMC-first filtering (90% search space reduction), preprocessing cache, similarity cache

**Key Methods**: `matchHoldingsWithFunds()`, `preprocessFundsData()`, `updateHoldingsWithLatestNAV()`

## Holdings & Portfolio

**Holdings**: CSV/PDF parsing via `HoldingsParser.swift`, managed by `HoldingsManager.swift` (MainActor)

**Upload**: Settings tab integration, swipe-to-dismiss fund detail popups

**Portfolio UI**: Center-aligned sorting (Current Value ↓/↑, Annualised Return ↓/↑), clickable cards, simplified layout (no category badges, source in top-right)

**Calculations**: 
- Individual: Current value (units×NAV), returns, returns%, XIRR
- Portfolio: Sums + weighted average XIRR by investment amount

## Interactive Chart Zoom & Time Ranges

**Time Ranges**: 1W, 1M, 6M, 1Y, 3Y (6M hidden during custom zoom)  
**Custom Zoom**: 5D to 10Y range with fund age constraints  
**Start Date Picker**: DatePicker with smart auto-dismiss (day selection only)  
**Gestures**: Drag left/right to zoom in/out, integrated with date picker  
**Display**: Smart decimal format (1.5W, 2.3M, 1.2Y) with intelligent positioning  
**Integration**: Time range selector updates with custom periods, performance metrics recalculate

## Quick Reference

**API Exploration**: Download data locally first (`curl https://api.mfapi.in/mf > data.json`)

**Fund House**: First-word extraction for performance only (90% search space reduction), not accurate AMC parsing

**Recent Updates**:
- Chart: 6M time range, start date picker, drag zoom (5D-10Y)
- Portfolio: Settings upload, center sorting, clickable cards, clean UI
- Performance: Total Return + CAGR + Volatility metrics
- Navigation: 4-tab structure (Funds, Portfolio, Settings, About)

**Troubleshooting**:
- Race conditions: Extract property access to variables
- MainActor: Use `await MainActor.run`  
- Cache issues: Clear DataCache
- Performance: Check preprocessing cache in FundMatcher
- UI Tests: Updated for "Annualised Return" terminology

---

**Version**: 0.0.1 (FWB Branding Update) | **iOS Target**: 17.0+