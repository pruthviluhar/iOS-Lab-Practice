
import SwiftUI

struct RecipeBookView: View {

    @State private var recipes: [Recipe] = []
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var vegOnly = false
    @State private var loadError: String?

    private let categories = [
        "All", "Breakfast", "Lunch", "Dessert"
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in

            let matchesSearch =
                searchText.isEmpty ||
                recipe.name.localizedCaseInsensitiveContains(searchText) ||
                recipe.ingredients.contains {
                    $0.localizedCaseInsensitiveContains(searchText)
                }

            let matchesCategory =
                selectedCategory == "All" ||
                recipe.category == selectedCategory

            let matchesVeg =
                !vegOnly || recipe.isVeg

            return matchesSearch &&
                   matchesCategory &&
                   matchesVeg
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(
                                        selectedCategory == category
                                        ? Color.orange
                                        : Color.gray.opacity(0.15),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        selectedCategory == category
                                        ? Color.white
                                        : Color.primary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // Vegetarian filter
                Toggle("Vegetarian only", isOn: $vegOnly)
                    .padding(.horizontal)

                if let loadError {
                    ContentUnavailableView(
                        "Unable to Load Recipes",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if filteredRecipes.isEmpty {
                    // Friendly empty state
                    ContentUnavailableView(
                        "No Recipes Found",
                        systemImage: "fork.knife",
                        description: Text(
                            "Try another search or change your filters."
                        )
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(filteredRecipes) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeCardView(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.top, 8)
            .navigationTitle("RecipeBook")
            .searchable(
                text: $searchText,
                prompt: "Search recipes or ingredients"
            )
            .onAppear {
                loadRecipes()
            }
        }
    }

    // MARK: - Load JSON

    private func loadRecipes() {
        guard let url = Bundle.main.url(
            forResource: "recipes",
            withExtension: "json"
        ) else {
            loadError = "Add recipes.json to your app target."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            recipes = try JSONDecoder().decode(
                [Recipe].self,
                from: data
            )
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}

// MARK: - Recipe Card

struct RecipeCardView: View {

    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.12))
                    .frame(height: 110)
                    .overlay {
                        Image(systemName: recipe.img)
                            .font(.system(size: 42))
                            .foregroundStyle(.orange)
                    }

                if recipe.isVeg {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                        .padding(7)
                        .background(.background, in: Circle())
                        .padding(7)
                }
            }

            Text(recipe.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(recipe.category)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("\(recipe.cookTime) min")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(recipe.difficulty)
                .font(.caption.bold())
                .foregroundStyle(.orange)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

// MARK: - Recipe Details

struct RecipeDetailView: View {

    let recipe: Recipe

    @State private var checkedIngredients: Set<String> = []

    var body: some View {
        List {

            Section {
                HStack(spacing: 16) {
                    Image(systemName: recipe.img)
                        .font(.system(size: 42))
                        .foregroundStyle(.orange)
                        .frame(width: 70, height: 70)
                        .background(
                            Color.orange.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 16)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.name)
                            .font(.title2.bold())

                        Text("\(recipe.category) • \(recipe.cookTime) min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Difficulty: \(recipe.difficulty)")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Ingredients") {
                ForEach(
                    Array(recipe.ingredients.enumerated()),
                    id: \.offset
                ) { _, ingredient in
                    Button {
                        if checkedIngredients.contains(ingredient) {
                            checkedIngredients.remove(ingredient)
                        } else {
                            checkedIngredients.insert(ingredient)
                        }
                    } label: {
                        HStack {
                            Image(
                                systemName: checkedIngredients.contains(ingredient)
                                ? "checkmark.circle.fill"
                                : "circle"
                            )
                            .foregroundStyle(
                                checkedIngredients.contains(ingredient)
                                ? .green
                                : .secondary
                            )

                            Text(ingredient)
                                .foregroundStyle(.primary)
                                .strikethrough(
                                    checkedIngredients.contains(ingredient)
                                )

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Cooking Steps") {
                ForEach(
                    Array(recipe.steps.enumerated()),
                    id: \.offset
                ) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .frame(width: 25, alignment: .leading)

                        Text(step)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RecipeBookView()
}
