import Foundation
import Combine

@MainActor
class HoldingsManager: ObservableObject {
    static let shared = HoldingsManager()
    
    @Published var portfolio: Portfolio?
    @Published var isLoading = false
    @Published var loadingState: LoadingState = .idle
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let portfolioKey = "SavedPortfolio"
    private let holdingsParser = HoldingsParser.shared
    private let fundMatcher = FundMatcher.shared
    private let apiService = APIService.shared
    
    private init() {
        loadSavedPortfolio()
    }
    
    // MARK: - Portfolio Management
    
    func uploadHoldingsFile(from url: URL) async {
        // Update UI state on main thread
        await MainActor.run {
            isLoading = true
            loadingState = .uploadingFile
            errorMessage = nil
        }
        
        do {
            // Perform heavy operations in background
            let result = try await Task.detached(priority: .userInitiated) {
                // 1. Parse holdings from file (background task)
                let parsedHoldings = try await self.holdingsParser.parseHoldingsFile(from: url)
                
                // 2. Get current funds list for matching (background task)
                let availableFunds = try await self.apiService.fetchAllFunds()
                
                // 3. Match holdings with available funds (background task)
                let matchedHoldings = await self.fundMatcher.matchHoldingsWithFunds(parsedHoldings, availableFunds: availableFunds)
                
                // 4. Update holdings with latest NAV data for live calculations
                let updatedHoldings = try await self.fundMatcher.updateHoldingsWithLatestNAV(matchedHoldings)
                
                // 5. Create portfolio
                return Portfolio(holdings: updatedHoldings)
            }.value
            
            // Save portfolio and update UI state on main thread
            await savePortfolio(result)
            await MainActor.run {
                isLoading = false
                loadingState = .idle
            }
            
        } catch {
            // Update error state on main thread
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                loadingState = .idle
            }
        }
    }
    
    func savePortfolio(_ portfolio: Portfolio) async {
        self.portfolio = portfolio
        
        // Save to UserDefaults
        do {
            let encoded = try JSONEncoder().encode(portfolio)
            userDefaults.set(encoded, forKey: portfolioKey)
        } catch {
            errorMessage = "Failed to save portfolio: \(error.localizedDescription)"
        }
    }
    
    func loadSavedPortfolio() {
        guard let data = userDefaults.data(forKey: portfolioKey) else {
            return
        }
        
        do {
            let decodedPortfolio = try JSONDecoder().decode(Portfolio.self, from: data)
            portfolio = decodedPortfolio
        } catch {
            print("Failed to load saved portfolio: \(error.localizedDescription)")
            // Clean up corrupted data
            userDefaults.removeObject(forKey: portfolioKey)
        }
    }
    
    func clearPortfolio() {
        portfolio = nil
        userDefaults.removeObject(forKey: portfolioKey)
    }
    
    func refreshPortfolioData() async {
        guard let currentPortfolio = portfolio else { return }
        
        // Update UI state on main thread
        await MainActor.run {
            isLoading = true
            loadingState = .refreshingPortfolio
            errorMessage = nil
        }
        
        do {
            // Perform heavy operations in background
            let result = try await Task.detached(priority: .userInitiated) {
                // Try to get cached funds first, fallback to API if cache is empty
                var availableFunds = DataCache.shared.getCachedFundsList()
                
                if availableFunds == nil || availableFunds!.isEmpty {
                    // Cache is empty, fetch from API (background task)
                    availableFunds = try await self.apiService.fetchAllFunds()
                }
                
                guard let funds = availableFunds, !funds.isEmpty else {
                    throw APIService.APIError.noData
                }
                
                // Re-match holdings with fund data (background task)  
                let matchedHoldings = await self.fundMatcher.matchHoldingsWithFunds(currentPortfolio.holdings, availableFunds: funds)
                
                // Update holdings with latest NAV data for live calculations
                let updatedHoldings = try await self.fundMatcher.updateHoldingsWithLatestNAV(matchedHoldings)
                
                return Portfolio(holdings: updatedHoldings)
            }.value
            
            // Update portfolio and UI state on main thread
            await savePortfolio(result)
            await MainActor.run {
                isLoading = false
                loadingState = .idle
            }
            
        } catch {
            // Update error state on main thread
            await MainActor.run {
                errorMessage = "Failed to refresh portfolio: \(error.localizedDescription)"
                isLoading = false
                loadingState = .idle
            }
        }
    }
    
    // MARK: - Individual Holdings Management
    
    func updateHolding(_ holding: HoldingData) async {
        guard let currentPortfolio = portfolio else { return }
        
        // Find and update the holding
        if let index = currentPortfolio.holdings.firstIndex(where: { $0.id == holding.id }) {
            var updatedHoldings = currentPortfolio.holdings
            updatedHoldings[index] = holding
            
            let updatedPortfolio = Portfolio(holdings: updatedHoldings)
            await savePortfolio(updatedPortfolio)
        }
    }
    
    func removeHolding(_ holding: HoldingData) async {
        guard let currentPortfolio = portfolio else { return }
        
        let updatedHoldings = currentPortfolio.holdings.filter { $0.id != holding.id }
        let updatedPortfolio = Portfolio(holdings: updatedHoldings)
        await savePortfolio(updatedPortfolio)
    }
    
    func addHolding(_ holding: HoldingData) async {
        guard let currentPortfolio = portfolio else {
            // Create new portfolio with this holding
            let newPortfolio = Portfolio(holdings: [holding])
            await savePortfolio(newPortfolio)
            return
        }
        
        var updatedHoldings = currentPortfolio.holdings
        updatedHoldings.append(holding)
        
        let updatedPortfolio = Portfolio(holdings: updatedHoldings)
        await savePortfolio(updatedPortfolio)
    }
    
    // MARK: - Fund Details Integration
    
    func getFundDetails(for holding: HoldingData) async throws -> FundDetails? {
        guard let schemeCode = holding.matchedSchemeCode else {
            return nil
        }
        
        // Create a temporary MutualFund object to fetch details
        let tempFund = MutualFund(
            schemeCode: schemeCode,
            schemeName: holding.schemeName
        )
        
        return try await apiService.fetchFundDetails(for: tempFund)
    }
    
    // MARK: - Analytics and Insights
    
    var hasHoldings: Bool {
        portfolio?.holdings.isEmpty == false
    }
    
    var matchedHoldingsCount: Int {
        portfolio?.matchedHoldings.count ?? 0
    }
    
    var unmatchedHoldingsCount: Int {
        portfolio?.unmatchedHoldings.count ?? 0
    }
    
    var portfolioSummary: PortfolioSummary? {
        portfolio?.summary
    }
    
    func getCategoryAllocation() -> [CategoryAllocation] {
        guard let portfolio = portfolio else { return [] }
        
        let breakdown = portfolio.categoryBreakdown
        let totalValue = portfolio.summary.currentPortfolioValue
        
        return breakdown.values.map { allocation in
            var updatedAllocation = allocation
            updatedAllocation.allocationPercentage = totalValue > 0 ? (allocation.currentValue / totalValue) * 100 : 0
            return updatedAllocation
        }.sorted { $0.currentValue > $1.currentValue }
    }
    
    func getSourceAllocation() -> [SourceAllocation] {
        guard let portfolio = portfolio else { return [] }
        
        let breakdown = portfolio.sourceBreakdown
        let totalValue = portfolio.summary.currentPortfolioValue
        
        return breakdown.values.map { allocation in
            var updatedAllocation = allocation
            updatedAllocation.allocationPercentage = totalValue > 0 ? (allocation.currentValue / totalValue) * 100 : 0
            return updatedAllocation
        }.sorted { $0.currentValue > $1.currentValue }
    }
    
    func getTopPerformers() -> [HoldingData] {
        portfolio?.topPerformers ?? []
    }
    
    // MARK: - Data Export
    
    func exportPortfolioToCSV() -> String? {
        guard let portfolio = portfolio else { return nil }
        
        var csvContent = "Scheme Name,AMC,Category,Sub Category,Folio Number,Source,Units,Invested Value,Current Value,Returns,Returns %,XIRR,Match Status\n"
        
        for holding in portfolio.holdings {
            let matchStatus = holding.matchedSchemeCode != nil ? "Matched" : "Unmatched"
            let row = "\"\(holding.schemeName)\",\"\(holding.amcName)\",\"\(holding.category)\",\"\(holding.subCategory)\",\"\(holding.folioNumber)\",\"\(holding.source)\",\(holding.units),\(holding.investedValue),\(holding.currentValue),\(holding.returns),\(holding.returnsPercentage),\(holding.xirr),\(matchStatus)\n"
            csvContent += row
        }
        
        return csvContent
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

enum LoadingState {
    case idle
    case uploadingFile
    case refreshingPortfolio
    case processingData
}