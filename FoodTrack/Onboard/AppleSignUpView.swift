//
//  AppleSignUpView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 09.07.2025.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

struct AppleSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isSigningUp") private var isSigningUp: Bool = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var nickname = ""
    @State private var needsNickname = false
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 80))
                        .foregroundColor(.black)
                    Text("Sign Up with Apple")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if needsNickname {
                    VStack(spacing: 16) {
                        Text("Choose a Nickname")
                            .font(.headline)
                        TextField("Nickname", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                        Button("Continue") {
                            saveAppleUser(nickname: nickname)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(nickname.isEmpty)
                    }
                    .padding()
                } else {
                    SignInWithAppleButton(
                        .signUp,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
            }
            .alert("Apple Sign Up", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        isSigningUp = true
        switch result {
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
            isLoading = false
            isSigningUp = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                alertMessage = "Apple authentication failed."
                showAlert = true
                isLoading = false
                isSigningUp = false
                return
            }
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isLoading = false
                    isSigningUp = false
                    return
                }
                // Check if user doc exists
                let db = Firestore.firestore()
                let uid = result?.user.uid ?? ""
                let userDoc = db.collection("users").document(uid)
                userDoc.getDocument { doc, _ in
                    if let doc = doc, doc.exists {
                        // Already has nickname, done!
                        isLoading = false
                        isSigningUp = false
                        dismiss()
                    } else {
                        // Prompt for nickname
                        needsNickname = true
                        isLoading = false
                    }
                }
            }
        }
    }

    func saveAppleUser(nickname: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        // Get user's email (Apple might not provide it on subsequent sign-ins)
        let userEmail = user.email ?? ""
        
        // Store provider information and user data
        let userData: [String: Any] = [
            "nickname": nickname,
            "email": userEmail,
            "createdAt": Timestamp(),
            "provider": "apple.com",
            "hasPassword": false,
            "notificationFrequency": "Every 12 Hours",
            "intervalHours": 12,
            "updatedAt": Date().timeIntervalSince1970 * 1000
        ]
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            isSigningUp = false
            if let error = error {
                alertMessage = "Failed to save user: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Nonce Utilities

import CryptoKit

func randomNonceString(length: Int = 32) -> String {
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0..<16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
} 
