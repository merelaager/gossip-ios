//
//  SessionManager.swift
//  Gossip
//
//

import Foundation

typealias LoginResponse = JSendResponse<UserData>

struct LoginReqBody: Codable {
    let username: String
    let password: String
}

struct SignupReqBody: Codable {
    let token: String
    let username: String
    let password: String
}

struct LoginFailResponseData: Decodable {
    let message: String
}

struct SignupFailResponseData: Decodable {
    let message: String
}

struct UserData: Decodable {
    let username: String
    let role: String
}

struct User: Identifiable, Decodable, Encodable {
    let id: String
    let username: String
    let role: String
}

enum AppAuthState {
    case loading
    case loggedIn
    case loggedOut
}

@MainActor
@Observable
class SessionManager {
    var currentUser: User?
    var appLoadingState: AppAuthState = .loading
    
    init() {
        if let cachedUser = self.loadPersistedUser() {
            currentUser = cachedUser
        }
    }
    
    // This is useful to avoid displaying the splash screen when the user
    // is certainly logged out.
    func checkForCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies where !cookie.isExpired {
                if cookie.name == "sessionId" {
                    return
                }
            }
        }
        appLoadingState = .loggedOut
    }
    
    func persistUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    func loadPersistedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(User.self, from: data)
        else {
            return nil
        }
        return user
    }

    func getCurrentUser(override: Bool = false) async {
        // We need an override, since this is also used to check for session state after login/signup.
        if (!override && appLoadingState == .loggedOut) {
            return
        }

        let url = Constants.baseURL.appendingPathComponent("account")

        do {
            let user: User = try await Networking.get(url, failType: NoContent.self)
            currentUser = user
            appLoadingState = .loggedIn
            persistUser(user)
            return
        } catch let error as JSendFailError<NoContent> where error.statusCode == 401 {
            currentUser = nil
            UserDefaults.standard.removeObject(forKey: "currentUser")
        } catch {
            print("DEBUG: Request failed: \(error)")
        }
        appLoadingState = .loggedOut
    }

    func login(username: String, password: String) async throws {
        let url = Constants.baseURL.appendingPathComponent("auth/login")
        let body = LoginReqBody(username: username, password: password)
        let _: NoContent = try await Networking.post(
            url,
            body: body,
            failType: LoginFailResponseData.self
        )
        await getCurrentUser(override: true)
    }

    func signUp(token: String, username: String, password: String) async throws
    {
        let url = Constants.baseURL.appendingPathComponent("users")
        let body = SignupReqBody(
            token: token,
            username: username,
            password: password
        )
        let _: NoContent = try await Networking.post(
            url,
            body: body,
            failType: SignupFailResponseData.self
        )
        await getCurrentUser(override: true)
    }

    func signOut() {
        if let userId = currentUser?.id {
            Notifications.deleteToken(userId: userId)
        }

        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.cookies?.forEach { cookie in
            cookieStorage.deleteCookie(cookie)
        }

        currentUser = nil
        appLoadingState = .loggedOut
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

extension HTTPCookie {
    var isExpired: Bool {
        guard let expiresDate = self.expiresDate else { return false }
        return expiresDate < Date()
    }
}
