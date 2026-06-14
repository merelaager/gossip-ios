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
    
    @State private var showChangePassword = false
    @State private var showDeleteConfirmation = false
    @State private var username = ""
    
    @State private var notificationStatus: UNAuthorizationStatus = .authorized

    @Environment(
        \.scenePhase
    ) private var scenePhase
    
    var body: some View {
        ZStack {
            NavigationStack {
                Form {
                    Section {
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
                    
                    Section {
                        Button(
                            "Vaheta salasõna"
                        ) {
                            showChangePassword
                                .toggle()
                        }
                        .tint(
                            .blue
                        )
                        Button(
                            "Kustuta konto",
                            role: .destructive
                        ) {
                            showDeleteConfirmation = true
                        }
                        .alert(
                            "Kustuta konto?",
                            isPresented: $showDeleteConfirmation
                        ) {
                            TextField(
                                text: $username
                            ) {
                                Text(
                                    "Kasutajanimi"
                                )
                            }
                            Button(
                                "Kustuta konto",
                                role: .destructive
                            ) {
                                Task {
                                    await deleteAccount()
                                }
                            }
                            .disabled(
                                sessionManager.currentUser?.username != username
                            )
                            Button(
                                "Tühista",
                                role: .cancel
                            ) {
                            }
                        } message: {
                            Text(
                                "Konto kustutamiseks sisesta oma kasutajanimi."
                            )
                        }
                        .tint(
                            .blue
                        )
                    } header: {
                        Text(
                            "Konto"
                        )
                    } footer: {
                        Text(
                            "Koos kontoga kustutatakse ka kõik sinu postitused. Sinu kontot ega postitusi taastada ei saa."
                        )
                    }
                    
                    Section {
                        Button(
                            "Logi välja"
                        ) {
                            sessionManager
                                .signOut()
                        }
                        .tint(
                            .blue
                        )
                    } footer: {
                        Text(
                            "Pärast rakendusest väljalogimist pead sa postituste nägemiseks uuesti sisse logima."
                        )
                        .font(
                            .footnote
                        )
                        .foregroundColor(
                            .secondary
                        )
                    }
                    
                    if notificationStatus == .denied || notificationStatus == .notDetermined {
                        Section {
                            Button(
                                "Luba teavitused"
                            ) {
                                Task {
                                    await enableNotifications()
                                }
                            }
                            .tint(
                                .blue
                            )
                        } header: {
                            Text(
                                "Teavitused"
                            )
                        } footer: {
                            if notificationStatus == .denied {
                                Text(
                                    "Teavitused saad sisse lülitada iOS-i seadetes."
                                )
                                .font(
                                    .footnote
                                )
                                .foregroundColor(
                                    .secondary
                                )
                            }
                        }
                    }
                }
                .navigationTitle(
                    "Konto"
                )
            }
        }
        .sheet(
            isPresented: $showChangePassword
        ) {
            NewPasswordView()
        }
        .task {
            await checkNotificationPermissionStatus()
        }
        .onChange(
            of: scenePhase
        ) {
            _,
            newPhase in
            if newPhase == .active {
                Task {
                    await Notifications
                        .ensureRegistered()
                    await checkNotificationPermissionStatus()
                }
            }
        }
    }
    
    func deleteAccount() async {
        if let userId = sessionManager.currentUser?.id {
            Notifications
                .deleteToken(
                    userId: userId
                )
        }
        do {
            try await AccountService
                .deleteAccount()
            sessionManager
                .signOut()
        } catch {
            print(
                "DEBUG: \(error)"
            )
        }
    }
    
    func checkNotificationPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }
    
    func enableNotifications() async {
        switch notificationStatus {
        case .notDetermined:
            await Notifications
                .ensureRegistered()
            await checkNotificationPermissionStatus()
        case .denied:
            if let url = URL(
                string: UIApplication.openNotificationSettingsURLString
            ) {
                await MainActor
                    .run {
                        UIApplication.shared
                            .open(
                                url
                            )
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
        .tint(
            .pink
        )
}
