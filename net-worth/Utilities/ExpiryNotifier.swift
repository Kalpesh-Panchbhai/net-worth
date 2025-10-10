import Foundation
import UserNotifications

final class ExpiryNotifier {
    static let shared = ExpiryNotifier()
    private init() {}

    private let oneDayId = "expiry-1d"
    private let oneHourId = "expiry-1h"
    private let firstInstallKey = "firstInstallDate"

    // Public entry point
    func setupExpiryNotifications() {
        requestNotificationPermission()
        // Prefer: provisioning profile (MobileProvision) -> executable creation + 7 days -> first-install + 7 days
        let expiry =
            MobileProvision.read()?.expirationDate
            ?? estimatedExpiryFromBundle()
            ?? fallbackExpiry()
        scheduleExpiryNotifications(expirationDate: expiry)
    }

    // MARK: - Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
        }
    }

    // MARK: - Expiration Date

    private func provisioningExpirationDate() -> Date? {
        // Keep for compatibility, but prefer MobileProvision.read() above
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
            let data = try? Data(contentsOf: url),
            let ascii = String(data: data, encoding: .ascii)
        else { return nil }
        guard let plistStartRange = ascii.range(of: "<plist"),
            let plistEndRange = ascii.range(of: "</plist>")
        else { return nil }
        let plistString = String(ascii[plistStartRange.lowerBound...plistEndRange.upperBound])
        guard let plistData = plistString.data(using: .utf8) else { return nil }
        var format = PropertyListSerialization.PropertyListFormat.xml
        let dict =
            try? PropertyListSerialization.propertyList(
                from: plistData, options: [], format: &format) as? [String: Any]
        return dict?["ExpirationDate"] as? Date
    }

    private func estimatedExpiryFromBundle() -> Date? {
        if let executablePath = Bundle.main.executablePath,
            let attributes = try? FileManager.default.attributesOfItem(atPath: executablePath),
            let creationDate = attributes[.creationDate] as? Date
        {
            return Calendar.current.date(byAdding: .day, value: 7, to: creationDate)
        }
        return nil
    }

    private func fallbackExpiry() -> Date {
        let defaults = UserDefaults.standard
        if let stored = defaults.object(forKey: firstInstallKey) as? Date {
            return Calendar.current.date(byAdding: .day, value: 7, to: stored)
                ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        } else {
            let now = Date()
            defaults.set(now, forKey: firstInstallKey)
            return Calendar.current.date(byAdding: .day, value: 7, to: now)
                ?? now.addingTimeInterval(7 * 24 * 60 * 60)
        }
    }

    // MARK: - Scheduling
    private func scheduleExpiryNotifications(expirationDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [oneDayId, oneHourId])

        // Compute fire times
        let oneDayBefore = expirationDate.addingTimeInterval(-24 * 60 * 60)
        let oneHourBefore = expirationDate.addingTimeInterval(-60 * 60)

        func schedule(id: String, title: String, body: String, fireAt: Date) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: fireAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request) { error in
            }
        }

        schedule(
            id: oneDayId,
            title: "App expires tomorrow",
            body: "Your build will expire in 24 hours. Please re-install a fresh build.",
            fireAt: oneDayBefore)

        schedule(
            id: oneHourId,
            title: "App expires in 1 hour",
            body: "Your build will expire in 1 hour. Re-install to continue using the app.",
            fireAt: oneHourBefore)
    }
}
