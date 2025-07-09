//
//  GoogleSignUpView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 09.07.2025.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore

struct GoogleSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isSigningUp") private var isSigningUp: Bool = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var nickname = ""
    @State private var needsNickname = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                VStack(spacing: 20) {
                    Image("google_icon") // Use your Google icon asset name here
                        .resizable()
                        .frame(width: 80, height: 80)
                    Text("Sign Up with Google")
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
                            saveGoogleUser(nickname: nickname)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(nickname.isEmpty)
                    }
                    .padding()
                } else {
                    GoogleSignInButton(action: handleGoogleSignIn)
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
            .alert("Google Sign Up", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    func handleGoogleSignIn() {
        isLoading = true
        isSigningUp = true
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            alertMessage = "Missing Google client ID."
            showAlert = true
            isLoading = false
            isSigningUp = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            alertMessage = "No root view controller."
            showAlert = true
            isLoading = false
            isSigningUp = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                isLoading = false
                isSigningUp = false
                return
            }
            guard
                let user = signInResult?.user,
                let email = user.profile?.email,
                let idToken = user.idToken?.tokenString
            else {
                alertMessage = "Google authentication failed (missing token)."
                showAlert = true
                isLoading = false
                isSigningUp = false
                return
            }
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
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

    func saveGoogleUser(nickname: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "nickname": nickname,
            "email": user.email ?? "",
            "createdAt": Timestamp()
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
