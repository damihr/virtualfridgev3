//
//  Recipe.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 27.06.2025.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct MyRecipe: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let ingredients: [String]
    let steps: [String]        // NEW
}

func loadRecipesFromJSON() -> [MyRecipe] {
    guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        print("❌ Couldn’t find recipes.json")
        return []
    }
    do { return try JSONDecoder().decode([MyRecipe].self, from: data) }
    catch { print("❌ Decode error:", error); return [] }
}


func getTopMatchingRecipes(from allRecipes: [MyRecipe], fridgeIngredients: [String]) -> [MyRecipe] {
    let lowercasedFridge = fridgeIngredients.map { $0.lowercased() }

    let scoredRecipes = allRecipes.map { recipe -> (MyRecipe, Int) in
        let matchCount = recipe.ingredients.reduce(0) { count, ingredient in
            let lowerIngredient = ingredient.lowercased()
            return lowercasedFridge.contains(where: { fridgeItem in
                lowerIngredient.contains(fridgeItem) || fridgeItem.contains(lowerIngredient)
            }) ? count + 1 : count
        }
        return (recipe, matchCount)
    }

    return scoredRecipes
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
        .prefix(10)
        .map { $0.0 }
}


struct PexelsPhoto: Decodable {
    let src: PhotoSource
}

struct PhotoSource: Decodable {
    let medium: String
}

struct PexelsResponse: Decodable {
    let photos: [PexelsPhoto]
}

class PexelsImageFetcher {
    static let shared = PexelsImageFetcher()
    private let apiKey = "lgrJMn7RVjrZdbPExkqBVpNNQDaWiuzSTtVgqNw0cibeGqb4X0Y0sxJt"

    func fetchImageURL(for query: String, completion: @escaping (URL?) -> Void) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.pexels.com/v1/search?query=\(queryEncoded)&per_page=1"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  error == nil,
                  let result = try? JSONDecoder().decode(PexelsResponse.self, from: data),
                  let first = result.photos.first else {
                completion(nil)
                return
            }
            completion(URL(string: first.src.medium))
        }.resume()
    }
}
