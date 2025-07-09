//
//  FridgeView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 06.06.2025.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme

    @State private var isShowingAddItem = false
    @State private var selectedAddMethod: AddMethod = .manual
    @Binding var items: [FoodItem]

    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"

    let db = Firestore.firestore()
    let userID = Auth.auth().currentUser?.uid ?? "defaultUser"

    let categories = ["All", "Meat", "Dairy", "Vegetable", "Fruits", "Seafood", "Beverage", "Grains", "Other"]

    var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var filteredItems: [FoodItem] {
        items.filter { item in
            (selectedCategory == "All" || item.category.caseInsensitiveCompare(selectedCategory) == .orderedSame)
            && (searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    var sortedFilteredItems: [FoodItem] {
        filteredItems.sorted {
            $0.daysUntilExpiration(from: today) < $1.daysUntilExpiration(from: today)
        }
    }

    var expiringCount: Int {
        filteredItems.filter { $0.daysUntilExpiration(from: today) <= 2 && $0.daysUntilExpiration(from: today) >= 0 }.count
    }

    var expiredCount: Int {
        filteredItems.filter { $0.daysUntilExpiration(from: today) < 0 }.count
    }

    var body: some View {
        if colorScheme == .dark {
            // 🌑 Dark Mode Design
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Fridge")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        Text("\(filteredItems.count) items • \(expiringCount) expiring • \(expiredCount) expired")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                    // Modern Add Item Button (smaller text, less bold)
                    Button(action: {
                        isShowingAddItem = true
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Add Item")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color.blue.opacity(0.13), radius: 4, x: 0, y: 1)
                        .accessibilityLabel("Add a new food item")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .padding(.bottom, 8)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search your fridge...", text: $searchText)
                        .foregroundColor(.white)
                    CategoryPickerViewDark(categories: categories, selectedCategory: $selectedCategory)
                }
                .padding(12)
                .background(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if expiredCount > 0 || expiringCount > 0 {
                    HStack(spacing: 8) {
                        if expiredCount > 0 {
                            Text("\(expiredCount) expired")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.red.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                                .cornerRadius(16)

                        }
                        if expiringCount > 0 {
                            Text("\(expiringCount) expiring soon")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(16)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sortedFilteredItems) { item in
                            if let index = items.firstIndex(where: { $0.id == item.id }) {
                                FoodCard(item: $items[index], today: today) {
                                    deleteItemFromFirestore(item)
                                    items.remove(at: index)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteItemFromFirestore(item)
                                        items.remove(at: index)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $isShowingAddItem, onDismiss: {
                loadItemsFromFirestore()
            }) {
                AddItemView(selectedMethod: $selectedAddMethod) { _ in }
            }
            .onAppear(perform: loadItemsFromFirestore)

        } else {
            // ☀️ Light Mode Design (your original)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Fridge")
                            .font(.largeTitle).bold()
                        Text("\(filteredItems.count) items • \(expiringCount) expiring • \(expiredCount) expired")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                    // Modern Add Item Button (smaller text, less bold)
                    Button(action: {
                        isShowingAddItem = true
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Add Item")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color.green.opacity(0.13), radius: 4, x: 0, y: 1)
                        .accessibilityLabel("Add a new food item")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .padding(.bottom, 8)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search your fridge...", text: $searchText)
                        .foregroundColor(.primary)
                    CategoryPickerView(categories: categories, selectedCategory: $selectedCategory)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.04), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if expiredCount > 0 || expiringCount > 0 {
                    HStack(spacing: 8) {
                        if expiredCount > 0 {
                            Text("\(expiredCount) expired")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.red)
                                .cornerRadius(16)
                        }
                        if expiringCount > 0 {
                            Text("\(expiringCount) expiring soon")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(16)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sortedFilteredItems) { item in
                            if let index = items.firstIndex(where: { $0.id == item.id }) {
                                FoodCard(item: $items[index], today: today) {
                                    deleteItemFromFirestore(item)
                                    items.remove(at: index)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteItemFromFirestore(item)
                                        items.remove(at: index)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $isShowingAddItem, onDismiss: {
                loadItemsFromFirestore()
            }) {
                AddItemView(selectedMethod: $selectedAddMethod) { _ in }
            }
            .onAppear(perform: loadItemsFromFirestore)
        }
    }

    func loadItemsFromFirestore() {
        db.collection("foodItems")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading items: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                items = documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let name = data["name"] as? String,
                        let quantity = data["quantity"] as? Int,
                        let unit = data["unit"] as? String,
                        let category = data["category"] as? String,
                        let expiration = (data["expiration"] as? Timestamp)?.dateValue()
                    else {
                        return nil
                    }

                    return FoodItem(
                        id: UUID(),
                        documentID: doc.documentID,
                        name: name,
                        quantity: quantity,
                        unit: unit,
                        category: category,
                        expiration: expiration
                    )
                }
            }
    }

    func deleteItemFromFirestore(_ item: FoodItem) {
        db.collection("foodItems").document(item.documentID!).delete()
    }
}

// Light mode version
struct CategoryPickerView: View {
    let categories: [String]
    @Binding var selectedCategory: String

    var body: some View {
        Menu {
            ForEach(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    Label(category, systemImage: selectedCategory == category ? "checkmark" : "")
                        .labelStyle(TitleOnlyLabelStyle())
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCategory)
                    .foregroundColor(.black)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(Color(.systemGray5))
            .cornerRadius(10)
        }
    }
}

// Dark mode version
struct CategoryPickerViewDark: View {
    let categories: [String]
    @Binding var selectedCategory: String

    var body: some View {
        Menu {
            ForEach(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    Label(category, systemImage: selectedCategory == category ? "checkmark" : "")
                        .labelStyle(TitleOnlyLabelStyle())
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCategory)
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
}
