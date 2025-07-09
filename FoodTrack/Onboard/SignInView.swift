//
//  SignInView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 02.07.2025.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isResetAlertShown = false
    @State private var resetAlertMessage = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    @State private var isSigningIn = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.mint.opacity(0.2), .green.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        VStack(spacing: 8) {
                            Text("Welcome Back!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.mint, .green]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Sign in to continue")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 30)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                TextField("e.g. user@example.com", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disabled(isSigningIn)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                HStack {
                                    if isPasswordVisible {
                                        TextField("e.g. password", text: $password)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    } else {
                                        SecureField("e.g. password", text: $password)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    }

                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.mint)
                                    }
                                    .disabled(isSigningIn)
                                }
                            }

                            Button(action: {
                                if email.isEmpty {
                                    resetAlertMessage = "Please enter your email above first."
                                    isResetAlertShown = true
                                } else {
                                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                                        if let error = error {
                                            resetAlertMessage = error.localizedDescription
                                        } else {
                                            resetAlertMessage = "A password reset email has been sent to \(email)."
                                        }
                                        isResetAlertShown = true
                                    }
                                }
                            }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(.mint)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 5)
                            .disabled(isSigningIn)
                        }
                        .padding(.horizontal)

                        Spacer()

                        Button(action: {
                            signIn()
                        }) {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isSigningIn ? "Signing In..." : "Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.mint, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .disabled(isSigningIn)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.mint)
                            .font(.title2)
                    }
                    .disabled(isSigningIn)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Reset Password", isPresented: $isResetAlertShown) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resetAlertMessage)
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    // You can add navigation logic here if needed
                    dismiss()
                }
            } message: {
                Text("Successfully signed in!")
            }
        }
    }

    private func signIn() {
        showAlert = false
        alertMessage = ""
        
        guard !email.isEmpty else {
            alertTitle = "Missing Email"
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }
        guard !password.isEmpty else {
            alertTitle = "Missing Password"
            alertMessage = "Please enter your password."
            showAlert = true
            return
        }
        guard email.contains("@") && email.contains(".") else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }

        isSigningIn = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isSigningIn = false
                
                if let error = error {
                    let errorMessage = getErrorMessage(for: error)
                    alertTitle = "Sign In Failed"
                    alertMessage = errorMessage
                    showAlert = true
                } else if let user = Auth.auth().currentUser {
                    user.reload { reloadError in
                        if let reloadError = reloadError {
                            alertTitle = "Sign In Failed"
                            alertMessage = reloadError.localizedDescription
                            showAlert = true
                            return
                        }
                        if !user.isEmailVerified {
                            try? Auth.auth().signOut()
                            alertTitle = "Email Not Verified"
                            alertMessage = "Please verify your email before signing in. Check your inbox for a verification link."
                            showAlert = true
                        } else {
                            showSuccessAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email address. Please check your email or sign up."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address format."
        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled. Please contact support."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many failed attempts. Please try again later."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection and try again."
        case AuthErrorCode.operationNotAllowed.rawValue:
            return "Email/password sign in is not enabled. Please contact support."
        default:
            return error.localizedDescription
        }
    }
}