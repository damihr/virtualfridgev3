//
//  Profile.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 10.06.2025.
//
/*
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import FirebaseCore

enum NotificationFrequency: String, CaseIterable, Identifiable {
    case none = "No Notifications"
    case every12Hours = "Every 12 Hours"
    case every24Hours = "Every 24 Hours"
    case everyWeek = "Every Week"

    var id: String { self.rawValue }

    var intervalHours: Int {
        switch self {
        case .none: return 0
        case .every12Hours: return 12
        case .every24Hours: return 24
        case .everyWeek: return 24 * 7
        }
    }
}

enum PasswordSheetState {
    case passwordInput
    case changePassword
    case forgotPassword
    case googleReauth
    case appleReauth
    case emailReauth
}

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager
    @State private var user: User? = Auth.auth().currentUser
    @State private var nickname: String = ""
    @State private var isEditingNickname = false
    @FocusState private var nicknameFieldFocused: Bool
    @State private var deleteError: String?
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @State private var selectedFrequency: NotificationFrequency = .every12Hours
    @State private var notificationsAllowed = true
    @State private var nicknameFeedbackMessage: String?

    @State private var showPasswordSuccessAlert = false

    @State private var showDeletePasswordPrompt = false
    @State private var deletePassword = ""
    @State private var showFinalDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showDeleteSuccessAlert = false
    @State private var isPasswordUser: Bool = false
    @State private var isGoogleUser: Bool = false
    @State private var isAppleUser: Bool = false
    @State private var showGoogleReauthSheet = false
    @State private var showAppleReauthSheet = false
    @State private var isGoogleReauthenticating = false
    @State private var showSignOutAlert = false
    @State private var showSetPasswordSheet = false
    @State private var newPasswordForLink = ""
    @State private var confirmPasswordForLink = ""
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var setPasswordError: String?
    @State private var showSetPasswordSuccessAlert = false
    @State private var passwordSheetState: PasswordSheetState = .passwordInput
    @State private var currentNonce: String?

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Appearance", selection: $colorSchemeSetting) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accessibilityLabel("Appearance Mode")
                }
                profileSection
                nicknameSection
                emailSection
                securitySection
                notificationSection
                signOutSection
                deleteAccountSection
            }
            .navigationTitle("Profile")
            .onAppear {
                loadNickname()
                loadNotificationFrequency()
                checkNotificationStatus()
                let providers = Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
                isPasswordUser = providers.contains("password")
                isGoogleUser = providers.contains("google.com")
                isAppleUser = providers.contains("apple.com")
            }

            .sheet(isPresented: $showAppleReauthSheet) {
                AppleReauthSheet(isPresented: $showAppleReauthSheet, onSuccess: {
                    deleteAccountAndData()
                })
            }
            .sheet(isPresented: $showSetPasswordSheet) {
                setPasswordSheet
            }
            .alert("Success", isPresented: $showPasswordSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been changed successfully.")
            }
            .alert("Password Set Successfully", isPresented: $showSetPasswordSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been updated successfully. You can now sign in with either your email/password or continue using your social login.")
            }
            .alert("Confirm Password", isPresented: $showDeletePasswordPrompt) {
                SecureField("Enter your password", text: $deletePassword)
                Button("Cancel", role: .cancel) {
                    deletePassword = ""
                }
                Button("Continue", role: .destructive) {
                    if !deletePassword.isEmpty {
                        showFinalDeleteConfirmation = true
                    }
                }
            } message: {
                Text("To delete your account, please confirm your password.")
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError ?? "Unknown error.")
            }
            .alert("Final Confirmation", isPresented: $showFinalDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    deletePassword = ""
                }
                Button("Delete Account", role: .destructive) {
                    reauthenticateAndDelete()
                }
            } message: {
                Text("This action cannot be undone. All your food items, recipes, and account data will be permanently deleted. Are you absolutely sure you want to delete your account?")
            }
            .alert("Account Deleted", isPresented: $showDeleteSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your account and all associated data have been successfully deleted.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var profileSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.tertiary)

                VStack {
                    Text(user?.email ?? "No email")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Member since \(formattedDate(user?.metadata.creationDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(UIColor.systemGroupedBackground))
    }

    private var nicknameSection: some View {
        Section(header: Text("Nickname"), footer:
            Group {
                if let message = nicknameFeedbackMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Failed") ? .red : .green)
                }
            }
        ) {
            HStack {
                Text("Nickname")
                    .foregroundColor(.primary)

                Spacer()

                TextField("Your nickname", text: $nickname, onCommit: {
                    if nicknameFieldFocused && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        saveNickname()
                        nicknameFieldFocused = false
                    }
                })
                .multilineTextAlignment(.trailing)
                .foregroundColor(nicknameFieldFocused ? .accentColor : .secondary)
                .focused($nicknameFieldFocused)

                if nicknameFieldFocused {
                    Button("Save") {
                        saveNickname()
                        nicknameFieldFocused = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .font(.footnote.bold())
                    .padding(.leading, 6)
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var emailSection: some View {
        Section(header: Text("Email")) {
            if let email = user?.email {
                Text(email)
                    .font(.headline)
                    .foregroundColor(.primary)
            } else {
                Text("No email address set.")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var securitySection: some View {
        Section(header: Text("Security")) {
            if isPasswordUser {
                Button("Change Password") {
                    clearPasswordFields()
                    passwordSheetState = .changePassword
                    showSetPasswordSheet = true
                }
                .foregroundColor(.primary)
            } else if isGoogleUser || isAppleUser {
                Button("Set Password") {
                    clearSetPasswordFields()
                    passwordSheetState = .passwordInput
                    showSetPasswordSheet = true
                }
                .foregroundColor(.primary)
            }
        }
    }

    private var notificationSection: some View {
        Section(header: Text("Reminders")) {
            if notificationsAllowed {
                Picker("Fridge Reminder", selection: $selectedFrequency) {
                    ForEach(NotificationFrequency.allCases) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .onChange(of: selectedFrequency) { newValue in
                    saveNotificationFrequency(newValue)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications are turned off.")
                        .foregroundColor(.red)
                    Button("Enable Notifications in Settings") {
                        openAppSettings()
                    }
                }
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutAlert = true
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .alert("Are you sure you want to sign out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    session.signOut()
                }
            }
        }
    }

    private var deleteAccountSection: some View {
        Section {
            if (isGoogleUser || isAppleUser) && !isPasswordUser {
                Button(role: .destructive) {
                    if isAppleUser {
                        showAppleReauthSheet = true
                    } else {
                        showGoogleReauthSheet = true
                    }
                } label: {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.red)
                        }
                        Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isDeletingAccount)
                .sheet(isPresented: $showGoogleReauthSheet) {
                    GoogleReauthSheet(isPresented: $showGoogleReauthSheet, onSuccess: {
                        deleteAccountAndData()
                    })
                }
            } else {
                Button(role: .destructive) {
                    showDeletePasswordPrompt = true
                } label: {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.red)
                        }
                        Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isDeletingAccount)
            }
        }
    }



    private var setPasswordSheet: some View {
        NavigationView {
            Group {
                switch passwordSheetState {
                case .passwordInput:
                    passwordInputView
                case .changePassword:
                    changePasswordView
                case .forgotPassword:
                    forgotPasswordView
                case .googleReauth:
                    googleReauthView
                case .appleReauth:
                    appleReauthView
                case .emailReauth:
                    emailReauthView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSetPasswordSheet = false
                        passwordSheetState = .passwordInput
                        clearAllPasswordFields()
                    }
                }
            }
        }
    }
    
    private var navigationTitle: String {
        switch passwordSheetState {
        case .passwordInput:
            return "Set Password"
        case .changePassword:
            return "Change Password"
        case .forgotPassword:
            return "Forgot Password"
        case .googleReauth, .appleReauth, .emailReauth:
            return "Re-authenticate"
        }
    }
    
    private var passwordInputView: some View {
        Form {
            Section(header: Text("New Password")) {
                SecureField("Enter your new password", text: $newPasswordForLink)
            }
            Section(header: Text("Confirm New Password")) {
                SecureField("Confirm your new password", text: $confirmPasswordForLink)
            }
            if let errorMessage = setPasswordError {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { setPassword() }
                    .disabled(newPasswordForLink.isEmpty || confirmPasswordForLink.isEmpty || newPasswordForLink != confirmPasswordForLink)
            }
        }
    }
    
    private var changePasswordView: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter your current password", text: $oldPassword)
            }
            Section(header: Text("New Password")) {
                SecureField("Enter your new password", text: $newPassword)
            }
            Section(header: Text("Confirm New Password")) {
                SecureField("Confirm your new password", text: $confirmPassword)
            }
            if let errorMessage = setPasswordError {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            Section {
                Button("Forgot Password?") {
                    passwordSheetState = .forgotPassword
                }
                .foregroundColor(.blue)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Change") { changePassword() }
                    .disabled(oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
            }
        }
    }
    
    private var forgotPasswordView: some View {
        VStack(spacing: 24) {
            if isAppleUser && !isGoogleUser && !isPasswordUser {
                Text("Re-authenticate with Apple to set a new password.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Re-authenticate with Apple") {
                    passwordSheetState = .appleReauth
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            } else {
                Text("Reset your password via email.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Reset Password via Email") {
                    resetPasswordViaEmail()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }
    
    private var emailReauthView: some View {
        VStack(spacing: 24) {
            Text("For security, please re-authenticate with your email and password.")
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 16) {
                TextField("Email", text: .constant(user?.email ?? ""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                
                SecureField("Password", text: $oldPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Re-authenticate") {
                    reauthenticateWithEmail()
                }
                .buttonStyle(.borderedProminent)
                .disabled(oldPassword.isEmpty)
            }
            .padding(.horizontal)
            
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var googleReauthView: some View {
        VStack(spacing: 24) {
            Text("For security, please re-authenticate with Google to set your password.")
                .multilineTextAlignment(.center)
                .padding()
            Button("Re-authenticate with Google") {
                reauthenticateWithGoogleForPassword()
            }
            .buttonStyle(.borderedProminent)
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }
    
    private var appleReauthView: some View {
        VStack(spacing: 24) {
            Text("For security, please re-authenticate with Apple to set your password.")
                .multilineTextAlignment(.center)
                .padding()
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                },
                onCompletion: handleAppleReauthForPassword
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .padding(.horizontal, 32)
            
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func clearPasswordFields() {
        clearAllPasswordFields()
    }

    private func clearEmailFields() {
        // No email fields to clear
    }

    private func loadNickname() {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let nick = data["nickname"] as? String {
                self.nickname = nick
            }
        }
    }

    private func saveNickname() {
        nicknameFeedbackMessage = nil
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).setData(["nickname": nickname], merge: true) { error in
            if let error = error {
                self.nicknameFeedbackMessage = "Failed to save nickname: \(error.localizedDescription)"
            } else {
                self.nicknameFeedbackMessage = "Nickname updated!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.nicknameFeedbackMessage = nil
                }
            }
        }
    }

    private func saveNotificationFrequency(_ frequency: NotificationFrequency) {
        guard let uid = user?.uid else { return }
        let data: [String: Any] = [
            "notificationFrequency": frequency.rawValue,
            "intervalHours": frequency.intervalHours,
            "updatedAt": Date().timeIntervalSince1970 * 1000
        ]
        db.collection("users").document(uid).setData(data, merge: true)
    }



    private func changeEmail() {
        // No email change functionality
    }
    
    private func updateEmailForUser(_ user: User) {
        // No email update functionality
    }
    
    private func showGoogleReauthForEmailChange() {
        // No Google reauth for email change
    }
    
    private func showAppleReauthForEmailChange() {
        // No Apple reauth for email change
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAllowed = settings.authorizationStatus == .authorized
                if self.notificationsAllowed {
                    self.loadNotificationFrequency()
                }
            }
        }
    }

    private func loadNotificationFrequency() {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let raw = data["notificationFrequency"] as? String,
                   let freq = NotificationFrequency(rawValue: raw) {
                    self.selectedFrequency = freq
                } else {
                    self.selectedFrequency = .every12Hours
                    saveNotificationFrequency(.every12Hours)
                }
            }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    private func reauthenticateAndDelete() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            deleteError = "No user is signed in."
            isDeletingAccount = false
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: deletePassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                self.deleteError = "Re-authentication failed: \(error.localizedDescription)"
                self.isDeletingAccount = false
                return
            }
            deletePassword = ""
            deleteAccountAndData()
        }
    }

    private func deleteAccountAndData() {
        guard let user = Auth.auth().currentUser,
              let uid = user.uid as String? else { return }

        // Show loading state
        isDeletingAccount = true
        deleteError = "Deleting your account and data..."

        // Delete food items from main collection
        let foodItemsRef = db.collection("foodItems").whereField("userID", isEqualTo: uid)
        
        // Delete food items from nested collection (if they exist)
        let nestedFoodItemsRef = db.collection("users").document(uid).collection("foodItems")

        // First, get all food items from main collection
        foodItemsRef.getDocuments { snapshot, error in
            if let error = error {
                self.deleteError = "Failed to fetch food items: \(error.localizedDescription)"
                self.isDeletingAccount = false
                return
            }

            let batch = self.db.batch()
            
            // Delete food items from main collection
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }

            // Delete user document
            let userDocRef = self.db.collection("users").document(uid)
            batch.deleteDocument(userDocRef)

            // Commit the batch deletion
            batch.commit { batchError in
                if let batchError = batchError {
                    self.deleteError = "Failed to delete data: \(batchError.localizedDescription)"
                    self.isDeletingAccount = false
                    return
                }

                // Now try to delete nested food items (this might not exist, so we handle errors gracefully)
                nestedFoodItemsRef.getDocuments { nestedSnapshot, nestedError in
                    if let nestedError = nestedError {
                        print("Warning: Could not fetch nested food items: \(nestedError.localizedDescription)")
                        // Continue with account deletion even if nested items can't be fetched
                    } else {
                        let nestedBatch = self.db.batch()
                        nestedSnapshot?.documents.forEach { doc in
                            nestedBatch.deleteDocument(doc.reference)
                        }
                        
                        nestedBatch.commit { nestedBatchError in
                            if let nestedBatchError = nestedBatchError {
                                print("Warning: Could not delete nested food items: \(nestedBatchError.localizedDescription)")
                                // Continue with account deletion even if nested items can't be deleted
                            }
                        }
                    }
                    
                    // Finally delete the Firebase Auth user
                    user.delete { authError in
                        if let authError = authError {
                            self.deleteError = "Failed to delete user account: \(authError.localizedDescription)"
                            self.isDeletingAccount = false
                        } else {
                            // Success - sign out and clear any local data
                            self.deleteError = nil
                            self.isDeletingAccount = false
                            self.showDeleteSuccessAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.session.signOut()
                            }
                        }
                    }
                }
            }
        }
    }

    private func setPassword() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser else {
            setPasswordError = "No user is signed in."
            return
        }

        guard newPasswordForLink == confirmPasswordForLink else {
            setPasswordError = "Passwords do not match."
            return
        }

        // Handle different authentication methods for re-authentication
        if isGoogleUser {
            passwordSheetState = .googleReauth
        } else if isAppleUser {
            passwordSheetState = .appleReauth
        } else {
            setPasswordError = "Unknown authentication method."
        }
    }
    
    private func changePassword() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser else {
            setPasswordError = "No user is signed in."
            return
        }

        guard newPassword == confirmPassword else {
            setPasswordError = "New passwords do not match."
            return
        }

        // For password users, re-authenticate with email/password
        if isPasswordUser {
            passwordSheetState = .emailReauth
        } else if isGoogleUser {
            // For Google users, only allow reset via email in forgot password, but allow change if they know current password
            passwordSheetState = .emailReauth
        } else if isAppleUser {
            passwordSheetState = .emailReauth
        } else {
            setPasswordError = "Unknown authentication method."
        }
    }
    
    private func resetPasswordViaEmail() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser, let email = user.email else {
            setPasswordError = "No email address found."
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                setPasswordError = "Failed to send reset email: \(error.localizedDescription)"
            } else {
                showSetPasswordSuccessAlert = true
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
                clearAllPasswordFields()
            }
        }
    }
    
    private func showReauthOptions() {
        setPasswordError = nil
        if isGoogleUser {
            passwordSheetState = .googleReauth
        } else if isAppleUser {
            passwordSheetState = .appleReauth
        } else {
            setPasswordError = "No social authentication methods available."
        }
    }
    
    private func reauthenticateWithEmail() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser, let email = user.email else {
            setPasswordError = "No email address found."
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                setPasswordError = "Re-authentication failed: \(error.localizedDescription)"
            } else {
                // Now update the password
                user.updatePassword(to: newPassword) { error in
                    if let error = error {
                        setPasswordError = "Failed to update password: \(error.localizedDescription)"
                    } else {
                        showSetPasswordSuccessAlert = true
                        showSetPasswordSheet = false
                        passwordSheetState = .passwordInput
                        clearAllPasswordFields()
                    }
                }
            }
        }
    }
    
    private func setPasswordAfterReauth() {
        guard let user = Auth.auth().currentUser else {
            setPasswordError = "No user is signed in."
            return
        }
        
        // Determine which password to use based on the current state
        let passwordToSet = passwordSheetState == .changePassword ? newPassword : newPasswordForLink
        
        user.updatePassword(to: passwordToSet) { error in
            if let error = error {
                setPasswordError = "Failed to update password: \(error.localizedDescription)"
            } else {
                showSetPasswordSuccessAlert = true
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
                clearAllPasswordFields()
                self.user = Auth.auth().currentUser // Refresh profile
            }
        }
    }
    


    private func clearSetPasswordFields() {
        newPasswordForLink = ""
        confirmPasswordForLink = ""
        setPasswordError = nil
    }
    
    private func clearAllPasswordFields() {
        newPasswordForLink = ""
        confirmPasswordForLink = ""
        oldPassword = ""
        newPassword = ""
        confirmPassword = ""
        setPasswordError = nil
    }

    private func reauthenticateWithGoogleForPassword() {
        isGoogleReauthenticating = true
        let clientID = FirebaseApp.app()?.options.clientID
        guard let clientID = clientID else {
            setPasswordError = "Missing Google client ID."
            isGoogleReauthenticating = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            setPasswordError = "No root view controller."
            isGoogleReauthenticating = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                setPasswordError = error.localizedDescription
                isGoogleReauthenticating = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                setPasswordError = "Google authentication failed (missing token)."
                isGoogleReauthenticating = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    setPasswordError = error.localizedDescription
                    isGoogleReauthenticating = false
                    return
                }
                isGoogleReauthenticating = false
                setPasswordAfterReauth()
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
            }
        }
    }

    private func handleAppleReauthForPassword(result: Result<ASAuthorization, Error>) {
        isGoogleReauthenticating = true
        switch result {
        case .failure(let error):
            setPasswordError = error.localizedDescription
            isGoogleReauthenticating = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                setPasswordError = "Apple authentication failed."
                isGoogleReauthenticating = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    setPasswordError = error.localizedDescription
                    isGoogleReauthenticating = false
                    return
                }
                isGoogleReauthenticating = false
                setPasswordAfterReauth()
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
            }
        }
    }
}

struct GoogleReauthSheet: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Google...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Google to delete your account.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Re-authenticate with Google") {
                        reauthenticateWithGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func reauthenticateWithGoogle() {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller."
            isLoading = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                errorMessage = "Google authentication failed (missing token)."
                isLoading = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

struct AppleReauthSheet: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Apple...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Apple to delete your account.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleReauth
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func handleAppleReauth(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple authentication failed."
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

struct GoogleReauthForEmailSheet: View {
    @Binding var isPresented: Bool
    let newEmail: String
    let onSuccess: (User) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Google...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Google to change your email to: \(newEmail)")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Re-authenticate with Google") {
                        reauthenticateWithGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func reauthenticateWithGoogle() {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller."
            isLoading = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                errorMessage = "Google authentication failed (missing token)."
                isLoading = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                if let currentUser = Auth.auth().currentUser {
                    onSuccess(currentUser)
                }
            }
        }
    }
}

struct AppleReauthForEmailSheet: View {
    @Binding var isPresented: Bool
    let newEmail: String
    let onSuccess: (User) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Apple...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Apple to change your email to: \(newEmail)")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleReauth
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func handleAppleReauth(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple authentication failed."
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                if let currentUser = Auth.auth().currentUser {
                    onSuccess(currentUser)
                }
            }
        }
    }
}

struct GoogleReauthForPasswordSheet: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Google...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Google to set your password.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Re-authenticate with Google") {
                        reauthenticateWithGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func reauthenticateWithGoogle() {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller."
            isLoading = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                errorMessage = "Google authentication failed (missing token)."
                isLoading = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

struct AppleReauthForPasswordSheet: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Apple...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Apple to set your password.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleReauth
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func handleAppleReauth(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple authentication failed."
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

*/
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import FirebaseCore

