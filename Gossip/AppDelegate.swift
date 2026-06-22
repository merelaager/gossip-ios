//
//  AppDelegate.swift
//  Gossip
//
//

import SwiftUI
@preconcurrency import UserNotifications

@MainActor
@Observable
class AppDelegate: NSObject, UIApplicationDelegate,
                   @preconcurrency UNUserNotificationCenterDelegate
{
    var app: GossipApp?
    var sessionManager: SessionManager?
    var pendingDestination: NotificationDestination?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let type = response.notification.request.content.userInfo["type"] as? String
        if type == "moderation" {
            Task { @MainActor in
                self.pendingDestination = .moderation
            }
        }
        completionHandler()
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
                await Notifications.handleRegistration(
                    token: stringifiedToken,
                    userId: userId
                )
            }
        }
    }
}
