//
//  AppView.swift
//  Gossip
//
//

import SwiftUI

struct AppView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.scenePhase) private var scenePhase

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
        .task {
            // Cookie check to avoid displaying
            // the splash screen for non-logged in users.
            sessionManager.checkForCookies()
            await sessionManager.getCurrentUser()
        }
        .onChange(of: sessionManager.appLoadingState) { _, newState in
            if newState == .loggedIn {
                Task { await Notifications.ensureRegistered() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && sessionManager.appLoadingState == .loggedIn {
                Task { await Notifications.ensureRegistered() }
            }
        }
    }
}

#Preview {
    AppView()
        .environment(SessionManager())
}
