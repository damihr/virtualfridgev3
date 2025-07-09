//
//  ContentView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 03.06.2025.
//
/*
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FeatureData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct OnboardingFlow: View {
    @State private var currentPage = 0
    @State private var showWelcome = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // Background for iPad rendering safety

            if showWelcome {
                WelcomeView()
                    .id("welcome")
                    .transition(.opacity)
            } else {
                ScrollView {
                    VStack {
                        if currentPage == 0 {
                            Onboard(
                                title: "Virtual Fridge",
                                features: [
                                    FeatureData(title: "Smart Tracking", subtitle: "Control product quantities", icon: "barcode.viewfinder"),
                                    FeatureData(title: "Meal Plans", subtitle: "Flexible AI recommendations", icon: "fork.knife"),
                                    FeatureData(title: "Zero Waste", subtitle: "Expiry reminders", icon: "bolt.fill"),
                                    FeatureData(title: "Analytics", subtitle: "Track calories & quality", icon: "chart.bar.xaxis")
                                ],
                                description: "Plan your meals weekly with ease — no spoiled food, automatic shopping lists, and AI-curated dishes based on your preferences.",
                                buttonTitle: "Next",
                                buttonColors: (.mint, .green),
                                nextAction: { currentPage += 1 },
                                currentPage: currentPage
                            )
                        } else if currentPage == 1 {
                            Onboard(
                                title: "Scan & Discover",
                                features: [
                                    FeatureData(title: "Fridge Scan", subtitle: "Snap and add products quickly", icon: "camera.viewfinder"),
                                    FeatureData(title: "Manual Entry", subtitle: "Add items easily by typing", icon: "keyboard"),
                                    FeatureData(title: "Receipt Scan", subtitle: "Fast product lookup", icon: "barcode.viewfinder")
                                ],
                                description: "Use multiple scanning methods to add your groceries seamlessly with speed and precision.",
                                buttonTitle: "Next",
                                buttonColors: (.orange, .red),
                                nextAction: { currentPage += 1 },
                                currentPage: currentPage
                            )
                        } else if currentPage == 2 {
                            Onboard(
                                title: "Personalized AI Plans",
                                features: [
                                    FeatureData(title: "Custom Recommendations", subtitle: "", icon: "sparkles"),
                                    FeatureData(title: "Meal Suggestions", subtitle: "", icon: "lightbulb"),
                                    FeatureData(title: "Nutrition Insights", subtitle: "", icon: "heart.fill")
                                ],
                                description: "Get meal plans and tips based on your unique style, dietary needs, and habits using powerful AI technology.",
                                buttonTitle: "Get Started",
                                buttonColors: (.purple, .blue),
                                nextAction: { showWelcome = true },
                                currentPage: currentPage
                            )
                        }
                    }
                    .animation(.easeInOut, value: currentPage)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .id("onboarding")
                .transition(.slide)
            }
        }
        .animation(.easeInOut, value: showWelcome)
    }
}

struct Onboard: View {
    let title: String
    let features: [FeatureData]
    let description: String
    let buttonTitle: String
    let buttonColors: (Color, Color)
    let nextAction: () -> Void
    let currentPage: Int

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [buttonColors.0.opacity(0.3), buttonColors.1.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 25) {
                    Spacer().frame(height: 25)

                    Image(systemName: "leaf.circle.fill")
                        .resizable()
                        .frame(width: 55, height: 55)
                        .foregroundColor(buttonColors.0)

                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.clear)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [buttonColors.0, buttonColors.1]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .mask(
                                Text(title)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            )
                        )

                    // --- PAGE 1: 4 features, use grid, NO fixed height ---
                    if features.count == 4 {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(features, id: \.title) { feature in
                                FeatureCard(
                                    title: feature.title,
                                    subtitle: feature.subtitle,
                                    systemIcon: feature.icon
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    // --- PAGE 2/3: 3 features, use ZStack, WITH fixed height ---
                    else if features.count == 3 {
                        ZStack {
                            ForEach(Array(features.enumerated()), id: \.1.title) { index, feature in
                                CircleFeatureCard(
                                    title: feature.title,
                                    subtitle: feature.subtitle,
                                    systemIcon: feature.icon,
                                    colors: buttonColors
                                )
                                .offset(
                                    x: index == 1 ? -100 : (index == 2 ? 100 : 0),
                                    y: index == 0 ? -60 : 60
                                )
                            }
                        }
                        .frame(height: 300) // <--- fixed height for circle layout
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }

                    VStack(spacing: 8) {
                        Text("Track • Plan • Save")
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(description)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.black.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }

                Spacer()

                // Fixed position elements
                VStack(spacing: 12) {
                    // Page indicator dots
                    HStack(spacing: 64) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 8)

                    // Button
                    Button(action: nextAction) {
                        Text(buttonTitle)
                            .gradientButtonStyle(color1: buttonColors.0, color2: buttonColors.1)
                    }
                }
                .padding([.horizontal, .bottom])
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, buttonColors.0.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

struct CircleFeatureCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String
    let colors: (Color, Color)
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [colors.0.opacity(0.2), colors.1.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 8)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .white.opacity(0.95)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 156, height: 156)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [colors.0.opacity(0.5), colors.1.opacity(0.5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                VStack(spacing: 8) {
                    Image(systemName: systemIcon)
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [colors.0, colors.1]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(title)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
                .frame(width: 130, height: 130)
            }
        }
        .frame(width: 160, height: 160)
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemIcon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(title)
                .fontWeight(.semibold)
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func gradientButtonStyle(color1: Color, color2: Color) -> some View {
        self
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [color1, color2], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
    }
}
*/

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FeatureData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct OnboardingFlow: View {
    @State private var currentPage = 0
    @State private var showWelcome = false

    var body: some View {
        ZStack {
            if showWelcome {
                WelcomeView()
                    .transition(.opacity)
            } else {
                VStack {
                    if currentPage == 0 {
                        Onboard(
                            title: "Virtual Fridge",
                            features: [
                                FeatureData(title: "Smart Tracking", subtitle: "Control product quantities", icon: "barcode.viewfinder"),
                                FeatureData(title: "Meal Plans", subtitle: "Flexible AI recommendations", icon: "fork.knife"),
                                FeatureData(title: "Zero Waste", subtitle: "Expiry reminders", icon: "bolt.fill"),
                                FeatureData(title: "Analytics", subtitle: "Track calories & quality", icon: "chart.bar.xaxis")
                            ],
                            description: "Plan your meals weekly with ease — no spoiled food, automatic shopping lists, and AI-curated dishes based on your preferences.",
                            buttonTitle: "Next",
                            buttonColors: (.mint, .green),
                            nextAction: { currentPage += 1 },
                            backAction: { if currentPage > 0 { currentPage -= 1 } },
                            currentPage: currentPage
                        )
                    } else if currentPage == 1 {
                        Onboard(
                            title: "Scan & Discover",
                            features: [
                                FeatureData(title: "Fridge Scan", subtitle: "Snap and add products quickly", icon: "camera.viewfinder"),
                                FeatureData(title: "Manual Entry", subtitle: "Add items easily by typing", icon: "keyboard"),
                                FeatureData(title: "Receipt Scan", subtitle: "Fast product lookup", icon: "barcode.viewfinder")
                            ],
                            description: "Use multiple scanning methods to add your groceries seamlessly with speed and precision.",
                            buttonTitle: "Next",
                            buttonColors: (.orange, .red),
                            nextAction: { currentPage += 1 },
                            backAction: { if currentPage > 0 { currentPage -= 1 } },
                            currentPage: currentPage
                        )
                    } else if currentPage == 2 {
                        Onboard(
                            title: "Personalized AI Plans",
                            features: [
                                FeatureData(title: "Custom Recommendations", subtitle: "", icon: "sparkles"),
                                FeatureData(title: "Meal Suggestions", subtitle: "", icon: "lightbulb"),
                                FeatureData(title: "Nutrition Insights", subtitle: "", icon: "heart.fill")
                            ],
                            description: "Get meal plans and tips based on your unique style, dietary needs, and habits using powerful AI technology.",
                            buttonTitle: "Get Started",
                            buttonColors: (.purple, .blue),
                            nextAction: { showWelcome = true },
                            backAction: { if currentPage > 0 { currentPage -= 1 } },
                            currentPage: currentPage
                        )
                    }
                }
                .animation(.easeInOut, value: currentPage)
                .transition(.slide)
            }
        }
        .animation(.easeInOut, value: showWelcome)
    }
}

