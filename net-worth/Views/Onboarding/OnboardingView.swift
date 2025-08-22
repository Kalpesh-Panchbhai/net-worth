import SwiftUI

struct OnboardingView: View {
    @State private var isSigningIn = false
    @State private var errorMessage: String? = nil
    @AppStorage("backendUserId") private var backendUserId: Int = -1
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookupStore: LookupStore

    private let auth = AuthManager.shared
    private let client = RestClient()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(LinearGradient.airbnbAccent)
                    Text("Welcome to Net Worth")
                        .font(.title2.weight(.bold))
                    Text("Sign in to sync your data across devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button(action: { Task { await signIn() } }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                            Text(isSigningIn ? "Signing in..." : "Continue with Google")
                                .bold()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(LinearGradient.airbnbAccent))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(isSigningIn)

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Text("By continuing, you agree to the Terms and Privacy Policy.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) { GlobalBannerHost() }
        }
    }

    @MainActor
    private func signIn() async {
        guard !isSigningIn else { return }
        errorMessage = nil
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            let firebaseUID = try await auth.signInWithGoogle()
            let id = try await client.registerFirebaseUser(uid: firebaseUID)
            if id > 0 {
                backendUserId = id
                Haptics.success()
                await lookupStore.loadIfNeeded(userId: id)
            } else {
                errorMessage = "Failed to create or fetch user. Please try again."
                banners.showError(message: errorMessage ?? "")
            }
        } catch {
            errorMessage = (error as NSError).localizedDescription
            banners.showError(message: errorMessage ?? "")
        }
    }
}


