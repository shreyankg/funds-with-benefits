import SwiftUI

struct FundsListView: View {
    @StateObject private var viewModel = FundsViewModel()
    @State private var showingCategories = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                CategoryFilterView(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if viewModel.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.refreshFunds()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.filteredFunds) { fund in
                        NavigationLink(destination: FundDetailView(fund: fund)) {
                            FundRowView(fund: fund)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.refreshFunds()
                    }
                }
            }
            .navigationTitle("Mutual Funds")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search funds, codes, or fund houses", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category ? 
                                Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedCategory == category ? 
                                .white : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FundRowView: View {
    let fund: MutualFund
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fund.schemeName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(fund.fundHouse)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    CategoryBadge(category: fund.category)
                    
                    Text("Code: \(fund.schemeCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                if fund.isGrowthPlan {
                    PlanBadge(title: "Growth", color: .green)
                }
                
                if fund.isDividendPlan {
                    PlanBadge(title: "Dividend", color: .blue)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategoryBadge: View {
    let category: String
    
    private var backgroundColor: Color {
        switch category {
        case "Equity": return .orange
        case "Debt": return .blue
        case "Hybrid": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        Text(category)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct PlanBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading mutual funds...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    FundsListView()
}