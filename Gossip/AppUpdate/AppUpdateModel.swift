//
//  AppUpdateModel.swift
//  Gossip
//
//

import Foundation

struct AppVersion: Decodable {
    let version: String
}

@MainActor
@Observable
final class AppUpdateModel {
    private(set) var latestVersion: String?
    private(set) var bannerDismissed = false

    private let dismissedVersionKey = "dismissedUpdateVersion"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    var isUpdateAvailable: Bool {
        guard let latestVersion else { return false }
        return latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    var bannerVisible: Bool {
        isUpdateAvailable && !bannerDismissed
    }

    func check() async {
        let url = Constants.baseURL
            .appending(path: "app/version")
            .appending(queryItems: [URLQueryItem(name: "platform", value: "ios")])

        do {
            let latest: AppVersion = try await Networking.get(url, failType: NoContent.self)
            latestVersion = latest.version
            bannerDismissed = wasDismissed(latest.version)
        } catch {
            print("DEBUG: App version check failed: \(error)")
        }
    }

    func dismissBanner() {
        guard let latestVersion else { return }
        UserDefaults.standard.set(latestVersion, forKey: dismissedVersionKey)
        bannerDismissed = true
    }

    private func wasDismissed(_ version: String) -> Bool {
        guard let dismissed = UserDefaults.standard.string(forKey: dismissedVersionKey) else {
            return false
        }
        return version.compare(dismissed, options: .numeric) != .orderedDescending
    }
}
