//
//  SignUp.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 03.06.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isSigningUp") private var isSigningUp: Bool = false
    @State private var showTermsSheet = false
    @State private var nickname = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    @State private var isCreatingAccount = false
    @State private var showVerifyPrompt = false
    @State private var showVerifySent = false

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
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.mint, .green]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Join VirtualFridge today!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 30)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nickname")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                TextField("e.g. FoodLover, ChefJohn, etc.", text: $nickname)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.nickname)
                                    .disabled(isCreatingAccount)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                TextField("e.g. user@example.com", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disabled(isCreatingAccount)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                HStack {
                                    if isPasswordVisible {
                                        TextField("e.g. SecurePassword", text: $password)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    } else {
                                        SecureField("e.g. SecurePassword", text: $password)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    }

                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.mint)
                                    }
                                    .disabled(isCreatingAccount)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                HStack {
                                    if isConfirmPasswordVisible {
                                        TextField("e.g.SecurePassword", text: $confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    } else {
                                        SecureField("e.g. SecurePassword", text: $confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    }

                                    Button(action: { isConfirmPasswordVisible.toggle() }) {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.mint)
                                    }
                                    .disabled(isCreatingAccount)
                                }
                            }
                        }
                        .padding(.horizontal)

                        HStack(spacing: 4) {
                            Text("By signing up, you agree to our")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            Button(action: {
                                showTermsSheet = true
                            }) {
                                Text("Terms & Conditions")
                                    .font(.footnote)
                                    .foregroundColor(.mint)
                            }
                            .disabled(isCreatingAccount)
                        }
                        .padding(.top, 10)

                        Button(action: {
                            validateAndPromptVerification()
                        }) {
                            HStack {
                                if isCreatingAccount {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isCreatingAccount ? "Creating Account..." : "Create Account")
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
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        .disabled(isCreatingAccount)
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
                    .disabled(isCreatingAccount)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Verify Your Email", isPresented: $showVerifyPrompt) {
                Button("OK", role: .cancel) {
                    actuallyCreateAccount()
                }
            } message: {
                Text("We will send a verification link to your email. Please verify your email before signing in.")
            }
            .alert("Verification Email Sent", isPresented: $showVerifySent) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Account created! Please check your email for the verification link before signing in.")
            }
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsAndPrivacyView()
        }
    }
    
    private func validateAndPromptVerification() {
        showAlert = false
        alertMessage = ""
        
        guard !nickname.isEmpty else {
            alertTitle = "Missing Nickname"
            alertMessage = "Please enter a nickname for your account."
            showAlert = true
            return
        }
        guard !email.isEmpty else {
            alertTitle = "Missing Email"
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }
        guard !password.isEmpty else {
            alertTitle = "Missing Password"
            alertMessage = "Please enter a password."
            showAlert = true
            return
        }
        guard password == confirmPassword else {
            alertTitle = "Passwords Don't Match"
            alertMessage = "Please make sure your passwords match."
            showAlert = true
            return
        }
        guard password.count >= 6 else {
            alertTitle = "Password Too Short"
            alertMessage = "Password must be at least 6 characters long."
            showAlert = true
            return
        }
        guard email.contains("@") && email.contains(".") else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        // If all validation passes, show the verification prompt
        isSigningUp = true
        showVerifyPrompt = true
    }
    
    private func actuallyCreateAccount() {
        isCreatingAccount = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    isCreatingAccount = false
                    isSigningUp = false
                    let errorMessage = getErrorMessage(for: error)
                    alertTitle = "Account Creation Failed"
                    alertMessage = errorMessage
                    showAlert = true
                    return
                }

                guard let user = result?.user else {
                    isCreatingAccount = false
                    isSigningUp = false
                    return
                }

                // Save nickname to Firestore before sign out
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "nickname": nickname,
                    "email": email,
                    "createdAt": Timestamp()
                ]
                db.collection("users").document(user.uid).setData(userData, merge: true) { firestoreError in
                    if let firestoreError = firestoreError {
                        isCreatingAccount = false
                        isSigningUp = false
                        alertTitle = "Firestore Error"
                        alertMessage = "Failed to save user info: \(firestoreError.localizedDescription)"
                        showAlert = true
                        // Still proceed to sign out and send verification
                    }

                    // Sign out immediately after saving user info
                    try? Auth.auth().signOut()

                    // Send verification email
                    user.sendEmailVerification { error in
                        isCreatingAccount = false
                        isSigningUp = false
                        if let error = error {
                            alertTitle = "Verification Failed"
                            alertMessage = "Could not send verification email: \(error.localizedDescription)"
                            showAlert = true
                        } else {
                            showVerifySent = true
                        }
                    }
                }
            }
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists. Please sign in instead."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address format."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Please choose a stronger password."
        case AuthErrorCode.operationNotAllowed.rawValue:
            return "Email/password sign up is not enabled. Please contact support."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection and try again."
        default:
            return error.localizedDescription
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TermsAndPrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms & Conditions")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("""
Welcome to VirtualFridge! By using our app, you agree to the following terms:

1. **Account Responsibility:** You are responsible for maintaining the confidentiality of your account and password.
2. **Usage Limitations:** Do not misuse our services. Use the app only as intended.
3. **Content Ownership:** You retain ownership of your content, but we may use anonymized data to improve our services.
4. **Prohibited Activities:** You must not upload harmful, illegal, or abusive content.

We reserve the right to suspend your account if you violate any of these terms.
""")

                    Text("Privacy Policy")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)

                    Text("""
We respect your privacy. Here's how we handle your data:

1. **Data Collection:** We collect your nickname, email, and product usage to improve your experience.
2. **Data Usage:** Your data is used only to provide and improve VirtualFridge services.
3. **No Third-Party Sharing:** We do not sell or share your data with third parties.
4. **Data Security:** We use Firebase services to securely store and protect your information.

You may request deletion of your account and associated data at any time.
""")

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

