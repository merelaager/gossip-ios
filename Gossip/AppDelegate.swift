//
//  AppDelegate.swift
//  Gossip
//
//

import SwiftUI
import UserNotifications

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
        UNUserNotificationCenter.current().delegate = self
        return true
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
