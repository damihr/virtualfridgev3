//
//  WelcomeView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 03.06.2025.
//
import SwiftUI

struct WelcomeView: View {
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var showGoogleSignIn = false
    @State private var showAppleSignIn = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.mint.opacity(0.2), .green.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "leaf.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.mint, .green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("VirtualFridge")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.mint, .green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                Spacer()
                // Buttons
                VStack(spacing: 16) {
                    Button(action: { showSignIn = true }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
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
                    Button(action: { showSignUp = true }) {
                        Text("Sign Up with email")
                            .font(.headline)
                            .foregroundColor(.mint)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.mint, .green]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    }
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.vertical, 8)
                    // Google Sign In
                    Button(action: { showGoogleSignIn = true }) {
                        HStack(spacing: 12) {
                            Image("google_icon") // Use your Google icon asset name here
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("Sign in with Google")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView()
                .transition(.move(edge: .trailing))
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .transition(.move(edge: .trailing))
        }
        .fullScreenCover(isPresented: $showGoogleSignIn) {
            GoogleSignUpView()
                .transition(.move(edge: .trailing))
        }
        .fullScreenCover(isPresented: $showAppleSignIn) {
            AppleSignUpView()
                .transition(.move(edge: .trailing))
        }
    }
}

