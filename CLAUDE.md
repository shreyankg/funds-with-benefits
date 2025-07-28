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

## Claude Code Specific Guidelines

### Code Quality Requirements
- Always test API integration changes with real endpoints
- Maintain cache performance when modifying data models
- Ensure chart interactions remain responsive
- Follow existing error handling patterns throughout the app
- Consider offline functionality when making network-related changes

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

## Quick Reference

### Key API Endpoints
- **Base URL**: `https://api.mfapi.in/mf`
- `GET /mf` - All mutual funds list
- `GET /mf/{schemeCode}` - Individual fund history

### Important Files to Know
- `APIService.swift` - All API integration logic
- `DataCache.swift` - Caching system
- `MutualFund.swift` - Core data model
- `ContentView.swift` - Main app navigation
- `DEVELOPER_DOCS.md` - Complete technical documentation

### Testing Commands
```bash
# Run all tests
xcodebuild test -scheme MutualFundsApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

---

**Note**: This file provides Claude Code-specific guidance. For complete technical documentation, architecture details, and development workflows, refer to `DEVELOPER_DOCS.md`.