//
//  ManualInputView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 30.06.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ManualInputView: View {
    var onAdd: (FoodItem) -> Void
    @Environment(\.presentationMode) var presentationMode

    // Form state
    @State private var name = ""
    @State private var quantity = 1
    @State private var unit = "pieces"
    @State private var category = "Other"
    @State private var expirationDate = Date()
    @State private var showDatePicker = false

    // Constants
    let units = ["pieces", "kg", "lbs", "liters"]
    let categories = ["Other", "Dairy", "Meat", "Vegetable", "Fruits", "Grains", "Beverage", "Seafood"]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Product Name")
                    .font(.subheadline).bold()
                    .foregroundColor(.black)
                TextField("e.g., Organic Milk", text: $name)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(height: 48)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quantity")
                        .font(.subheadline).bold()
                        .foregroundColor(.black)
                    TextField("", value: $quantity, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(height: 48)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit")
                        .font(.subheadline).bold()
                        .foregroundColor(.black)
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
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(height: 48)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline).bold()
                    .foregroundColor(.black)
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
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(height: 48)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Expiration Date")
                    .font(.subheadline).bold()
                    .foregroundColor(.black)
                Button(action: { showDatePicker.toggle() }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(dateFormatter.string(from: expirationDate))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(14)
                    .background(Color(.systemGray6))
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

            Spacer()

            HStack(spacing: 16) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)

                Button("Add Item") {
                    addItemToFirestore()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    private func addItemToFirestore() {
        let item = FoodItem(name: name, quantity: quantity, unit: unit, category: category, expiration: expirationDate)
        let db = Firestore.firestore()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).collection("foodItems").document(item.id.uuidString).setData(item.toDictionary()) { error in
            if let error = error {
                print("Error adding item: \(error)")
            } else {
                print("Item added")
                onAdd(item)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
} 
