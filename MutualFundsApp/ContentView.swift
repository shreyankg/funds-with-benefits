import SwiftUI
import UniformTypeIdentifiers

// Temporary inline SettingsView until we add the separate file to Xcode project
struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var holdingsManager = HoldingsManager.shared
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "eye.slash.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Dividend Funds")
                                .font(.headline)
                            Text("Include dividend/IDCW funds in listings and matching")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settings.showDividendFunds)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Fund Display")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When disabled, dividend/IDCW funds are hidden from the funds list and excluded from portfolio matching.")
                        
                        if !settings.showDividendFunds {
                            Text("✓ Dividend funds are currently hidden")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Text("⚠️ All funds including dividend plans are visible")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upload Holdings File")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Import your portfolio from PDF or CSV")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Portfolio Management")
                } footer: {
                    Text("Upload your holdings statement to track your portfolio and get comprehensive analytics.")
                }
                
            }
            .sheet(isPresented: $showingFilePicker) {
                FilePickerView { url in
                    Task {
                        await holdingsManager.uploadHoldingsFile(from: url)
                    }
                }
            }
            .alert("Error", isPresented: .constant(holdingsManager.errorMessage != nil)) {
                Button("OK") {
                    holdingsManager.clearError()
                }
            } message: {
                Text(holdingsManager.errorMessage ?? "")
            }
            .navigationBarHidden(true)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            FundsListView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Funds")
                }
            
            HoldingsView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Portfolio")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
            
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
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
            .navigationBarHidden(true)
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