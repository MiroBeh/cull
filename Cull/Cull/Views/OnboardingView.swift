import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @EnvironmentObject var photoService: PhotoLibraryService
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            page(
                symbol: "photo.stack",
                title: "Welcome to Cull",
                subtitle: "Clean up your photo library in minutes, one swipe at a time.",
                tag: 0
            )
            page(
                symbol: "hand.draw",
                title: "Swipe to Decide",
                subtitle: "Swipe right to keep. Swipe left to delete. Tap undo to go back.",
                tag: 1
            )
            startPage.tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }

    private func page(symbol: String, title: String, subtitle: String, tag: Int) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 88))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
        .tag(tag)
    }

    private var startPage: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.green)
            Text("Ready to Cull?")
                .font(.largeTitle.bold())
            Text("Grant access to your photo library to get started.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button("Get Started") {
                Task {
                    _ = await photoService.requestAuthorization()
                    onComplete()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 48)
        }
    }
}
