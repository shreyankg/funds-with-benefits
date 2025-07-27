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
            ScrollView {
                VStack(spacing: 30) {
                    // App Logo and Branding
                    VStack(spacing: 16) {
                        if let logoImage = UIImage(named: "app_logo") {
                            Image(uiImage: logoImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        } else {
                            // Fallback
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 30, weight: .light))
                                        .foregroundColor(.white)
                                }
                        }
                        
                        VStack(spacing: 8) {
                            Text("Funds with Benefits")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Empowering your investment journey with intelligent insights and benefits")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(
                                icon: "magnifyingglass.circle.fill",
                                title: "Smart Search & Filter",
                                description: "Find funds by name, code, category, or fund house with real-time filtering"
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis.circle.fill",
                                title: "Interactive Performance Charts",
                                description: "Beautiful charts with 1W, 1M, 6M, 1Y, and 3Y timeframes"
                            )
                            
                            FeatureRow(
                                icon: "info.circle.fill",
                                title: "Comprehensive Analysis",
                                description: "NAV history, total returns, CAGR, volatility, and risk metrics"
                            )
                            
                            FeatureRow(
                                icon: "arrow.clockwise.circle.fill",
                                title: "Real-time Data",
                                description: "Latest NAV values and daily performance updates from MF API"
                            )
                            
                            FeatureRow(
                                icon: "icloud.circle.fill",
                                title: "Offline Capability",
                                description: "Smart caching for seamless experience even without internet"
                            )
                            
                            FeatureRow(
                                icon: "heart.circle.fill",
                                title: "Investment Benefits",
                                description: "Intelligent insights to help you make better investment decisions"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Version and Credits
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Text("App Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Version:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("0.0.1")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("iOS Requirement:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("17.0+")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Data Source:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("api.mfapi.in")
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.subheadline)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
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