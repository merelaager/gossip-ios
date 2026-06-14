//
//  LoginView.swift
//  Gossip
//
//

import SwiftUI
import Combine

struct SignUpSheetData {
    var showSheet = false
    var givenUsername: String?
}

struct LoginView: View {
    @Environment(SessionManager.self) private var sessionManager
    
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    @State private var displayTokenPrompt = false
    @State private var token = ""
    @State var sheetData = SignUpSheetData()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Merelaagri gossip")
                    .font(.title)
                    .padding(.bottom, 4)
                
                Text("Logi sisse")
                    .padding(.bottom)
                
                VStack(spacing: 0) {
                    TextField("Kasutajanimi", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    Divider()
                        .padding(.leading, 16)
                    SecureField("Parool", text: $password)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: .rect(cornerRadius: 22, style: .continuous)
                )
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.bottom, 0)
                }
                
                Button {
                    Task {
                        await signIn()
                    }
                } label: {
                    Text("Logi sisse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!formIsValid)
                .padding(.horizontal)
                .padding(.vertical)
                
                Button {
                    displayTokenPrompt = true
                } label: {
                    HStack(spacing: 3) {
                        Text("Pole kontot?")
                        Text("Loo konto.")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color(.systemGray))
                    .font(.subheadline)
                }
                
                Spacer()
            }
        }
        .tint(.pink)
        .alert("Kutse", isPresented: $displayTokenPrompt) {
            TextField(text: $token) {
                Text("Kutsekood")
            }
            .textInputAutocapitalization(.never)
            .onChange(of: token) { oldValue, newValue in
                let isDeleting = newValue.count < oldValue.count
                var uppercased = newValue.uppercased()
                
                if uppercased.count > 9 {
                    uppercased = String(uppercased.prefix(9))
                }

                if uppercased.count == 4 && !isDeleting {
                    uppercased.append("-")
                }

                if token != uppercased {
                    token = uppercased
                }
            }
            Button("Tühista", role: .cancel) {
                errorMessage = nil
            }
            Button("Jätka") {
                Task {
                    errorMessage = nil
                    await checkToken()
                }
            }
            .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).count != 9)
        } message: {
            Text("Sisesta konto loomiseks vajalik kutsekood, mille said kasvatajatelt.")
        }
        .tint(.blue)
        .sheet(isPresented: $sheetData.showSheet) { [sheetData] in
            SignupView(token: token, givenUsername: sheetData.givenUsername)
        }
        .tint(.pink)
    }
}

private extension LoginView {
    func signIn() async {
        do {
            try await sessionManager.login(username: username, password: password)
        } catch let error as JSendFailError<LoginFailResponseData> {
            errorMessage = error.data.message
            token = ""
        } catch {
            print("DEBUG: \(error)")
            errorMessage = "Viga serveriga ühenduse loomisel."
            token = ""
        }
    }
    
    func checkToken() async {
        do {
            let tokenStatus = try await SignupService.fetchTokenStatus(token: token)
            sheetData.givenUsername = tokenStatus.username
            sheetData.showSheet = true
            return
        } catch let error as JSendFailError<TokenStatusFailData> {
            print("DEBUG: \(error)")
            errorMessage = error.data.message
        } catch {
            print("DEBUG: \(error)")
            errorMessage = "Viga serveriga ühenduse loomisel."
        }
        sheetData.givenUsername = nil
        sheetData.showSheet = false
    }
    
    var formIsValid: Bool {
        return !username.isEmpty && !password.isEmpty
    }
}

#Preview {
    LoginView()
        .environment(SessionManager())
        .tint(.pink)
}
