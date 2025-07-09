//
//  AddItemView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 06.06.2025.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum AddMethod: String, CaseIterable {
    case manual = "Manual"
    case receipt = "Receipt"
    case photo = "Photo"
}

struct AddItemView: View {
    @Binding var selectedMethod: AddMethod
    var onAdd: (FoodItem) -> Void
    @Environment(\.presentationMode) var presentationMode

    // Manual input
    @State private var name = ""
    @State private var quantity = 1
    @State private var unit = "pieces"
    @State private var category = "Other"
    @State private var expirationDate = Date()
    @State private var showDatePicker = false

    let units = ["pieces", "kg", "lbs", "liters"]
    let categories = ["Other", "Dairy", "Meat", "Vegetable", "Fruits", "Grains", "Beverage", "Seafood"]

    @State private var showSuccessAlert = false
    @State private var isImageStep = false
    @State private var isAdding = false
    @State private var showPhotoSourceDialog = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemBackground).ignoresSafeArea() // Use system background for dark mode
            ScrollView { // Added ScrollView for iPad compatibility
                VStack(spacing: 0) {
                    // Title and close button
                    HStack {
                        Spacer()
                        Text("Add Food Item")
                            .font(.title2).bold()
                            .foregroundColor(Color.primary) // Use dynamic color
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

                    // Picker for add method
                    HStack {
                        Picker("Add Method", selection: $selectedMethod) {
                            ForEach(AddMethod.allCases, id: \.self) { method in
                                Text(method.rawValue)
                                    .font(.system(size: 26, weight: .heavy))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(height: 88)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 22)

                    // Selected input view
                    Group {
                        if selectedMethod == .manual {
                            manualInputView
                        } else if selectedMethod == .receipt {
                            receiptView
                        } else if selectedMethod == .photo {
                            photoView
                        }
                    }
                }
            }
        }
    }

    
    
    
    
    
    
    
    
    
    
    //#MARK
    private var manualInputView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Product Name")
                    .font(.subheadline).bold()
                    .foregroundColor(Color.primary)
                TextField("e.g., Organic Milk", text: $name)
                    .padding(14)
                    .background(Color(.secondarySystemBackground)) // dynamic
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5) // more gray outline
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
                    TextField("", value: $quantity, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .padding(14)
                        .background(Color(.secondarySystemBackground)) // dynamic
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5) // more gray outline
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
                        .background(Color(.secondarySystemBackground)) // dynamic
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5) // more gray outline
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
                    .background(Color(.secondarySystemBackground)) // dynamic
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5) // more gray outline
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
                    .background(Color(.secondarySystemBackground)) // dynamic
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1.5) // more gray outline
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
                .disabled(isAdding) // always enabled unless adding

                Button(action: {
                    isAdding = true
                    let item = FoodItem(name: name, quantity: quantity, unit: unit, category: category, expiration: expirationDate)
                    let db = Firestore.firestore()
                    db.collection("foodItems").document(item.id.uuidString).setData(item.toDictionary()) { error in
                        if let error = error {
                            print("Error adding item: \(error)")
                            isAdding = false
                        } else {
                            print("Item added")
                            onAdd(item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                presentationMode.wrappedValue.dismiss()
                                isAdding = false
                            }
                        }
                    }
                }) {
                    HStack {
                        if isAdding {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isAdding ? "Adding..." : "Add Item")
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.accentColor) // Use accent color for button
                .cornerRadius(10)
                .disabled(isAdding || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    
    
    
    
    
    
    
    
    
    private var receiptView: some View {
        VStack(spacing: 32) {
            Spacer()
            if let image = selectedImage, isImageStep {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .cornerRadius(14)
                        .shadow(radius: 4)
                    Button(action: {
                        isAdding = true
                        analyzeImage1()
                    }) {
                        HStack {
                            if isAdding { ProgressView() }
                            Text(isAdding ? "Adding..." : "Analyze and Add Items")
                        }
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isAdding)
                    Button("Back") {
                        selectedImage = nil
                        isImageStep = false
                    }
                    .foregroundColor(Color.secondary)
                    .padding(.top, 4)
                }
            } else {
                VStack(spacing: 12) {
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        Image(systemName: "doc.text.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(Color.accentColor)
                    }
                    Text("Scan Your Receipt")
                        .font(.title3).bold()
                        .foregroundColor(Color.primary)
                    Text("Quickly add items by scanning your grocery receipt. We'll extract all food items for you!")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                Button(action: {
                    showPhotoSourceDialog = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Pick or Take Photo")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.mint]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
                .confirmationDialog("Select Photo Source", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button("Take Photo") { isCameraPickerPresented = true }
                    }
                    Button("Choose from Gallery") { isPickerPresented = true }
                    Button("Cancel", role: .cancel) { }
                }
            }
            if isLoading {
                ProgressView("Analyzing...")
            }
            Spacer()
        }
        .padding(.horizontal)
        .sheet(isPresented: $isPickerPresented, onDismiss: { if selectedImage != nil { isImageStep = true } }) {
            PhotoPicker(image: $selectedImage)
        }
        .sheet(isPresented: $isCameraPickerPresented, onDismiss: { if selectedImage != nil { isImageStep = true } }) {
            CameraPicker(image: $selectedImage)
        }
        .alert("Items added!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                selectedImage = nil
                isImageStep = false
                isAdding = false
            }
        }
    }

    @State private var selectedImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var isLoading = false
    @State private var isCameraPickerPresented = false

    private var photoView: some View {
        VStack(spacing: 32) {
            Spacer()
            if let image = selectedImage, isImageStep {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .cornerRadius(14)
                        .shadow(radius: 4)
                    Button(action: {
                        isAdding = true
                        analyzeImage()
                    }) {
                        HStack {
                            if isAdding { ProgressView() }
                            Text(isAdding ? "Adding..." : "Analyze and Add Items")
                        }
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isAdding)
                    Button("Back") {
                        selectedImage = nil
                        isImageStep = false
                    }
                    .foregroundColor(Color.secondary)
                    .padding(.top, 4)
                }
            } else {
                VStack(spacing: 12) {
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.18), Color.mint.opacity(0.18)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(Color.accentColor)
                    }
                    Text("Fridge Photo Scan")
                        .font(.title3).bold()
                        .foregroundColor(Color.primary)
                    Text("Snap a photo of your fridge and let AI detect all the food items inside!")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                Button(action: {
                    isPickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Pick or Take Photo")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.mint]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            if isLoading {
                ProgressView("Analyzing...")
            }
            Spacer()
        }
        .padding(.horizontal)
        .sheet(isPresented: $isPickerPresented, onDismiss: { if selectedImage != nil { isImageStep = true } }) {
            PhotoPicker(image: $selectedImage)
        }
        .alert("Items added!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                selectedImage = nil
                isImageStep = false
                isAdding = false
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private func analyzeImage1() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.6) else { return }
        isLoading = true
        isAdding = true

        let base64Image = imageData.base64EncodedString()

        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are an expert assistant that extracts useful grocery items from receipts."],
            ["role": "user", "content": [
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)"
                    ]
                ],
                [
                    "type": "text",
                    "text": """
                    Extract all edible items from this receipt. Return only valid food items in JSON format like this:
                    [{"name":"Banana", "quantity":5, "unit":"pieces", "category":"Fruits", "expiration_days":5}]
                    Assume default expiration based on possible categories: Fruits, Vegetable, Grains, Beverage, Meat, Dairy, Seafood or Other. units can be: pieces, kg, lbs , liters.  Ignore brands and additional information, use only integers for unit. Combine multiple products by units if same are met.
                    """
                ]
            ]]
        ]

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 1500,
            "temperature": 0.4
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isAdding = false
            }

            if let data = data,
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = result["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {

                print("✅ Response:\n\(content)")

                if let jsonData = extractAndFixJSON(from: content) {
                    do {
                        let parsedItems = try JSONDecoder().decode([ParsedItem].self, from: jsonData)
                        saveItemsToFirestore(parsedItems)
                        print("✅ Parsed \(parsedItems.count) item(s) successfully")
                        DispatchQueue.main.async { showSuccessAlert = true }
                    } catch {
                        print("❌ JSON decode error: \(error.localizedDescription)")
                        print("🧪 Tried JSON:\n\(String(data: jsonData, encoding: .utf8) ?? "")")
                    }
                } else {
                    print("❌ Failed to extract or repair JSON")
                    print("🧪 Full content:\n\(content)")
                }

            } else {
                print("❌ Network or response error")
                if let data = data,
                   let raw = String(data: data, encoding: .utf8) {
                    print("🪵 Raw response:\n\(raw)")
                } else if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func analyzeImage() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.6) else { return }
        isLoading = true
        isAdding = true

        let base64Image = imageData.base64EncodedString()

        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a helpful assistant that identifies fridge food items from photos."],
            ["role": "user", "content": [
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)"
                    ]
                ],
                [
                    "type": "text",
                    "text": """
                    Analyze this fridge photo. List all edible items in JSON like:
                    [{"name":"Milk", "quantity":1, "unit":"liters", "category":"Dairy", "expiration_days":7}]
                    Assume default expiration based on possible categories: Fruits, Vegetable, Grains, Beverage, Meat, Dairy, Seafood or Other. units can be: pieces, kg, lbs , liters. Ignore brands and additional information, use only integers for unit. Combine multiple products by units if same are met.
                    """
                ]
            ]]
        ]

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 1500,
            "temperature": 0.4
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isAdding = false
            }

            if let data = data,
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = result["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {

                print("✅ Response:\n\(content)")

                if let jsonData = extractAndFixJSON(from: content) {
                    do {
                        let parsedItems = try JSONDecoder().decode([ParsedItem].self, from: jsonData)
                        saveItemsToFirestore(parsedItems)
                        print("✅ Parsed \(parsedItems.count) item(s) successfully")
                        DispatchQueue.main.async { showSuccessAlert = true }
                    } catch {
                        print("❌ JSON decode error: \(error.localizedDescription)")
                        print("🧪 Tried JSON:\n\(String(data: jsonData, encoding: .utf8) ?? "")")
                    }
                } else {
                    print("❌ Failed to extract or repair JSON")
                    print("🧪 Full content:\n\(content)")
                }

            } else {
                print("❌ Network or response error")
                if let data = data,
                   let raw = String(data: data, encoding: .utf8) {
                    print("🪵 Raw response:\n\(raw)")
                } else if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

struct ParsedItem: Codable {
    let name: String
    let quantity: Int
    let unit: String
    let category: String
    let expiration_days: Int
}

func saveItemsToFirestore(_ items: [ParsedItem]) {
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid ?? "defaultUser"

    for item in items {
        let expirationDate = Calendar.current.date(byAdding: .day, value: item.expiration_days, to: Date())!
        let foodItem = FoodItem(name: item.name,
                                quantity: item.quantity,
                                unit: item.unit,
                                category: item.category,
                                expiration: expirationDate)
        db.collection("foodItems").document(foodItem.id.uuidString).setData(foodItem.toDictionary()) { error in
            if let error = error {
                print("❌ Error saving item: \(error)")
            }
        }
    }
}

func extractAndFixJSON(from text: String) -> Data? {
    guard let startIndex = text.firstIndex(of: "[") else { return nil }
    let partial = String(text[startIndex...])

    // Try to match full JSON array with regex
    let pattern = #"\{[^}]*\}"#
    let regex = try? NSRegularExpression(pattern: pattern)
    let matches = regex?.matches(in: partial, range: NSRange(partial.startIndex..., in: partial)) ?? []

    var objects: [String] = []
    for match in matches {
        if let range = Range(match.range, in: partial) {
            let object = partial[range]
            objects.append(String(object))
        }
    }

    let finalJSON = "[\(objects.joined(separator: ","))]"
    return finalJSON.data(using: .utf8)
}


// MARK: - Firestore Remote Config Fetch

func loadOpenAIKey(completion: @escaping (String?) -> Void) {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let key = dict["OpenAI_API_Key"] as? String, !key.isEmpty else {
        print("❌ Failed to load OpenAI API Key from Secrets.plist")
        completion(nil)
        return
    }

    print("✅ Loaded OpenAI API Key from Secrets.plist")
    completion(key)
}



struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
