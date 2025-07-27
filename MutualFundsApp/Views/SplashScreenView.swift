import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // More sober background
                LinearGradient(
                    colors: [Color.gray.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo
                    if let logoImage = UIImage(named: "app_logo") {
                        Image(uiImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    } else {
                        // Fallback with more sober colors
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(
                                colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }
                    
                    // App Name and Tagline - Center Justified
                    VStack(spacing: 8) {
                        Text("Funds with Benefits")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(textOpacity)
                        
                        Text("Empowering your investment journey")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(textOpacity)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    // Loading indicator with sober styling
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(1.2)
                        
                        Text("Loading mutual funds data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(textOpacity)
                    .padding(.bottom, 50)
                }
                .padding(.horizontal, 40)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
                    textOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}