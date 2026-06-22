//
//  Notifications.swift
//  Gossip
//
//

import Foundation
import UIKit
import UserNotifications

struct SubmitTokenFailResponseData: Decodable {
    let message: String
}

enum NotificationDestination: Sendable {
    case moderation
}

enum Notifications {
    static func currentStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    static func clearDelivered() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        Task { try? await center.setBadgeCount(0) }
    }

    static func ensureRegistered() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )) ?? false
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        case .denied:
            break
        @unknown default:
            break
        }
    }

    static func handleRegistration(token: String, userId: String) async {
        do {
            try await postDeviceToken(token: token, userId: userId)
        } catch let error as JSendFailError<SubmitTokenFailResponseData> {
            print("Token submission failed with client error: \(error.data.message)")
        } catch {
            print("Unexpected error during token submission: \(error)")
        }
    }

    static func deleteToken(userId: String) {
        let cacheKey = "lastSentToken:\(userId)"
        guard let token = UserDefaults.standard.string(forKey: cacheKey) else {
            return
        }

        let url = Constants.baseURL.appendingPathComponent("apple/tokens/\(token)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // Explicitly set cookies to avoid the race condition with cookie clearing
        // when the user signs out.
        request.httpShouldHandleCookies = false
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        URLSession.shared.dataTask(with: request).resume()

        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    private static func postDeviceToken(token: String, userId: String) async throws {
        let cacheKey = "lastSentToken:\(userId)"
        if UserDefaults.standard.string(forKey: cacheKey) == token {
            return
        }

        struct Payload: Codable {
            let token: String
            let userId: String
        }

        let url = Constants.baseURL.appendingPathComponent("apple/tokens")
        let _: NoContent = try await Networking.post(
            url,
            body: Payload(token: token, userId: userId),
            failType: SubmitTokenFailResponseData.self
        )

        UserDefaults.standard.set(token, forKey: cacheKey)
    }
}