enum PasswordSheetState: String, Identifiable {
    case passwordInput, changePassword, forgotPassword, googleReauth, appleReauth, emailReauth

    var id: String { rawValue }
}


enum NotificationFrequency: String, CaseIterable, Identifiable {
    case none = "No Notifications"
    case every12Hours = "Every 12 Hours"
    case every24Hours = "Every 24 Hours"
    case everyWeek = "Every Week"

    var id: String { self.rawValue }

    var intervalHours: Int {
        switch self {
        case .none: return 0
        case .every12Hours: return 12
        case .every24Hours: return 24
        case .everyWeek: return 24 * 7
        }
    }
}


struct ProfileView: View {
    @EnvironmentObject var session: SessionManager
    @State private var user: User? = Auth.auth().currentUser
    @State private var nickname: String = ""
    @State private var isEditingNickname = false
    @FocusState private var nicknameFieldFocused: Bool
    @State private var deleteError: String?
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @State private var selectedFrequency: NotificationFrequency = .every12Hours
    @State private var notificationsAllowed = true
    @State private var nicknameFeedbackMessage: String?

    @State private var showPasswordSuccessAlert = false

    @State private var showDeletePasswordPrompt = false
    @State private var deletePassword = ""
    @State private var showFinalDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showDeleteSuccessAlert = false
    @State private var isPasswordUser: Bool = false
    @State private var isGoogleUser: Bool = false
    @State private var isAppleUser: Bool = false
    @State private var showGoogleReauthSheet = false
    @State private var showAppleReauthSheet = false
    @State private var isGoogleReauthenticating = false
    @State private var showSignOutAlert = false
    @State private var showSetPasswordSheet = false
    @State private var newPasswordForLink = ""
    @State private var confirmPasswordForLink = ""
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var setPasswordError: String?
    @State private var showSetPasswordSuccessAlert = false
    @State private var passwordSheetState: PasswordSheetState? = nil
    @State private var currentNonce: String?

