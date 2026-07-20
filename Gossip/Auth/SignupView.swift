//
//  SignupView.swift
//  Gossip
//
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionManager.self) private var sessionManager

    let token: String
    let givenUsername: String?

    @State private var username = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.pink)

                        Text("Loo konto")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Gossipi nägemiseks ja postitamiseks on vajalik konto. Sinu kasutajat näevad ainult kasvatajad.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .listRowBackground(Color.clear)
                }

                Section {
                    if let gu = givenUsername {
                        LabeledContent("Kasutajanimi", value: gu)
                    } else {
                        TextField("Kasutajanimi", text: $username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                } footer: {
                    if givenUsername != nil {
                        Text("Sa ei saa oma kasutajanime valida, kuna su konto peab olema anonüümne. Jäta see kasutajanimi meelde.")
                    } else {
                        Text("Kasutajanimi tohib sisaldada ainult ladina tähestiku tähti, numbreid, punkte ja allkriipse.")
                    }
                }

                Section {
                    SecureField("Salasõna", text: $password)
                    SecureField("Korda salasõna", text: $passwordConfirm)
                } footer: {
                    Text("Salasõna peab olema vähemalt 8 tähemärki pikk.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await signUp() }
                    } label: {
                        Text("Loo konto")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(password.count < 8 || password != passwordConfirm)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            dismiss()
                        }
                    } else {
                        Button("Tühista") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private extension SignupView {
    func signUp() async {
        do {
            if let gu = givenUsername {
                username = gu
            }
            try await sessionManager.signUp(token: token, username: username, password: password)
            dismiss()
            return
        } catch let error as JSendFailError<SignupFailResponseData> {
            print("DEBUG: \(error)")
            errorMessage = error.data.message
        } catch {
            print("DEBUG: \(error)")
            errorMessage = "Viga serveriga ühenduse loomisel."
        }
    }
}

#Preview {
    SignupView(token: "TOKEN", givenUsername: "anonymouse")
        .environment(SessionManager())
        .tint(.pink)
}
