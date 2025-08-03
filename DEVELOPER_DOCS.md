# Funds with Benefits (FWB) - Developer Documentation

## Project Overview

iOS app for tracking Indian mutual funds with real-time data from api.mfapi.in. SwiftUI + MVVM architecture.

**Key Features**: Fund data with charts, holdings management, high-performance fund matching (99%+), portfolio sorting

**Tech Stack**: SwiftUI (iOS 17+), MVVM + Combine, Swift Charts, URLSession async/await, UserDefaults caching

## Key Files

**Models**: `MutualFund.swift`, `HoldingData.swift`, `Portfolio.swift`  
**Services**: `APIService.swift`, `DataCache.swift`, `HoldingsManager.swift`, `FundMatcher.swift`  
**Views**: `FundsListView.swift`, `FundDetailView.swift`, `Holdings/`

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

**Test Status**: 50/50 unit tests, 18/19 UI tests passing ✅

**Portfolio Tests** (12 new): Individual fund calculations + portfolio banner calculations + integration tests

## Fund Matching (FundMatcher.swift)

**Performance**: 99%+ accuracy, 20-50x faster, <1s refresh time

**Algorithm**: Multi-factor scoring (AMC 25%, core name 25%, financial terms 25%, plan type 25%)

**Optimization**: AMC-first filtering (90% search space reduction), preprocessing cache, similarity cache

**Key Methods**: `matchHoldingsWithFunds()`, `preprocessFundsData()`, `updateHoldingsWithLatestNAV()`

## Holdings & Portfolio

**Holdings**: CSV/PDF parsing via `HoldingsParser.swift`, managed by `HoldingsManager.swift` (MainActor)

**Calculations**: 
- Individual: Current value (units×NAV), returns, returns%, XIRR
- Portfolio: Sums + weighted average XIRR by investment amount

## Quick Reference

**API Exploration**: Download data locally first (`curl https://api.mfapi.in/mf > data.json`)

**Fund House**: First-word extraction for performance only (90% search space reduction), not accurate AMC parsing

**Troubleshooting**:
- Race conditions: Extract property access to variables
- MainActor: Use `await MainActor.run`  
- Cache issues: Clear DataCache
- Performance: Check preprocessing cache in FundMatcher

---

**Version**: 0.0.1 (FWB Branding Update) | **iOS Target**: 17.0+