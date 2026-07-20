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
    private(set) var updateAvailable = false
    private(set) var latestVersion: String?

    private let dismissedVersionKey = "dismissedUpdateVersion"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    func check() async {
        let url = Constants.baseURL
            .appending(path: "app/version")
            .appending(queryItems: [URLQueryItem(name: "platform", value: "ios")])

        do {
            let latest: AppVersion = try await Networking.get(url, failType: NoContent.self)
            latestVersion = latest.version
            updateAvailable = shouldPrompt(for: latest.version)
        } catch {
            print("DEBUG: App version check failed: \(error)")
        }
    }

    func dismiss() {
        guard let latestVersion else { return }
        UserDefaults.standard.set(latestVersion, forKey: dismissedVersionKey)
        updateAvailable = false
    }

    private func shouldPrompt(for latest: String) -> Bool {
        guard latest.compare(currentVersion, options: .numeric) == .orderedDescending else {
            return false
        }

        if let dismissed = UserDefaults.standard.string(forKey: dismissedVersionKey),
           latest.compare(dismissed, options: .numeric) != .orderedDescending {
            return false
        }

        return true
    }
}