struct Onboard: View {
    let title: String
    let features: [FeatureData]
    let description: String
    let buttonTitle: String
    let buttonColors: (Color, Color)
    let nextAction: () -> Void
    let backAction: () -> Void
    let currentPage: Int

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [buttonColors.0.opacity(0.3), buttonColors.1.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 25) {
                        Spacer().frame(height: 25)
                        Image(systemName: "leaf.circle.fill")
                            .resizable()
                            .frame(width: 55, height: 55)
                            .foregroundColor(buttonColors.0)
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.clear)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [buttonColors.0, buttonColors.1]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .mask(
                                    Text(title)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                )
                            )
                        if features.count == 4 {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(features, id: \.title) { feature in
                                    FeatureCard(
                                        title: feature.title,
                                        subtitle: feature.subtitle,
                                        systemIcon: feature.icon
                                    )
                                }
                            }
                            .padding(.horizontal)
                        } else if features.count == 3 {
                            ZStack {
                                ForEach(Array(features.enumerated()), id: \.1.title) { index, feature in
                                    CircleFeatureCard(
                                        title: feature.title,
                                        subtitle: feature.subtitle,
                                        systemIcon: feature.icon,
                                        colors: buttonColors
                                    )
                                    .offset(
                                        x: index == 1 ? -100 : (index == 2 ? 100 : 0),
                                        y: index == 0 ? -60 : 60
                                    )
                                }
                            }
                            .frame(height: 300)
                            .padding(.horizontal)
                        }
                        VStack(spacing: 8) {
                            Text("Track • Plan • Save")
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            Text(description)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                }
                // Bottom section
                HStack(spacing: 16) {
                    Button(action: backAction) {
                        Text("Back")
                            .gradientButtonStyle(
                                color1: currentPage == 0 ? .gray.opacity(0.5) : .orange,
                                color2: currentPage == 0 ? .gray.opacity(0.2) : .orange.opacity(0.7)
                            )
                    }
                    .disabled(currentPage == 0)
                    Button(action: nextAction) {
                        Text(buttonTitle)
                            .gradientButtonStyle(color1: buttonColors.0, color2: buttonColors.1)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, buttonColors.0.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}


struct CircleFeatureCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String
    let colors: (Color, Color)
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [colors.0.opacity(0.2), colors.1.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 8)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .white.opacity(0.95)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 156, height: 156)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [colors.0.opacity(0.5), colors.1.opacity(0.5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                VStack(spacing: 8) {
                    Image(systemName: systemIcon)
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [colors.0, colors.1]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(title)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
                .frame(width: 130, height: 130)
            }
        }
        .frame(width: 160, height: 160)
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemIcon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(title)
                .fontWeight(.semibold)
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func gradientButtonStyle(color1: Color, color2: Color) -> some View {
        self
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [color1, color2], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
    }
}



