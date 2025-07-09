//
//  Planner.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 10.06.2025.
//
/*
import Foundation
import SwiftUI

struct Recipe: Identifiable, Decodable {
    let id: Int
    let title: String
    let image: String
}


struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: recipe.image)) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)

            Text(recipe.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


struct PlannerView: View {
    let items: [FoodItem]
    @State private var lastFetchedItemNames: [String] = []
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var fridgeItemNames: [String] {
        items.map { $0.name }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView("Fetching recipes...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if recipes.isEmpty {
                    VStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Meal Planner")
                            .font(.title).bold()
                        Text("No recipes found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(recipes) { recipe in
                                RecipeCard(recipe: recipe)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Planner")
            .onAppear {
                fetchRecipes()
            }
        }
    }
    
    func fetchRecipes() {
        let currentItemNames = fridgeItemNames.sorted()
        
        // Check if the current items are the same as last fetched
        if currentItemNames == lastFetchedItemNames {
            print("No changes in fridge items, skipping fetch")
            return
        }

        lastFetchedItemNames = currentItemNames
        isLoading = true
        errorMessage = nil

        let ingredients = currentItemNames.joined(separator: ",")
        let urlString = "https://api.spoonacular.com/recipes/findByIngredients?ingredients=\(ingredients)&number=10&apiKey=13db807ad8464b87adbe4849e24fd195"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    errorMessage = "No data"
                    return
                }

                do {
                    recipes = try JSONDecoder().decode([Recipe].self, from: data)
                } catch {
                    errorMessage = "Failed to decode: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
*/



import SwiftUI

struct PlannerView: View {
    let items: [FoodItem]

    @State private var topRecipes: [MyRecipe] = []
    @State private var imageURLs: [UUID: URL] = [:]

    var body: some View {
        NavigationView {
            if topRecipes.isEmpty {
                // Centered empty state
                VStack(spacing: 18) {
                    Text("🛒")
                        .font(.system(size: 64))
                    Text("Add more items to your fridge!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Suggested Recipes")
            } else {
                List {
                    ForEach(topRecipes, id: \.id) { recipe in
                        card(for: recipe)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Suggested Recipes")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: loadAndMatchRecipes)
    }

    // MARK: - Card UI
    @ViewBuilder
    private func card(for recipe: MyRecipe) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = imageURLs[recipe.id] {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(height: 160)
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(height: 160).clipped().cornerRadius(10)
                    default:
                        Color.gray.frame(height: 160).cornerRadius(10)
                    }
                }
            } else {
                Color.gray.opacity(0.2).frame(height: 160).cornerRadius(10)
            }

            Text(recipe.name).font(.headline).foregroundColor(Color.primary)

            if let desc = recipe.description {
                Text(desc).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            }

            Text("Ingredients: \(recipe.ingredients.joined(separator: ", "))")
                .font(.footnote).foregroundColor(Color.secondary)

            // See more button inside the card
            NavigationLink(destination: RecipeDetailView(recipe: recipe, imageURL: imageURLs[recipe.id])) {
                Text("See more ▶︎")
                    .font(.footnote.bold())
                    .foregroundColor(Color.accentColor)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.10))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 1)
        )
    }

    // MARK: - Matching + Images
    private func loadAndMatchRecipes() {
        let fridge = items.map { $0.name.lowercased() }
        let all   = loadRecipesFromJSON()
        topRecipes = getTopMatchingRecipes(from: all, fridgeIngredients: fridge)

        topRecipes.forEach { recipe in
            let query = [recipe.name, recipe.description ?? ""].joined(separator: " ")
            PexelsImageFetcher.shared.fetchImageURL(for: query) { url in
                if let url = url {
                    DispatchQueue.main.async { imageURLs[recipe.id] = url }
                }
            }
        }
    }
}
