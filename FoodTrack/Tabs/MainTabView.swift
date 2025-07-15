//
//  MainTabView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 10.06.2025.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var items: [FoodItem] = []
    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(items: $items)
                .tabItem {
                    Label("Fridge", systemImage: "snowflake")
                }
                .tag(0)
            
            PlannerView(items: items)
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
                .tag(1)
            
            OverviewView(items: items)
                .tabItem {
                    Label("Overview", systemImage: "chart.pie.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(3)
            
        }
        .accentColor(.green)
        .onAppear {
            // Make unselected tabs gray
            let appearance = UITabBarAppearance()
            appearance.stackedLayoutAppearance.normal.iconColor = .gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

