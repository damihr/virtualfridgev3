//
//  RecipeDetailView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 27.06.2025.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: MyRecipe
    let imageURL: URL?

    var body: some View {
        ScrollView {
            // Image
            if let url = imageURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.gray.opacity(0.2) }
                .frame(height: 240).clipped()
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.name)
                    .font(.largeTitle).bold()

                if let desc = recipe.description {
                    Text(desc)
                }

                // Ingredients
                if !recipe.ingredients.isEmpty {
                    Text("Ingredients")
                        .font(.title3).bold().padding(.top, 8)
                    ForEach(recipe.ingredients, id: \.self) { ing in
                        Text("• \(ing)")
                    }
                }

                // Steps
                if !recipe.steps.isEmpty {
                    Text("Steps")
                        .font(.title3).bold().padding(.top, 8)
                    ForEach(Array(recipe.steps.enumerated()), id: \.0) { idx, step in
                        Text("\(idx + 1). \(step)")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
