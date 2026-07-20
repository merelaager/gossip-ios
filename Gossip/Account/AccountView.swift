//
//  AccountView.swift
//  Gossip
//
//

import SwiftUI

struct AccountView: View {
    @Environment(SessionManager.self) private var sessionManager

    @State private var showChangePassword = false
    @State private var showDeleteConfirmation = false
    @State private var username = ""

    var body: some View {
        Form {
            Section {
                Button("Vaheta salasõna") {
                    showChangePassword.toggle()
                }
                .tint(.blue)

                Button("Kustuta konto", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .alert("Kustuta konto?", isPresented: $showDeleteConfirmation) {
                    TextField(text: $username) {
                        Text("Kasutajanimi")
                    }
                    Button("Kustuta konto", role: .destructive) {
                        Task { await deleteAccount() }
                    }
                    .disabled(sessionManager.currentUser?.username != username)
                    Button("Tühista", role: .cancel) {}
                } message: {
                    Text("Konto kustutamiseks sisesta oma kasutajanimi.")
                }
                .tint(.blue)
            } footer: {
                Text("Koos kontoga kustutatakse ka kõik sinu postitused. Sinu kontot ega postitusi taastada ei saa.")
            }

            Section {
                Button("Logi välja") {
                    sessionManager.signOut()
                }
                .tint(.blue)
            } footer: {
                Text("Pärast rakendusest väljalogimist pead sa postituste nägemiseks uuesti sisse logima.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Konto")
        .sheet(isPresented: $showChangePassword) {
            NewPasswordView()
        }
    }

    func deleteAccount() async {
        if let userId = sessionManager.currentUser?.id {
            Notifications.deleteToken(userId: userId)
        }
        do {
            try await AccountService.deleteAccount()
            sessionManager.signOut()
        } catch {
            print("DEBUG: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
            .environment(SessionManager())
            .tint(.pink)
    }
}
