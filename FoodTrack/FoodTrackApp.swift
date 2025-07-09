//
//  FoodTrackApp.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 03.06.2025.
//
/*
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore
import UIKit
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

@main
struct FoodTrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            if session.isSignedIn {
                MainTabView()
                    .environmentObject(session)
                    .onAppear {
                        NotificationManager.shared.registerForPushNotifications()
                    }
            } else {
                OnboardingFlow()
                    .environmentObject(session)
                    .preferredColorScheme(.light)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Set delegates
        Messaging.messaging().delegate = NotificationManager.shared
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        return true
    }

    // Called when APNs token is received
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        // Now fetch FCM token (APNs token is required before this)
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error)")
            } else if let token = token {
                print("📲 Got FCM token after APNs: \(token)")
                NotificationManager.shared.saveTokenToFirestore(token)
            }
        }
    }
}













class SessionManager: ObservableObject {
    @Published var isSignedIn: Bool = false

    init() {
        self.isSignedIn = Auth.auth().currentUser?.isEmailVerified ?? false

        Auth.auth().addStateDidChangeListener { _, user in
            if let user = user {
                user.reload { _ in
                    DispatchQueue.main.async {
                        self.isSignedIn = user.isEmailVerified
                    }
                }
            } else {
                self.isSignedIn = false
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.isSignedIn = false
    }
}




import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func saveTokenToFirestore(_ token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No signed-in user to save token for.")
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .setData(["fcmToken": token], merge: true) { error in
                if let error = error {
                    print("❌ Failed to save FCM token: \(error)")
                } else {
                    print("✅ FCM token saved for user \(userID)")
                }
            }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("🔄 FCM didRefreshToken: \(token)")
        saveTokenToFirestore(token)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

*/
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore
import UIKit
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

@main
struct FoodTrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var session = SessionManager()
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation { showSplash = false }
                        }
                    }
            } else {
                if session.isCheckingAuth {
                    ProgressView("Checking authentication...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                } else if session.isSignedIn {
                    MainTabView()
                        .environmentObject(session)
                        .onAppear {
                            NotificationManager.shared.registerForPushNotifications()
                        }
                        .preferredColorScheme(
                            colorSchemeSetting == "system" ? nil :
                            (colorSchemeSetting == "dark" ? .dark : .light)
                        )
                } else {
                    OnboardingFlow()
                        .environmentObject(session)
                        .preferredColorScheme(.light)
                }
            }
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Image("Image")
                .resizable()
                .frame(width: 120, height: 120)
                .cornerRadius(24)
                .shadow(radius: 10)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Set delegates
        Messaging.messaging().delegate = NotificationManager.shared
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        return true
    }

    // Called when APNs token is received
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        // Now fetch FCM token (APNs token is required before this)
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error)")
            } else if let token = token {
                print("📲 Got FCM token after APNs: \(token)")
                NotificationManager.shared.saveTokenToFirestore(token)
            }
        }
    }
}














class SessionManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var isCheckingAuth: Bool = true

    init() {
        updateSignInStatus()
        Auth.auth().addStateDidChangeListener { _, _ in
            self.updateSignInStatus()
        }
    }

    private func updateSignInStatus() {
        isCheckingAuth = true
        if let user = Auth.auth().currentUser {
            user.reload { _ in
                DispatchQueue.main.async {
                    self.isSignedIn = user.isEmailVerified
                    self.isCheckingAuth = false
                }
            }
        } else {
            self.isSignedIn = false
            self.isCheckingAuth = false
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.isSignedIn = false
    }
}



import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func saveTokenToFirestore(_ token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No signed-in user to save token for.")
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .setData(["fcmToken": token], merge: true) { error in
                if let error = error {
                    print("❌ Failed to save FCM token: \(error)")
                } else {
                    print("✅ FCM token saved for user \(userID)")
                }
            }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("🔄 FCM didRefreshToken: \(token)")
        saveTokenToFirestore(token)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

