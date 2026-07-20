//
//  AppView.swift
//  Gossip
//
//

import SwiftUI

struct AppView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var updateModel = AppUpdateModel()

    var body: some View {
        Group {
            switch sessionManager.appLoadingState {
            case .loading:
                SplashView()
            case .loggedIn:
                ContentView()
            case .loggedOut:
                LoginView()
            }
        }
        .environment(updateModel)
        .safeAreaInset(edge: .top) {
            if updateModel.bannerVisible, sessionManager.appLoadingState != .loading {
                UpdateBanner(onDismiss: updateModel.dismissBanner)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: updateModel.bannerVisible)
        .task {
            // Cookie check to avoid displaying
            // the splash screen for non-logged in users.
            sessionManager.checkForCookies()
            await sessionManager.getCurrentUser()
        }
        .task {
            await updateModel.check()
        }
        .onChange(of: sessionManager.appLoadingState) { _, newState in
            if newState == .loggedIn {
                Task { await Notifications.ensureRegistered() }
            }
        }
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            if newPhase == .active {
                Notifications.clearDelivered()
                if sessionManager.appLoadingState == .loggedIn {
                    Task { await Notifications.ensureRegistered() }
                }
            }
        }
    }
}

#Preview {
    AppView()
        .environment(SessionManager())
}
