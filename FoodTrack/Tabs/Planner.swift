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
import Combine

struct PlannerView: View {
    let items: [FoodItem]
    class PlannerViewModel: ObservableObject {
        @Published var searchText: String = ""
    }
    @StateObject private var viewModel = PlannerViewModel()

    @State private var currentPageRecipes: [MyRecipe] = []
    @State private var imageURLs: [UUID: URL] = [:]
    @State private var currentPage: Int = 0
    @State private var isLoading: Bool = false
    @State private var totalRecipesCount: Int = 0
    @State private var sortMode: SortMode = .topMatching

    private let pageSize = 10
    private var totalPages: Int { max(1, (totalRecipesCount + pageSize - 1) / pageSize) }
    private var fridgeItems: [String] { items.map { $0.name.lowercased() } }

    @Environment(\.colorScheme) var colorScheme
    @State private var searchCancellable: AnyCancellable?

    enum SortMode: String, CaseIterable, Identifiable {
        case topMatching = "Top matching"
        case topMissing = "Top missing"
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Suggested Recipes")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        TextField("Search recipes...", text: $viewModel.searchText)
                            .padding(10)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .background(colorScheme == .dark ? Color(.systemGray5).opacity(0.25) : Color(.systemGray6))
                    .cornerRadius(12)

                    Menu {
                        ForEach(SortMode.allCases) { mode in
                            Button(mode.rawValue) {
                                sortMode = mode
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sortMode.rawValue)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color(.systemGray5))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                if isLoading {
                    Spacer()
                    ProgressView("Loading recipes...")
                    Spacer()
                } else if currentPageRecipes.isEmpty {
                    VStack(spacing: 18) {
                        Text("🛒")
                            .font(.system(size: 64))
                        Text("No matching recipes found.")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(currentPageRecipes, id: \.id) { recipe in
                            card(for: recipe)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)

                    // Pagination Controls
                    HStack(spacing: 8) {
                        Button(action: { changePage(to: currentPage - 1) }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                                    .font(.callout)
                            }
                            .foregroundColor(currentPage == 0 ? .gray : (colorScheme == .dark ? .green : .black))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .disabled(currentPage == 0)

                        Text("Page \(currentPage + 1) out of \(totalPages)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)

                        Button(action: { changePage(to: currentPage + 1) }) {
                            HStack {
                                Text("Next")
                                    .font(.callout)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor((currentPage + 1) >= totalPages ? .gray : (colorScheme == .dark ? .green : .black))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .disabled((currentPage + 1) >= totalPages)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadPage(0)
            setupSearchDebounce()
        }
        .onChange(of: sortMode) { _ in
            loadPage(0)
        }
    }

    private func setupSearchDebounce() {
        searchCancellable = viewModel.$searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { _ in
                loadPage(0)
            }
    }

    @ViewBuilder
    private func card(for recipe: MyRecipe) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = imageURLs[recipe.id] {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(height: 160)
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(height: 160).clipped().cornerRadius(10)
                    default:
                        Color.gray.frame(height: 160).cornerRadius(10)
                    }
                }
            } else {
                Color.gray.opacity(0.2).frame(height: 160).cornerRadius(10)
                    .overlay(ProgressView().frame(height: 160))
                    .onAppear {
                        fetchImage(for: recipe)
                    }
            }

            Text(recipe.name)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            if let desc = recipe.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    .lineLimit(2)
            }

            Text("Ingredients:")
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            Text(ingredientListColored(recipe: recipe))
                .font(.footnote)

            NavigationLink(destination: RecipeDetailView(recipe: recipe, imageURL: imageURLs[recipe.id])) {
                Text("Cook it! ▶︎")
                    .font(.footnote.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(
                        colorScheme == .dark ? Color.green : Color.blue
                    )
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

    private func ingredientListColored(recipe: MyRecipe) -> AttributedString {
        var result = AttributedString("")
        let fridgeItems = self.fridgeItems
        for (i, ing) in recipe.ingredients.enumerated() {
            var attr = AttributedString(ing)
            let isPresent = fridgeItems.contains { ing.lowercased().contains($0) || $0.contains(ing.lowercased()) }
            attr.foregroundColor = isPresent ? .green : .red
            result.append(attr)
            if i < recipe.ingredients.count - 1 {
                result.append(AttributedString(", "))
            }
        }
        return result
    }

    private func loadPage(_ page: Int) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let allRecipes = loadRecipesFromJSON()
            let filtered = allRecipes.filter { !$0.ingredients.isEmpty }
            let query = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searched = query.isEmpty ? filtered : filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }

            let scored: [(MyRecipe, Int, Int)] = searched.map { recipe in
                let match = recipe.ingredients.reduce(0) { score, ing in
                    let lower = ing.lowercased()
                    return fridgeItems.contains(where: { lower.contains($0) || $0.contains(lower) }) ? score + 1 : score
                }
                let missing = recipe.ingredients.filter { ing in !fridgeItems.contains { ing.lowercased().contains($0) || $0.contains(ing.lowercased()) } }.count
                return (recipe, match, missing)
            }

            let sorted: [(MyRecipe, Int, Int)]
            switch sortMode {
            case .topMatching:
                sorted = scored.sorted { $0.1 > $1.1 }
            case .topMissing:
                sorted = scored.sorted { $0.2 < $1.2 }
            }

            let total = sorted.count
            let start = page * pageSize
            let end = min(start + pageSize, total)
            let pageRecipes = (start < end) ? Array(sorted[start..<end]).map { $0.0 } : []

            DispatchQueue.main.async {
                self.totalRecipesCount = total
                self.currentPage = page
                self.currentPageRecipes = pageRecipes
                self.isLoading = false
            }
        }
    }

    private func changePage(to newPage: Int) {
        guard newPage >= 0 && newPage < totalPages else { return }
        loadPage(newPage)
    }

    private func fetchImage(for recipe: MyRecipe) {
        guard imageURLs[recipe.id] == nil else { return }
        let query = [recipe.name, recipe.description ?? ""].joined(separator: " ")
        PexelsImageFetcher.shared.fetchImageURL(for: query) { url in
            if let url = url {
                DispatchQueue.main.async {
                    self.imageURLs[recipe.id] = url
                }
            }
        }
    }
}
