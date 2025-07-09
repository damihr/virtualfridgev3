//
//  PlannerView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 27.06.2025.
//


import SwiftUI

struct PlannerView: View {
    let items: [FoodItem]

    @State private var topRecipes: [MyRecipe] = []
    @State private var imageURLs: [UUID: URL] = [:]

    var body: some View {
        NavigationView {
            List {
                ForEach(topRecipes, id: \.id) { recipe in
           ZStack(alignment: .bottomTrailing) {
                        // ⬇︎ MAIN CARD
                        card(for: recipe)

                        // ⬇︎ “See more” link (bottom‑right)
                        NavigationLink(destination: RecipeDetailView(recipe: recipe,
                                                                      imageURL: imageURLs[recipe.id])) {
                            Text("See more ▶︎")
                                .underline()
                                .font(.footnote)
                                .foregroundColor(.black)
                                .padding(6)
                        }
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(6)
                        .offset(x: -8, y: -8)
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Suggested Recipes")
            .onAppear(perform: loadAndMatchRecipes)
        }
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

            Text(recipe.name).font(.headline)

            if let desc = recipe.description {
                Text(desc).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            }

            Text("Ingredients: \(recipe.ingredients.joined(separator: \", \"))")
                .font(.footnote).foregroundColor(.gray)
        }
        .padding(.vertical, 8)
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
