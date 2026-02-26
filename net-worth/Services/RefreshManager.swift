import Foundation
import SwiftUI

@MainActor
final class RefreshManager: ObservableObject {
    @Published var isRefreshing = false
    @Published var elapsedSeconds: Double = 0

    private var timerTask: Task<Void, Never>? = nil
    private let client = RestClient()

    func triggerRefresh(banners: BannerCenter) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        elapsedSeconds = 0
        Haptics.softImpact()

        banners.show(
            AppBanner(
                icon: "arrow.trianglehead.2.counterclockwise", title: "Refreshing data…",
                message: "0s elapsed", style: .neutral))

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, self.isRefreshing, !Task.isCancelled else { break }
                self.elapsedSeconds += 1.0
                let secs = Int(self.elapsedSeconds)
                banners.show(
                    AppBanner(
                        icon: "arrow.trianglehead.2.counterclockwise", title: "Refreshing data…",
                        message: "\(secs)s elapsed", style: .neutral))
            }
        }

        do {
            let result = try await client.refreshData()
            timerTask?.cancel()
            timerTask = nil
            isRefreshing = false
            let durationSec = String(format: "%.1f", Double(result.durationMs) / 1000.0)
            Haptics.success()
            banners.showTemporary(
                AppBanner(
                    icon: "checkmark.circle.fill", title: "Data refreshed",
                    message: "Completed in \(durationSec)s", style: .success))
        } catch {
            timerTask?.cancel()
            timerTask = nil
            isRefreshing = false
            Haptics.softImpact()
            let msg = (error as? APIError)?.errorDescription ?? error.localizedDescription
            banners.showTemporary(
                AppBanner(
                    icon: "exclamationmark.triangle.fill", title: "Refresh failed", message: msg,
                    style: .warning))
        }
    }
}
