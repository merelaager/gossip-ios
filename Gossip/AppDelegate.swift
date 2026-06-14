//
//  AppDelegate.swift
//  Gossip
//
//

import SwiftUI
import UserNotifications

struct SubmitTokenFailResponseData: Decodable {
    let message: String
}

enum Notifications {
    static func deleteToken(
        userId: String
    ) {
        let cacheKey = "lastSentToken:\(userId)"
        guard let token = UserDefaults.standard.string(
            forKey: cacheKey
        ) else {
            return
        }
        
        let url = Constants.baseURL.appendingPathComponent(
            "apple/tokens/\(token)"
        )
        var request = URLRequest(
            url: url
        )
        request.httpMethod = "DELETE"
        URLSession.shared
            .dataTask(
                with: request
            )
            .resume()
        
        UserDefaults.standard
            .removeObject(
                forKey: cacheKey
            )
    }
    
    static func ensureRegistered() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        
        switch status {
        case .notDetermined:
            let granted = (
                try? await center
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound,
                            .badge
                        ]
                    )
            ) ?? false
            if granted {
                await MainActor
                    .run {
                        UIApplication.shared
                            .registerForRemoteNotifications()
                    }
            }
        case .authorized, .provisional, .ephemeral:
            await MainActor
                .run {
                    UIApplication.shared
                        .registerForRemoteNotifications()
                }
        case .denied:
            break
        @unknown default:
            break
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate,
                   UNUserNotificationCenterDelegate
{
    var app: GossipApp?
    var sessionManager: SessionManager?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter
            .current().delegate = self
        return true
    }
    
    func postDeviceToken(token: String, userId: String) async throws {
        let cacheKey = "lastSentToken:\(userId)"
        if UserDefaults.standard.string(forKey: cacheKey) == token {
            return
        }

        struct Payload: Codable {
            let token: String
            let userId: String
        }

        let payload = Payload(token: token, userId: userId)

        let url = Constants.baseURL.appendingPathComponent("apple/tokens")
        let _: NoContent = try await Networking.post(
            url,
            body: payload,
            failType: SubmitTokenFailResponseData.self
        )

        UserDefaults.standard.set(token, forKey: cacheKey)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let stringifiedToken = deviceToken.map {
            String(format: "%02.2hhx", $0)
        }.joined()

        Task {
            if let userId = sessionManager?.currentUser?.id {
                do {
                    try await postDeviceToken(token: stringifiedToken, userId: userId)
                } catch let error as JSendFailError<SubmitTokenFailResponseData> {
                    print("Token submission failed with client error: \(error.data.message)")
                } catch {
                    print("Unexpected error during token submission: \(error)")
                }
            }
        }
    }
}
