import SwiftUI

@main
struct MyRadioApp: App {
    @State private var splashDone = false

    var body: some Scene {
        WindowGroup {
            if splashDone {
                ContentView()
            } else {
                SplashView(onContinue: { splashDone = true })
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "radio")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("Моето радио")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("версия \(appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button(action: onContinue) {
                    Text("Продължи")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    SplashView(onContinue: {})
}
