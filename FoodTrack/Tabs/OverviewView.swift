//
//  OverviewView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 10.07.2025.
//

import SwiftUI
import Charts

struct OverviewView: View {
    let items: [FoodItem]
    @Environment(\.colorScheme) var colorScheme
    // All possible categories (from FoodItem)
    let allCategories = ["Dairy", "Meat", "Vegetable", "Fruits", "Grains", "Beverage", "Seafood", "Other"]
    
    struct CategoryStat: Identifiable {
        let id = UUID()
        let category: String
        let count: Int
        let percentage: Int
        let color: Color
    }
    
    var categoryStats: [CategoryStat] {
        let total = max(items.count, 1)
        let palette: [Color] = [.blue, .green, .orange, .red, .purple, .yellow, .pink, .gray]
        return allCategories.enumerated().compactMap { idx, cat in
            let count = items.filter { $0.category.caseInsensitiveCompare(cat) == .orderedSame }.count
            guard count > 0 else { return nil }
            let percent = Int(round(Double(count) / Double(total) * 100))
            return CategoryStat(category: cat, count: count, percentage: percent, color: palette[idx % palette.count])
        }
    }
    
    var totalItems: Int { items.count }
    var expiredItems: Int {
        let now = Date()
        return items.filter { $0.expiration < now }.count
    }
    var nonExpiredItems: [FoodItem] {
        let now = Date()
        return items.filter { $0.expiration >= now }
    }
    var averageDaysToExpire: Double {
        let now = Date()
        let days = nonExpiredItems.map { Double($0.daysUntilExpiration(from: now)) }
        guard !days.isEmpty else { return 0 }
        return days.reduce(0, +) / Double(days.count)
    }
    var mostCommonType: String {
        categoryStats.max(by: { $0.count < $1.count })?.category ?? "-"
    }
    var diversityScore: Double {
        let unique = Set(items.map { $0.category.lowercased() })
        return Double(unique.count) / Double(allCategories.count)
    }
    var diversityText: String {
        let score = diversityScore
        switch score {
        case 0.8...: return "Excellent"
        case 0.5..<0.8: return "Good"
        case 0.3..<0.5: return "Fair"
        default: return "Low"
        }
    }
    var suggestion: String {
        let missing = allCategories.filter { cat in !items.contains { $0.category.caseInsensitiveCompare(cat) == .orderedSame } }
        if let first = missing.first { return "Consider adding more \(first.lowercased()) items for a balanced fridge!" }
        return "Your fridge is well balanced!"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Overview")
                    .font(.largeTitle).bold()
                    .padding(.top)
                    .padding(.leading, 8)
                
                // Pie Chart Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Food Type Breakdown")
                        .font(.title2).bold()
                        .padding(.bottom, 2)
                    Text("Percentage by category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .center, spacing: 24) {
                        Chart(categoryStats) { entry in
                            SectorMark(
                                angle: .value("Count", entry.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(entry.color)
                            .annotation(position: .overlay, alignment: .center) {
                                if entry.percentage > 7 { // Only show label if big enough
                                    Text("\(entry.percentage)%")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(width: 180, height: 180)
                        .padding(.vertical, 8)
                        
                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(categoryStats) { entry in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(entry.color)
                                        .frame(width: 14, height: 14)
                                    Text(entry.category)
                                        .font(.subheadline)
                                    Text("\(entry.percentage)%")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 4)
                
                // Key Metrics Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("General")
                        .font(.title2).bold()
                    HStack(spacing: 24) {
                        metricCard(title: "Most Common Type", value: mostCommonType, color: .purple)
                        metricCard(title: "Expired Items", value: "\(expiredItems)", color: .red)
                        metricCard(title: "Avg. Days to Expire", value: String(format: "%.0f", averageDaysToExpire), color: .green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 4)
                
                // Fridge Status Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fridge Status")
                        .font(.title2).bold()
                    HStack(spacing: 24) {
                        metricCard(title: "Diversity Score", value: String(format: "%.0f%%", diversityScore * 100), color: .orange)
                        metricCard(title: "Status", value: diversityText, color: .orange)
                        metricCard(title: "Total Items", value: "\(totalItems)", color: .blue)
                    }
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .green : .black)
                        .padding(.top, 4)

                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 4)
                
                Spacer(minLength: 24)
            }
            .padding(.bottom, 16)
        }
    }
    
    // Helper for metric cards
    func metricCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.08), radius: 2, x: 0, y: 1)
        )
    }
} 
