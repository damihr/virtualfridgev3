//
//  Profile.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 10.06.2025.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import FirebaseCore
import GoogleSignIn

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

    @State private var showingPasswordChangeSheet = false
    @State private var newPassword = ""
    @State private var currentPassword = ""

    @State private var nicknameFeedbackMessage: String?
    @State private var passwordErrorMessage: String?
    @State private var showPasswordSuccessAlert = false

    @State private var showDeletePasswordPrompt = false
    @State private var deletePassword = ""
    @State private var showFinalDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showDeleteSuccessAlert = false
    @State private var isPasswordUser: Bool = false
    @State private var isGoogleUser: Bool = false
    @State private var showSetPasswordAlert = false
    @State private var setPasswordError: String?
    @State private var showGoogleReauthSheet = false
    @State private var isGoogleReauthenticating = false
    @State private var showSignOutAlert = false

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
            }
            .sheet(isPresented: $showingPasswordChangeSheet) {
                passwordChangeSheet
            }
            .alert("Success", isPresented: $showPasswordSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been changed successfully.")
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
            .alert("Set Password", isPresented: $showSetPasswordAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = setPasswordError {
                    Text("Failed to send password reset email: \(error)")
                } else {
                    Text("A password setup email has been sent to your Google account. Please check your inbox.")
                }
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

    private var securitySection: some View {
        Section(header: Text("Security")) {
            if isPasswordUser {
                Button("Change Password") {
                    clearPasswordFields()
                    showingPasswordChangeSheet = true
                }
                .foregroundColor(.primary)
            } else if isGoogleUser {
                Button("Set Password") {
                    if let email = user?.email {
                        Auth.auth().sendPasswordReset(withEmail: email) { error in
                            if let error = error {
                                setPasswordError = error.localizedDescription
                            } else {
                                setPasswordError = nil
                            }
                            showSetPasswordAlert = true
                        }
                    }
                }
                .foregroundColor(.primary)
                .alert("Set Password", isPresented: $showSetPasswordAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if let error = setPasswordError {
                        Text("Failed to send password reset email: \(error)")
                    } else {
                        Text("A password setup email has been sent to your Google account. Please check your inbox.")
                    }
                }
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
            if isGoogleUser && !isPasswordUser {
                Button(role: .destructive) {
                    showGoogleReauthSheet = true
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

    private var passwordChangeSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password"),
                        footer: Text("For security, you must re-authenticate before changing your password.").font(.caption)) {
                    SecureField("Enter your current password", text: $currentPassword)
                }

                Section(header: Text("New Password")) {
                    SecureField("Enter your new password", text: $newPassword)
                }

                if let message = passwordErrorMessage {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingPasswordChangeSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { changePassword() }
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func clearPasswordFields() {
        currentPassword = ""
        newPassword = ""
        passwordErrorMessage = nil
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

    private func changePassword() {
        passwordErrorMessage = nil
        guard let user = Auth.auth().currentUser, let email = user.email else {
            self.passwordErrorMessage = "No user is signed in."
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                self.passwordErrorMessage = "Re-authentication failed. Please check your current password."
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self.passwordErrorMessage = "Failed to update password: \(error.localizedDescription)"
                } else {
                    self.showingPasswordChangeSheet = false
                    self.showPasswordSuccessAlert = true
                }
            }
        }
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
