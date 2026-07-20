//
//  SettingsView.swift
//  Gossip
//
//

import SwiftUI
@preconcurrency import UserNotifications

struct SettingsView: View {
    @Environment(
        SessionManager.self
    ) private var sessionManager

    @Environment(AppUpdateModel.self) private var updateModel

    @State private var notificationStatus: UNAuthorizationStatus?

    @Environment(
        \.scenePhase
    ) private var scenePhase
    
    var body: some View {
        ZStack {
            NavigationStack {
                Form {
                    Section {
                        NavigationLink {
                            AccountView()
                        } label: {
                            VStack(
                                alignment: .leading
                            ) {
                                Text(
                                    sessionManager.currentUser?.username
                                    ?? "Anonüümne kasutaja"
                                )
                                if sessionManager.currentUser?.role != "READER" {
                                    Text(
                                        "Postitamine lubatud"
                                    )
                                    .font(
                                        .footnote
                                    )
                                } else {
                                    Text(
                                        "Postitamine keelatud"
                                    )
                                    .font(
                                        .footnote
                                    )
                                }
                            }
                        }
                    } footer: {
                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {
                            if sessionManager.currentUser?.role == "READER" {
                                VStack(
                                    alignment: .leading,
                                    spacing: 8
                                ) {
                                    Text(
                                        "Eesti Vabariigi seaduse järgi ei tohi alla 13-aastased lapsed ilma vanema nõusolekuta oma (isiku)andmeid digikeskkonnas jagada."
                                    )
                                    Text(
                                        "Kuna meil puudub sinu vanemate nõusolek, ei saa me lubada sul postitada, et sa kogemata isikustavat infot ei jagaks."
                                    )
                                }
                            }
                            
                            Link(
                                destination: URL(
                                    string:
                                        "https://gossip.merelaager.ee/privaatsuspoliitika"
                                )!
                            ) {
                                HStack(
                                    spacing: 4
                                ) {
                                    Text(
                                        "Privaatsuspoliitika"
                                    )
                                    Image(
                                        systemName: "arrow.up.right.square"
                                    )
                                }
                                .font(
                                    .footnote
                                )
                                .foregroundColor(
                                    .blue
                                )
                            }
                        }
                    }
                    
                    if let notificationStatus {
                        Section {
                            if notificationStatus == .denied || notificationStatus == .notDetermined {
                                Button("Luba teavitused") {
                                    Task { await enableNotifications() }
                                }
                                .tint(.blue)
                            } else {
                                Button("Taasta teavitused") {
                                    Task { await restoreNotifications() }
                                }
                                .tint(.blue)
                            }
                        } header: {
                            Text("Teavitused")
                        } footer: {
                            if notificationStatus == .denied {
                                Text("Teavitused saad sisse lülitada iOS-i seadetes.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else if notificationStatus != .notDetermined {
                                Text("Aitab siis, kui sulle teavitused kohale ei jõua.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section {
                        LabeledContent("Versioon", value: updateModel.currentVersion)
                    } footer: {
                        if updateModel.isUpdateAvailable, let latest = updateModel.latestVersion {
                            Link(destination: Constants.appStoreURL) {
                                HStack(spacing: 4) {
                                    Text("Saadaval on uus versioon (\(latest))")
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .font(.footnote)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .navigationTitle(
                    "Sätted"
                )
            }
        }
        .task {
            notificationStatus = await Notifications.currentStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    notificationStatus = await Notifications.currentStatus()
                }
            }
        }
    }
    
    func restoreNotifications() async {
        guard let userId = sessionManager.currentUser?.id else { return }
        await Notifications.resyncToken(userId: userId)
    }

    func enableNotifications() async {
        switch notificationStatus {
        case .notDetermined:
            await Notifications.ensureRegistered()
            notificationStatus = await Notifications.currentStatus()
        case .denied:
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        default:
            break
        }
    }
}

#Preview {
    SettingsView()
        .environment(
            SessionManager()
        )
        .environment(AppUpdateModel())
        .tint(
            .pink
        )
}
