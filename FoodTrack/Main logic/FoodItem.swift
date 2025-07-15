//
//  FoodItem.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 06.06.2025.
// AIzaSyCtlckQtcbhIHlM-UUxYz8uSIRsENXXUgU


import SwiftUI
import FirebaseFirestore
import FirebaseAuth
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct FoodItem: Identifiable, Equatable {
    let id: UUID
    var documentID: String? // Optional in case it's not assigned yet
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var expiration: Date

    init(id: UUID = UUID(), documentID: String? = nil, name: String, quantity: Double, unit: String, category: String, expiration: Date) {
        self.id = id
        self.documentID = documentID
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.expiration = expiration
    }

    func daysUntilExpiration(from date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: expiration)).day ?? 0
    }

}

extension FoodItem {
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "quantity": quantity,
            "unit": unit,
            "category": category,
            "expiration": Timestamp(date: expiration),
            "userID": Auth.auth().currentUser?.uid ?? "defaultUser"
        ]
    }
}

struct FoodCard: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var item: FoodItem
    let today: Date
    var onRemove: () -> Void

    @State private var showDetails = false
    @State private var showEditSheet = false

    var categoryIcon: String {
        switch item.category.lowercased() {
        case "dairy": return "cart"
        case "meat": return "hare"
        case "vegetable": return "carrot"
        case "fruits": return "apple.logo"
        case "beverage": return "takeoutbag.and.cup.and.straw"
        case "grains": return "leaf.circle"
        case "seafood": return "tortoise"
        default: return "shippingbox.fill"
        }
    }

    var daysLeft: Int { item.daysUntilExpiration(from: today) }

    var badge: some View {
        Group {
            if daysLeft < 0 {
                Text("Expired")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
            } else if daysLeft <= 2 {
                Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s") left")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 1)
                    )
            } else {
                Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s") left")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green, lineWidth: 1)
                    )
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 44, height: 44)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 22))
                        .foregroundColor(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    Text("\(String(format: item.quantity.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", item.quantity)) \(item.unit) • \(item.category)")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                    Text("Exp: " + item.expiration.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(daysLeft < 0 ? .red : Color.secondary)
                }

                Spacer()
                badge
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut) {
                    showDetails.toggle()
                }
            }

            if showDetails {
                Divider()
                HStack(spacing: 12) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Text("Edit")
                            .font(.footnote.bold())
                            .foregroundColor(Color.accentColor)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor.opacity(0.13))
                            .cornerRadius(10)
                    }

                    Button {
                        onRemove()
                    } label: {
                        Text("Remove")
                            .font(.footnote.bold())
                            .foregroundColor(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.13))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5)
        )
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: colorScheme == .dark ? 0.18 : 0.06), radius: 6, x: 0, y: 2)
        .sheet(isPresented: $showEditSheet) {
            EditFoodView(originalItem: item) { updatedItem in
                item = updatedItem
            }
        }
    }
}













struct EditFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    var originalItem: FoodItem
    var onUpdate: (FoodItem) -> Void

    @State private var name: String
    @State private var quantity: Double
    @State private var unit: String
    @State private var category: String
    @State private var expirationDate: Date
    @State private var showDatePicker = false

    let units = ["pieces", "kg", "lbs", "liters", "ml", "oz", "pt"]
    let categories = ["Other", "Dairy", "Meat", "Vegetable", "Fruits", "Grains", "Beverage", "Seafood"]

    init(originalItem: FoodItem, onUpdate: @escaping (FoodItem) -> Void) {
        self.originalItem = originalItem
        self.onUpdate = onUpdate
        _name = State(initialValue: originalItem.name)
        _quantity = State(initialValue: originalItem.quantity)
        _unit = State(initialValue: originalItem.unit)
        _category = State(initialValue: originalItem.category)
        _expirationDate = State(initialValue: originalItem.expiration)
    }

    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Edit Food Item")
                        .font(.title2).bold()
                        .foregroundColor(Color.primary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.secondary)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                .padding(.horizontal)

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Product Name")
                            .font(.subheadline).bold()
                            .foregroundColor(Color.primary)
                        TextField("e.g., Organic Milk", text: $name)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5)
                            )
                            .cornerRadius(10)
                            .frame(height: 48)
                            .foregroundColor(Color.primary)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quantity")
                                .font(.subheadline).bold()
                                .foregroundColor(Color.primary)
                            TextField("", value: $quantity, formatter: decimalFormatter)
                                .keyboardType(.decimalPad)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5)
                                )
                                .cornerRadius(10)
                                .frame(height: 48)
                                .foregroundColor(Color.primary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unit")
                                .font(.subheadline).bold()
                                .foregroundColor(Color.primary)
                            Menu {
                                ForEach(units, id: \.self) { u in
                                    Button(u) { unit = u }
                                }
                            } label: {
                                HStack {
                                    Text(unit)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5)
                                )
                                .cornerRadius(10)
                                .frame(height: 48)
                                .foregroundColor(Color.primary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.subheadline).bold()
                            .foregroundColor(Color.primary)
                        Menu {
                            ForEach(categories, id: \.self) { c in
                                Button(c) { category = c }
                            }
                        } label: {
                            HStack {
                                Text(category)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5)
                            )
                            .cornerRadius(10)
                            .frame(height: 48)
                            .foregroundColor(Color.primary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expiration Date")
                            .font(.subheadline).bold()
                            .foregroundColor(Color.primary)
                        Button(action: { showDatePicker.toggle() }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(dateFormatter.string(from: expirationDate))
                                    .foregroundColor(Color.primary)
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5)
                            )
                            .cornerRadius(10)
                            .frame(height: 48)
                        }
                        .sheet(isPresented: $showDatePicker) {
                            VStack {
                                DatePicker("Pick a date", selection: $expirationDate, displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .padding()
                                Button("Done") { showDatePicker = false }
                                    .padding()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                HStack(spacing: 16) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1.5)
                    )
                    .cornerRadius(10)

                    Button("Save Changes") {
                        let updated = FoodItem(
                            id: originalItem.id,
                            documentID: originalItem.documentID,
                            name: name,
                            quantity: quantity,
                            unit: unit,
                            category: category,
                            expiration: expirationDate
                        )
                        
                        let db = Firestore.firestore()
                        guard let docID = originalItem.documentID else {
                            print("Missing document ID, cannot update Firestore item.")
                            return
                        }
                        let data: [String: Any] = [
                            "name": updated.name,
                            "quantity": updated.quantity,
                            "unit": updated.unit,
                            "category": updated.category,
                            "expiration": Timestamp(date: updated.expiration),
                            "userID": Auth.auth().currentUser?.uid ?? "defaultUser"
                        ]
                        
                        db.collection("foodItems").document(docID).setData(data, merge: true) { error in
                            if let error = error {
                                print("Error updating item: \(error)")
                            } else {
                                print("Item updated")
                            }
                        }

                        onUpdate(updated)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }
}


