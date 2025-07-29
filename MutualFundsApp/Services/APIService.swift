import Foundation
import Combine

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
    
    func fetchAllFunds() async throws -> [MutualFund] {
        // Try to get cached data first
        if let cachedFunds = DataCache.shared.getCachedFundsList() {
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
    
    func fetchFundHistory(schemeCode: String) async throws -> FundHistory {
        // Try to get cached data first
        if let cachedHistory = DataCache.shared.getCachedFundHistory(for: schemeCode) {
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
    
    func fetchFundDetails(for fund: MutualFund) async throws -> FundDetails {
        let history = try await fetchFundHistory(schemeCode: fund.schemeCode)
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
                fund.schemeCode.localizedCaseInsensitiveContains(searchText) ||
                fund.fundHouse.localizedCaseInsensitiveContains(searchText)
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
    
    private let apiService = APIService.shared
    
    func loadFundDetails(for fund: MutualFund) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let details = try await apiService.fetchFundDetails(for: fund)
                fundDetails = details
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    var currentPerformance: FundPerformance? {
        return fundDetails?.performanceForPeriod(selectedTimeRange)
    }
    
    var chartData: [NAVData] {
        guard let details = fundDetails else { return [] }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .oneWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .threeYears:
            startDate = calendar.date(byAdding: .year, value: -3, to: endDate) ?? endDate
        }
        
        return details.history.filter { navData in
            navData.dateValue >= startDate
        }.sorted { $0.dateValue < $1.dateValue }
    }
}