    @State private var forgotNewPassword = ""
    @State private var forgotConfirmPassword = ""
    @State private var emailResetSent = false

    @State private var profileImage: UIImage? = nil
    @State private var showProfilePhotoSourceDialog = false
    @State private var showProfilePhotoPicker = false
    @State private var showProfileCameraPicker = false

    private let db = Firestore.firestore()

    let profileImageDefaultsKey = "profileImageData"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Appearance", selection: $colorSchemeSetting) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accessibilityLabel("Appearance Mode")
                }
                profileSection
                nicknameSection
                emailSection
                securitySection
                notificationSection
                signOutSection
                deleteAccountSection
            }
            .navigationTitle("Profile")
            .onAppear {
                loadNickname()
                loadNotificationFrequency()
                checkNotificationStatus()
                updateProviderStates()
                loadProfileImageFromDefaults()
            }
            .onChange(of: profileImage) { newImage in
                if let image = newImage {
                    saveProfileImageToDefaults(image)
                }
            }
            .sheet(isPresented: $showAppleReauthSheet) {
                AppleReauthSheet(isPresented: $showAppleReauthSheet, onSuccess: {
                    deleteAccountAndData()
                })
            }
            .sheet(item: $passwordSheetState) { state in
                setPasswordSheet(for: state)
            }
            .alert("Success", isPresented: $showPasswordSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been changed successfully.")
            }
            .alert("Password Set Successfully", isPresented: $showSetPasswordSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been updated successfully. You can now sign in with either your email/password or continue using your social login.")
            }
            .alert("Confirm Password", isPresented: $showDeletePasswordPrompt) {
                SecureField("Enter your password", text: $deletePassword)
                Button("Cancel", role: .cancel) {
                    deletePassword = ""
                }
                Button("Continue", role: .destructive) {
                    if !deletePassword.isEmpty {
                        showFinalDeleteConfirmation = true
                    }
                }
            } message: {
                Text("To delete your account, please confirm your password.")
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError ?? "Unknown error.")
            }
            .alert("Final Confirmation", isPresented: $showFinalDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    deletePassword = ""
                }
                Button("Delete Account", role: .destructive) {
                    reauthenticateAndDelete()
                }
            } message: {
                Text("This action cannot be undone. All your food items, recipes, and account data will be permanently deleted. Are you absolutely sure you want to delete your account?")
            }
            .alert("Account Deleted", isPresented: $showDeleteSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your account and all associated data have been successfully deleted.")
            }
            .sheet(isPresented: $showProfilePhotoPicker) {
                PhotoPicker(image: $profileImage)
            }
            .sheet(isPresented: $showProfileCameraPicker) {
                CameraPicker(image: $profileImage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var profileSection: some View {
        Section {
            VStack(spacing: 16) {
                Button(action: {
                    showProfilePhotoSourceDialog = true
                }) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .confirmationDialog("Choose Profile Photo", isPresented: $showProfilePhotoSourceDialog, titleVisibility: .visible) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button("Take Photo") { showProfileCameraPicker = true }
                    }
                    Button("Choose from Gallery") { showProfilePhotoPicker = true }
                    Button("Cancel", role: .cancel) { }
                }
                VStack {
                    Text(user?.email ?? "No email")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Member since \(formattedDate(user?.metadata.creationDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(UIColor.systemGroupedBackground))
    }

    private var nicknameSection: some View {
        Section(header: Text("Nickname"), footer:
            Group {
                if let message = nicknameFeedbackMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Failed") ? .red : .green)
                }
            }
        ) {
            HStack {
                Text("Nickname")
                    .foregroundColor(.primary)

                Spacer()

                TextField("Your nickname", text: $nickname, onCommit: {
                    if nicknameFieldFocused && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        saveNickname()
                        nicknameFieldFocused = false
                    }
                })
                .multilineTextAlignment(.trailing)
                .foregroundColor(nicknameFieldFocused ? .accentColor : .secondary)
                .focused($nicknameFieldFocused)

                if nicknameFieldFocused {
                    Button("Save") {
                        saveNickname()
                        nicknameFieldFocused = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .font(.footnote.bold())
                    .padding(.leading, 6)
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var emailSection: some View {
        Section(header: Text("Email")) {
            if let email = user?.email {
                Text(email)
                    .font(.headline)
                    .foregroundColor(.primary)
            } else {
                Text("No email address set.")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var securitySection: some View {
        Section(header: Text("Security")) {
            // This button is shown if the user already has a password.
            if isPasswordUser {
                Button("Change Password") {
                    updateProviderStates()
                    clearAllPasswordFields()
                    setPasswordError = nil
                    passwordSheetState = .changePassword
                }
                .foregroundColor(.primary)
                
            // This button is shown for social-only users who want to add a password.
            } else  {
                Button("Set Password") {
                    updateProviderStates()
                    clearAllPasswordFields()
                    setPasswordError = nil
                    passwordSheetState = .passwordInput
                }
                .foregroundColor(.primary)
            }
        }
    }

    private var notificationSection: some View {
        Section(header: Text("Reminders")) {
            if notificationsAllowed {
                Picker("Fridge Reminder", selection: $selectedFrequency) {
                    ForEach(NotificationFrequency.allCases) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .onChange(of: selectedFrequency) { newValue in
                    saveNotificationFrequency(newValue)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications are turned off.")
                        .foregroundColor(.red)
                    Button("Enable Notifications in Settings") {
                        openAppSettings()
                    }
                }
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutAlert = true
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .alert("Are you sure you want to sign out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    session.signOut()
                }
            }
        }
    }

    private var deleteAccountSection: some View {
        Section {
            if (isGoogleUser || isAppleUser) && !isPasswordUser {
                Button(role: .destructive) {
                    if isAppleUser {
                        showAppleReauthSheet = true
                    } else {
                        showGoogleReauthSheet = true
                    }
                } label: {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.red)
                        }
                        Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isDeletingAccount)
                .sheet(isPresented: $showGoogleReauthSheet) {
                    GoogleReauthSheet(isPresented: $showGoogleReauthSheet, onSuccess: {
                        deleteAccountAndData()
                    })
                }
            } else {
                Button(role: .destructive) {
                    showDeletePasswordPrompt = true
                } label: {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.red)
                        }
                        Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isDeletingAccount)
            }
        }
    }



    @ViewBuilder
    func setPasswordSheet(for state: PasswordSheetState) -> some View {
        NavigationView {
            Group {
                switch state {
                case .changePassword:
                    changePasswordView
                case .passwordInput:
                    passwordInputView
                case .forgotPassword:
                    forgotPasswordView
                case .googleReauth:
                    googleReauthView
                case .appleReauth:
                    appleReauthView
                case .emailReauth:
                    emailReauthView
                }
            }
            .navigationTitle(navigationTitle(for: state))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        passwordSheetState = nil
                    }
                }
            }
        }
    }

    func navigationTitle(for state: PasswordSheetState) -> String {
        switch state {
        case .passwordInput:
            return "Set Password"
        case .changePassword:
            return "Change Password"
        case .forgotPassword:
            return "Forgot Password"
        case .googleReauth, .appleReauth, .emailReauth:
            return "Re-authenticate"
        }
    }

    

    
    private var passwordInputView: some View {
        Form {
            Section(header: Text("New Password")) {
                SecureField("Enter your new password", text: $newPasswordForLink)
            }
            Section(header: Text("Confirm New Password")) {
                SecureField("Confirm your new password", text: $confirmPasswordForLink)
            }
            if let errorMessage = setPasswordError {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { setPassword() }
                    .disabled(newPasswordForLink.isEmpty || confirmPasswordForLink.isEmpty || newPasswordForLink != confirmPasswordForLink)
            }
        }
    }
    
    private var changePasswordView: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter your current password", text: $oldPassword)
            }
            Section(header: Text("New Password")) {
                SecureField("Enter your new password", text: $newPassword)
            }
            Section(header: Text("Confirm New Password")) {
                SecureField("Confirm your new password", text: $confirmPassword)
            }
            if let errorMessage = setPasswordError {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            Section {
                Button("Forgot Password?") {
                    passwordSheetState = .forgotPassword
                }
                .foregroundColor(.blue)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Change") { changePassword() }
                    .disabled(oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
            }
        }
    }
    
    private var forgotPasswordView: some View {
        Group {
            if isAppleUser {
                // Apple enabled (regardless of Google): only Apple reauth
                VStack(spacing: 24) {
                    Text("To reset your password, you must set a new password and re-authenticate with Apple.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(radius: 2)
                        VStack(spacing: 16) {
                            SecureField("New Password", text: $forgotNewPassword)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color(UIColor.systemBackground).opacity(0.7))
                                .cornerRadius(8)
                            SecureField("Confirm New Password", text: $forgotConfirmPassword)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color(UIColor.systemBackground).opacity(0.7))
                                .cornerRadius(8)
                            Button(action: {
                                if forgotNewPassword == forgotConfirmPassword && !forgotNewPassword.isEmpty {
                                    passwordSheetState = .appleReauth
                                    newPasswordForLink = forgotNewPassword
                                } else {
                                    setPasswordError = "Passwords do not match or are empty."
                                }
                            }) {
                                Text("Re-authenticate with Apple and Save")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    if let errorMessage = setPasswordError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
                .padding()
            } else if isGoogleUser {
                // Google enabled and Apple not: Google reauth or via email
                VStack(spacing: 24) {
                    Text("Choose how to reset your password:")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    Button(action: {
                        resetPasswordViaEmail()
                    }) {
                        Text("Reset via Email")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    if emailResetSent {
                        Text("A password reset email has been sent to your email address. Please check your inbox.")
                            .foregroundColor(.green)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Divider()
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(radius: 2)
                        VStack(spacing: 16) {
                            SecureField("New Password", text: $forgotNewPassword)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color(UIColor.systemBackground).opacity(0.7))
                                .cornerRadius(8)
                            SecureField("Confirm New Password", text: $forgotConfirmPassword)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color(UIColor.systemBackground).opacity(0.7))
                                .cornerRadius(8)
                            Button(action: {
                                if forgotNewPassword == forgotConfirmPassword && !forgotNewPassword.isEmpty {
                                    passwordSheetState = .googleReauth
                                    newPasswordForLink = forgotNewPassword
                                } else {
                                    setPasswordError = "Passwords do not match or are empty."
                                }
                            }) {
                                Text("Re-authenticate with Google and Save")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    if let errorMessage = setPasswordError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
                .padding()
            } else {
                // Only email
                VStack(spacing: 24) {
                    Text("Reset your password via email.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    Button(action: {
                        resetPasswordViaEmail()
                    }) {
                        Text("Reset Password via Email")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    if emailResetSent {
                        Text("A password reset email has been sent to your email address. Please check your inbox.")
                            .foregroundColor(.green)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    if let errorMessage = setPasswordError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private var emailReauthView: some View {
        VStack(spacing: 24) {
            Text("For security, please re-authenticate with your email and password.")
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 16) {
                TextField("Email", text: .constant(user?.email ?? ""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                
                SecureField("Password", text: $oldPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Re-authenticate") {
                    reauthenticateWithEmail()
                }
                .buttonStyle(.borderedProminent)
                .disabled(oldPassword.isEmpty)
            }
            .padding(.horizontal)
            
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var googleReauthView: some View {
        VStack(spacing: 24) {
            Text("For security, please re-authenticate with Google to set your password.")
                .multilineTextAlignment(.center)
                .padding()
            Button("Re-authenticate with Google") {
                reauthenticateWithGoogleForPassword()
            }
            .buttonStyle(.borderedProminent)
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }
    
    private var appleReauthView: some View {
        VStack(spacing: 24) {
            Text("For security, please re-authenticate with Apple to set your password.")
                .multilineTextAlignment(.center)
                .padding()
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                },
                onCompletion: handleAppleReauthForPassword
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .padding(.horizontal, 32)
            
            if let errorMessage = setPasswordError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func clearPasswordFields() {
        clearAllPasswordFields()
    }

    private func loadNickname() {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let nick = data["nickname"] as? String {
                self.nickname = nick
            }
        }
    }

    private func saveNickname() {
        nicknameFeedbackMessage = nil
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).setData(["nickname": nickname], merge: true) { error in
            if let error = error {
                self.nicknameFeedbackMessage = "Failed to save nickname: \(error.localizedDescription)"
            } else {
                self.nicknameFeedbackMessage = "Nickname updated!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.nicknameFeedbackMessage = nil
                }
            }
        }
    }

    private func saveNotificationFrequency(_ frequency: NotificationFrequency) {
        guard let uid = user?.uid else { return }
        let data: [String: Any] = [
            "notificationFrequency": frequency.rawValue,
            "intervalHours": frequency.intervalHours,
            "updatedAt": Date().timeIntervalSince1970 * 1000
        ]
        db.collection("users").document(uid).setData(data, merge: true)
    }



    

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAllowed = settings.authorizationStatus == .authorized
                if self.notificationsAllowed {
                    self.loadNotificationFrequency()
                }
            }
        }
    }

    private func loadNotificationFrequency() {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let raw = data["notificationFrequency"] as? String,
                   let freq = NotificationFrequency(rawValue: raw) {
                    self.selectedFrequency = freq
                } else {
                    self.selectedFrequency = .every12Hours
                    saveNotificationFrequency(.every12Hours)
                }
            }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    private func reauthenticateAndDelete() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            deleteError = "No user is signed in."
            isDeletingAccount = false
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: deletePassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                self.deleteError = "Re-authentication failed: \(error.localizedDescription)"
                self.isDeletingAccount = false
                return
            }
            deletePassword = ""
            deleteAccountAndData()
        }
    }

    private func deleteAccountAndData() {
        guard let user = Auth.auth().currentUser,
              let uid = user.uid as String? else { return }

        // Show loading state
        isDeletingAccount = true
        deleteError = "Deleting your account and data..."

        // Delete food items from main collection
        let foodItemsRef = db.collection("foodItems").whereField("userID", isEqualTo: uid)
        
        // Delete food items from nested collection (if they exist)
        let nestedFoodItemsRef = db.collection("users").document(uid).collection("foodItems")

        // First, get all food items from main collection
        foodItemsRef.getDocuments { snapshot, error in
            if let error = error {
                self.deleteError = "Failed to fetch food items: \(error.localizedDescription)"
                self.isDeletingAccount = false
                return
            }

            let batch = self.db.batch()
            
            // Delete food items from main collection
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }

            // Delete user document
            let userDocRef = self.db.collection("users").document(uid)
            batch.deleteDocument(userDocRef)

            // Commit the batch deletion
            batch.commit { batchError in
                if let batchError = batchError {
                    self.deleteError = "Failed to delete data: \(batchError.localizedDescription)"
                    self.isDeletingAccount = false
                    return
                }

                // Now try to delete nested food items (this might not exist, so we handle errors gracefully)
                nestedFoodItemsRef.getDocuments { nestedSnapshot, nestedError in
                    if let nestedError = nestedError {
                        print("Warning: Could not fetch nested food items: \(nestedError.localizedDescription)")
                        // Continue with account deletion even if nested items can't be fetched
                    } else {
                        let nestedBatch = self.db.batch()
                        nestedSnapshot?.documents.forEach { doc in
                            nestedBatch.deleteDocument(doc.reference)
                        }
                        
                        nestedBatch.commit { nestedBatchError in
                            if let nestedBatchError = nestedBatchError {
                                print("Warning: Could not delete nested food items: \(nestedBatchError.localizedDescription)")
                                // Continue with account deletion even if nested items can't be deleted
                            }
                        }
                    }
                    
                    // Finally delete the Firebase Auth user
                    user.delete { authError in
                        if let authError = authError {
                            self.deleteError = "Failed to delete user account: \(authError.localizedDescription)"
                            self.isDeletingAccount = false
                        } else {
                            // Success - sign out and clear any local data
                            self.deleteError = nil
                            self.isDeletingAccount = false
                            self.showDeleteSuccessAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.session.signOut()
                            }
                        }
                    }
                }
            }
        }
    }

    private func setPassword() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser else {
            setPasswordError = "No user is signed in."
            return
        }

        guard newPasswordForLink == confirmPasswordForLink else {
            setPasswordError = "Passwords do not match."
            return
        }

        // Handle different authentication methods for re-authentication
        if isGoogleUser {
            passwordSheetState = .googleReauth
        } else if isAppleUser {
            passwordSheetState = .appleReauth
        } else {
            setPasswordError = "Unknown authentication method."
        }
    }
    
    private func changePassword() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser else {
            setPasswordError = "No user is signed in."
            return
        }

        guard newPassword == confirmPassword else {
            setPasswordError = "New passwords do not match."
            return
        }

        // For password users, re-authenticate with email/password
        if isPasswordUser {
            passwordSheetState = .emailReauth
        } else if isGoogleUser {
            // For Google users, only allow reset via email in forgot password, but allow change if they know current password
            passwordSheetState = .emailReauth
        } else if isAppleUser {
            passwordSheetState = .emailReauth
        } else {
            setPasswordError = "Unknown authentication method."
        }
    }
    
    private func resetPasswordViaEmail() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser, let email = user.email else {
            setPasswordError = "No email address found."
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                setPasswordError = "Failed to send reset email: \(error.localizedDescription)"
                emailResetSent = false
            } else {
                emailResetSent = true
            }
        }
    }
    
    private func showReauthOptions() {
        setPasswordError = nil
        if isGoogleUser {
            passwordSheetState = .googleReauth
        } else if isAppleUser {
            passwordSheetState = .appleReauth
        } else {
            setPasswordError = "No social authentication methods available."
        }
    }
    
    private func reauthenticateWithEmail() {
        setPasswordError = nil
        guard let user = Auth.auth().currentUser, let email = user.email else {
            setPasswordError = "No email address found."
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                setPasswordError = "Re-authentication failed: \(error.localizedDescription)"
            } else {
                // Now update the password
                user.updatePassword(to: newPassword) { error in
                    if let error = error {
                        setPasswordError = "Failed to update password: \(error.localizedDescription)"
                    } else {
                        showSetPasswordSuccessAlert = true
                        showSetPasswordSheet = false
                        passwordSheetState = .passwordInput
                        clearAllPasswordFields()
                        updateProviderStates()
                    }
                }
            }
        }
    }
    
    private func setPasswordAfterReauth() {
        guard let user = Auth.auth().currentUser else {
            setPasswordError = "No user is signed in."
            return
        }
        
        // Determine which password to use based on the current state
        let passwordToSet = passwordSheetState == .changePassword ? newPassword : newPasswordForLink
        
        user.updatePassword(to: passwordToSet) { error in
            if let error = error {
                setPasswordError = "Failed to update password: \(error.localizedDescription)"
            } else {
                showSetPasswordSuccessAlert = true
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
                clearAllPasswordFields()
                self.user = Auth.auth().currentUser // Refresh profile
                updateProviderStates()
            }
        }
    }
    


    private func clearSetPasswordFields() {
        newPasswordForLink = ""
        confirmPasswordForLink = ""
        setPasswordError = nil
    }
    
    private func clearAllPasswordFields() {
        newPasswordForLink = ""
        confirmPasswordForLink = ""
        oldPassword = ""
        newPassword = ""
        confirmPassword = ""
        setPasswordError = nil
    }

    private func reauthenticateWithGoogleForPassword() {
        isGoogleReauthenticating = true
        let clientID = FirebaseApp.app()?.options.clientID
        guard let clientID = clientID else {
            setPasswordError = "Missing Google client ID."
            isGoogleReauthenticating = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            setPasswordError = "No root view controller."
            isGoogleReauthenticating = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                setPasswordError = error.localizedDescription
                isGoogleReauthenticating = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                setPasswordError = "Google authentication failed (missing token)."
                isGoogleReauthenticating = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    setPasswordError = error.localizedDescription
                    isGoogleReauthenticating = false
                    return
                }
                isGoogleReauthenticating = false
                setPasswordAfterReauth()
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
            }
        }
    }

    private func handleAppleReauthForPassword(result: Result<ASAuthorization, Error>) {
        isGoogleReauthenticating = true
        switch result {
        case .failure(let error):
            setPasswordError = error.localizedDescription
            isGoogleReauthenticating = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                setPasswordError = "Apple authentication failed."
                isGoogleReauthenticating = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    setPasswordError = error.localizedDescription
                    isGoogleReauthenticating = false
                    return
                }
                isGoogleReauthenticating = false
                setPasswordAfterReauth()
                showSetPasswordSheet = false
                passwordSheetState = .passwordInput
            }
        }
    }

    private func updateProviderStates() {
        let providers = Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
        isPasswordUser = providers.contains("password")
        isGoogleUser = providers.contains("google.com")
        isAppleUser = providers.contains("apple.com")
    }

    private func saveProfileImageToDefaults(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.9) {
            UserDefaults.standard.set(data, forKey: profileImageDefaultsKey)
        }
    }

    private func loadProfileImageFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: profileImageDefaultsKey),
           let image = UIImage(data: data) {
            self.profileImage = image
        }
    }
}

