import SwiftUI
import UniformTypeIdentifiers

struct HoldingsView: View {
    @StateObject private var holdingsManager = HoldingsManager.shared
    @State private var showingFilePicker = false
    @State private var showingExportSheet = false
    @State private var exportedCSV: String = ""
    
    var body: some View {
        NavigationView {
            Group {
                if holdingsManager.hasHoldings {
                    portfolioView
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Portfolio")
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
                        .padding(.horizontal)
                    
                    // Holdings List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Holdings")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(portfolio.holdings.count) funds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(portfolio.holdings.sorted { $0.currentValue > $1.currentValue }) { holding in
                                HoldingRowView(holding: holding)
                                    .padding(.horizontal)
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