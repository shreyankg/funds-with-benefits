import SwiftUI

struct HoldingRowView: View {
    let holding: HoldingData
    @State private var showingFundDetail = false
    @StateObject private var holdingsManager = HoldingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with fund name and match status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(holding.schemeName)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(holding.amcName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Match status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(holding.matchedSchemeCode != nil ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(holding.matchedSchemeCode != nil ? "Matched" : "Unmatched")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Category badge
                    Text(holding.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                }
            }
            
            // Investment details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(holding.units.formatted(.number.precision(.fractionLength(3))))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Invested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(holding.investedValue.formatted(.currency(code: "INR")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(holding.currentValue.formatted(.currency(code: "INR")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Returns and XIRR
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Returns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(holding.returns.formatted(.currency(code: "INR")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(holding.returns >= 0 ? .green : .red)
                        
                        Text("(\(holding.returnsPercentage.formatted(.number.precision(.fractionLength(2))))%)")
                            .font(.caption)
                            .foregroundColor(holding.returns >= 0 ? .green : .red)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("XIRR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(holding.xirr.formatted(.number.precision(.fractionLength(2))))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(holding.xirr >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Source")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(holding.source)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            // Additional details row
            HStack(spacing: 16) {
                Label(holding.folioNumber, systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if holding.matchedSchemeCode != nil {
                    Button(action: { showingFundDetail = true }) {
                        HStack(spacing: 4) {
                            Text("View Details")
                                .font(.caption)
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingFundDetail) {
            if let schemeCode = holding.matchedSchemeCode {
                FundDetailSheetView(holding: holding, schemeCode: schemeCode)
            }
        }
    }
    
    private var categoryColor: Color {
        switch holding.category.lowercased() {
        case "equity":
            return .blue
        case "debt":
            return .green
        case "hybrid":
            return .orange
        default:
            return .purple
        }
    }
}

struct FundDetailSheetView: View {
    let holding: HoldingData
    let schemeCode: String
    @State private var fundDetails: FundDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var holdingsManager = HoldingsManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading fund details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let fundDetails = fundDetails {
                    FundDetailView(fund: fundDetails.fund)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Unable to load fund details")
                            .font(.headline)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("Retry") {
                            loadFundDetails()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle(holding.schemeName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            loadFundDetails()
        }
    }
    
    private func loadFundDetails() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let details = try await holdingsManager.getFundDetails(for: holding)
                await MainActor.run {
                    self.fundDetails = details
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    HoldingRowView(
        holding: HoldingData(
            schemeName: "SBI Conservative Hybrid Fund Direct Growth",
            amcName: "SBI Mutual Fund",
            category: "Hybrid",
            subCategory: "Conservative Hybrid",
            folioNumber: "22821659",
            source: "External",
            units: 610.664,
            investedValue: 32931.93,
            currentValue: 48581.37,
            returns: 15649.44,
            xirr: 10.19,
            matchedSchemeCode: "123456"
        )
    )
    .padding()
}