struct GoogleReauthSheet: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Google...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Google to delete your account.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Re-authenticate with Google") {
                        reauthenticateWithGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func reauthenticateWithGoogle() {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller."
            isLoading = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                errorMessage = "Google authentication failed (missing token)."
                isLoading = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

struct AppleReauthSheet: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Apple...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Apple to delete your account.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleReauth
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func handleAppleReauth(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple authentication failed."
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

struct GoogleReauthForEmailSheet: View {
    @Binding var isPresented: Bool
    let newEmail: String
    let onSuccess: (User) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Google...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Google to change your email to: \(newEmail)")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Re-authenticate with Google") {
                        reauthenticateWithGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func reauthenticateWithGoogle() {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller."
            isLoading = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                errorMessage = "Google authentication failed (missing token)."
                isLoading = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                if let currentUser = Auth.auth().currentUser {
                    onSuccess(currentUser)
                }
            }
        }
    }
}

struct AppleReauthForEmailSheet: View {
    @Binding var isPresented: Bool
    let newEmail: String
    let onSuccess: (User) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Apple...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Apple to change your email to: \(newEmail)")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleReauth
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func handleAppleReauth(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple authentication failed."
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                if let currentUser = Auth.auth().currentUser {
                    onSuccess(currentUser)
                }
            }
        }
    }
}

struct GoogleReauthForPasswordSheet: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Google...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Google to set your password.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Re-authenticate with Google") {
                        reauthenticateWithGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func reauthenticateWithGoogle() {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller."
            isLoading = false
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                errorMessage = "Google authentication failed (missing token)."
                isLoading = false
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}

struct AppleReauthForPasswordSheet: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Re-authenticating with Apple...")
                        .padding()
                } else {
                    Text("For security, please re-authenticate with Apple to set your password.")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: handleAppleReauth
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .padding(.horizontal, 32)
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                Spacer()
            }
            .navigationTitle("Re-authenticate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    func handleAppleReauth(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple authentication failed."
                isLoading = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                isLoading = false
                isPresented = false
                onSuccess()
            }
        }
    }
}





