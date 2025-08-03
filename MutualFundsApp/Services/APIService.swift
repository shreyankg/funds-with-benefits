import Foundation
import Combine
import UIKit

// Temporary inline AppSettings until we add the separate file to Xcode project
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var showDividendFunds: Bool {
        didSet {
            UserDefaults.standard.set(showDividendFunds, forKey: "showDividendFunds")
        }
    }
    
    private init() {
        // Default to false (dividend funds hidden by default)
        self.showDividendFunds = UserDefaults.standard.object(forKey: "showDividendFunds") as? Bool ?? false
    }
    
    // Helper method to get filtered funds based on settings
    func filteredFunds(_ funds: [MutualFund]) -> [MutualFund] {
        if showDividendFunds {
            return funds
        } else {
            return funds.filter { !$0.isDividendPlan }
        }
    }
}

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://api.mfapi.in/mf"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .decodingError(let error):
                return "Data parsing error: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchAllFunds(forceRefresh: Bool = false) async throws -> [MutualFund] {
        // Try to get cached data first unless force refresh is requested
        if !forceRefresh, let cachedFunds = DataCache.shared.getCachedFundsList() {
            return cachedFunds
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let funds = try JSONDecoder().decode([MutualFund].self, from: data)
            
            // Cache the fetched data
            DataCache.shared.cacheFundsList(funds)
            
            return funds
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchFundHistory(schemeCode: String, forceRefresh: Bool = false) async throws -> FundHistory {
        // Try to get cached data first unless force refresh is requested
        if !forceRefresh, let cachedHistory = DataCache.shared.getCachedFundHistory(for: schemeCode) {
            return cachedHistory
        }
        
        guard let url = URL(string: "\(baseURL)/\(schemeCode)") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let history = try JSONDecoder().decode(FundHistory.self, from: data)
            
            // Cache the fetched data
            DataCache.shared.cacheFundHistory(history, for: schemeCode)
            
            return history
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchFundDetails(for fund: MutualFund, forceRefresh: Bool = false) async throws -> FundDetails {
        let history = try await fetchFundHistory(schemeCode: fund.schemeCode, forceRefresh: forceRefresh)
        return FundDetails(fund: fund, history: history.data, meta: history.meta)
    }
}

@MainActor
class FundsViewModel: ObservableObject {
    @Published var funds: [MutualFund] = []
    @Published var filteredFunds: [MutualFund] = []
    @Published var searchText = "" {
        didSet {
            filterFunds()
        }
    }
    @Published var selectedCategory: String = "All" {
        didSet {
            filterFunds()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let appSettings = AppSettings.shared
    
    let categories = ["All", "Equity", "Debt", "Hybrid", "Other"]
    
    init() {
        loadFunds()
        
        // Listen to settings changes to re-filter funds
        appSettings.$showDividendFunds
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] (showDividendFunds: Bool) in
                self?.filterFunds()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadFunds() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedFunds = try await apiService.fetchAllFunds()
                funds = fetchedFunds
                filterFunds()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func filterFunds() {
        var filtered = funds
        
        // Apply dividend fund filtering based on settings
        filtered = appSettings.filteredFunds(filtered)
        
        if !searchText.isEmpty {
            filtered = filtered.filter { fund in
                fund.schemeName.localizedCaseInsensitiveContains(searchText) ||
                fund.schemeCode.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Explicitly notify observers that the filtered funds are about to change
        objectWillChange.send()
        filteredFunds = filtered
    }
    
    func refreshFunds() {
        loadFunds()
    }
}

@MainActor
class FundDetailViewModel: ObservableObject {
    @Published var fundDetails: FundDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: TimeRange = .oneYear
    @Published var customZoomDays: Int?
    @Published var isZoomingEnabled = true
    
    private let apiService = APIService.shared
    private let minZoomDays = 7
    private let maxZoomDays = 1095
    
    func loadFundDetails(for fund: MutualFund, forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Check if we should force refresh or if cache is stale
                let shouldForceRefresh = forceRefresh || shouldRefreshFundCache(for: fund.schemeCode)
                
                let details = try await apiService.fetchFundDetails(for: fund, forceRefresh: shouldForceRefresh)
                fundDetails = details
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func shouldRefreshFundCache(for schemeCode: String) -> Bool {
        // For individual fund views, use a more aggressive cache policy (4 hours)
        let maxCacheAge: TimeInterval = 4 * 60 * 60 // 4 hours
        return !DataCache.shared.isFundHistoryCacheFresh(for: schemeCode, maxAge: maxCacheAge)
    }
    
    func refreshFundDetails() {
        guard let currentFund = fundDetails?.fund else { return }
        loadFundDetails(for: currentFund, forceRefresh: true)
    }
    
    var currentPerformance: FundPerformance? {
        return fundDetails?.performanceForPeriod(currentTimeRange)
    }
    
    var chartData: [NAVData] {
        guard let details = fundDetails else { return [] }
        
        let calendar = Calendar.current
        let endDate = Date()
        let daysToShow: Int
        
        if let customDays = customZoomDays {
            daysToShow = customDays
        } else {
            daysToShow = selectedTimeRange.days
        }
        
        let startDate = calendar.date(byAdding: .day, value: -daysToShow, to: endDate) ?? endDate
        
        return details.history.filter { navData in
            navData.dateValue >= startDate
        }.sorted { $0.dateValue < $1.dateValue }
    }
    
    var currentTimeRange: TimeRange {
        if let customDays = customZoomDays {
            return TimeRange(days: customDays)
        }
        return selectedTimeRange
    }
    
    func updateZoom(dragTranslation: CGSize) {
        guard isZoomingEnabled else { return }
        
        let currentDays = customZoomDays ?? selectedTimeRange.days
        let relativeSensitivity = calculateRelativeSensitivity(for: currentDays)
        let dayChange = Int(Double(dragTranslation.width) / relativeSensitivity)
        let newDays = max(minZoomDays, min(maxZoomDays, currentDays + dayChange))
        
        if newDays != currentDays {
            #if !os(watchOS)
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
            #endif
            
            if TimeRange.allCases.contains(where: { $0.days == newDays }) {
                customZoomDays = nil
                selectedTimeRange = TimeRange(days: newDays)
            } else {
                customZoomDays = newDays
            }
        }
    }
    
    func resetZoom() {
        customZoomDays = nil
    }
    
    private func calculateRelativeSensitivity(for currentDays: Int) -> Double {
        // Adjust sensitivity based on time frame for optimal control:
        // - Short periods (< 1 month): Lower sensitivity for precise control
        // - Medium periods (1 month - 1 year): Standard sensitivity 
        // - Long periods (> 1 year): Higher sensitivity for broader changes
        
        switch currentDays {
        case 0..<30:        // < 1 month: Higher sensitivity (easy to zoom)
            return 5.0
        case 30..<365:      // 1 month - 1 year: Standard sensitivity
            return 1.0
        default:            // > 1 year: Lower sensitivity (precise control)
            return 0.05
        }
    }
}