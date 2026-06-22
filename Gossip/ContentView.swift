//
//  ContentView.swift
//  Gossip
//
//

import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AppDelegate.self) private var appDelegate

    @State private var selectedTab: String = "feed"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Kõlakad", systemImage: "bubble", value: "feed") {
                PostsView(title: "Kõlakad", viewModel: PostsViewModel(endpoint: ""))
            }
            Tab("Kõva kumu", systemImage: "heart", value: "liked") {
                PostsView(title: "Kõva kumu", viewModel: PostsViewModel(endpoint: "/liked"))
            }
            if (sessionManager.currentUser?.role != "READER") {
                Tab("Minu", systemImage: "rectangle.stack.badge.person.crop", value: "my") {
                    PostsView(title: "Minu postitused", viewModel: PostsViewModel(endpoint: "/my"))
                }
            }
            if (sessionManager.currentUser?.role == "ADMIN") {
                Tab("Ootel", systemImage: "document.badge.clock", value: "moderation") {
                    PostsView(title: "Ootel", viewModel: PostsViewModel(endpoint: "/waitlist"))
                }
            }
            Tab("Konto", systemImage: "person.crop.circle", value: "account") {
                SettingsView()
            }
        }
        .tint(.pink)
        .onChange(of: appDelegate.pendingDestination, initial: true) { _, new in
            if new == .moderation {
                selectedTab = "moderation"
                appDelegate.pendingDestination = nil
            }
        }
    }
}

#Preview {
    let sessionManager = SessionManager()
    ContentView()
        .environment(sessionManager)
        .task { await sessionManager.getCurrentUser() }
}
