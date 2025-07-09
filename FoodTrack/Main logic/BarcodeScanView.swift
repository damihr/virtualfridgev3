//
//  BarcodeScanView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 30.06.2025.
//

import SwiftUI

struct BarcodeScanView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }

            Button("Pick Receipt Photo") {
                isPickerPresented = true
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            if selectedImage != nil {
                Button("Analyze and Add Items") {
                    analyzeReceiptImage()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            if isLoading {
                ProgressView("Analyzing...")
            }

            Spacer()
        }
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker(image: $selectedImage)
        }
    }

    private func analyzeReceiptImage() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.6) else { return }
        isLoading = true

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
