import SwiftUI
import UniformTypeIdentifiers

enum SortOption: String, CaseIterable {
    case currentValueDesc = "Current Value ↓"
    case currentValueAsc = "Current Value ↑"
    case xirrDesc = "Annualised Return ↓"
    case xirrAsc = "Annualised Return ↑"
}

struct HoldingsView: View {
    @StateObject private var holdingsManager = HoldingsManager.shared
    @State private var showingFilePicker = false
    @State private var showingExportSheet = false
    @State private var exportedCSV: String = ""
    @State private var selectedSortOption: SortOption = .currentValueDesc
    
    var body: some View {
        NavigationView {
            Group {
                if holdingsManager.hasHoldings {
                    portfolioView
                } else {
                    emptyStateView
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingFilePicker = true }) {
                            Label("Upload Holdings", systemImage: "doc.badge.plus")
                        }
                        
                        if holdingsManager.hasHoldings {
                            Button(action: {
                                Task {
                                    await refreshPortfolio()
                                }
                            }) {
                                Label("Refresh Data", systemImage: "arrow.clockwise")
                            }
                            
                            Button(action: exportToCSV) {
                                Label("Export to CSV", systemImage: "square.and.arrow.up")
                            }
                            
                            Divider()
                            
                            Button(action: clearPortfolio) {
                                Label("Clear Portfolio", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                FilePickerView { url in
                    Task {
                        await holdingsManager.uploadHoldingsFile(from: url)
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [exportedCSV])
            }
            .alert("Error", isPresented: .constant(holdingsManager.errorMessage != nil)) {
                Button("OK") {
                    holdingsManager.clearError()
                }
            } message: {
                Text(holdingsManager.errorMessage ?? "")
            }
        }
    }
    
    @ViewBuilder
    private var portfolioView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let portfolio = holdingsManager.portfolio {
                    PortfolioSummaryView(summary: portfolio.summary)
                        .padding(.horizontal, 8)
                    
                    // Holdings List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer()
                            
                            // Sort Options (center)
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        selectedSortOption = option
                                    }) {
                                        HStack {
                                            Text(option.rawValue)
                                            if selectedSortOption == option {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedSortOption.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(sortedHoldings(portfolio.holdings)) { holding in
                                HoldingRowView(
                                    holding: holding, 
                                    isClickable: holding.matchedSchemeCode != nil
                                )
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshPortfolio()
        }
        .overlay(alignment: .top) {
            if holdingsManager.isLoading && holdingsManager.loadingState == .refreshingPortfolio {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Refreshing portfolio...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: holdingsManager.isLoading)
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Holdings Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Upload your holdings statement to track your mutual fund portfolio and see comprehensive analytics.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Upload Holdings File")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            VStack(spacing: 8) {
                Text("Supported Formats")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label("PDF", systemImage: "doc.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("CSV", systemImage: "tablecells.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)
        }
        .overlay {
            if holdingsManager.isLoading && holdingsManager.loadingState == .uploadingFile {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Processing holdings file...")
                        .font(.headline)
                    Text("This may take a few moments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(32)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private func refreshPortfolio() async {
        await holdingsManager.refreshPortfolioData()
    }
    
    private func clearPortfolio() {
        holdingsManager.clearPortfolio()
    }
    
    private func sortedHoldings(_ holdings: [HoldingData]) -> [HoldingData] {
        switch selectedSortOption {
        case .currentValueDesc:
            return holdings.sorted { $0.currentValue > $1.currentValue }
        case .currentValueAsc:
            return holdings.sorted { $0.currentValue < $1.currentValue }
        case .xirrDesc:
            return holdings.sorted { $0.xirr > $1.xirr }
        case .xirrAsc:
            return holdings.sorted { $0.xirr < $1.xirr }
        }
    }
    
    private func exportToCSV() {
        if let csvContent = holdingsManager.exportPortfolioToCSV() {
            exportedCSV = csvContent
            showingExportSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HoldingsView()
}