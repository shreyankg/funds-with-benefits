import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FundsListView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Funds")
                }
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
        }
    }
}

struct FavoritesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Favorites Feature")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This feature will allow you to save and track your favorite mutual funds for quick access.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Coming Soon!")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top)
            }
            .navigationTitle("Favorites")
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Mutual Funds Tracker")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track and analyze Indian mutual funds with real-time data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "magnifyingglass",
                        title: "Search & Filter",
                        description: "Find funds by name, code, or category"
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Performance Charts",
                        description: "Interactive charts with multiple timeframes"
                    )
                    
                    FeatureRow(
                        icon: "info.circle",
                        title: "Detailed Analysis",
                        description: "NAV history, returns, and risk metrics"
                    )
                    
                    FeatureRow(
                        icon: "arrow.clockwise",
                        title: "Real-time Data",
                        description: "Latest NAV and performance data"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Data Source")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("api.mfapi.in")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("About")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}