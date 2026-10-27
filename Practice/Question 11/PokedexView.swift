import SwiftUI
import Combine

// MARK: - View Model

@MainActor
final class PokedexViewModel: ObservableObject {

    @Published private(set) var pokemon: [PokemonListItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMorePages = true
    @Published var errorMessage: String?

    private let service: PokemonService
    private var nextPageURL: URL?
    private var requestedPageURLs: Set<String> = []

    init() {
        self.service = PokemonService()
        self.nextPageURL = URL(
            string: "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0"
        )
    }

    func loadNextPage() async {
        guard !isLoading, hasMorePages else {
            return
        }

        guard let url = nextPageURL else {
            hasMorePages = false
            return
        }

        let pageKey = url.absoluteString

        guard !requestedPageURLs.contains(pageKey) else {
            return
        }

        requestedPageURLs.insert(pageKey)
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let page = try await service.fetchPage(from: url)

            let existingURLs = Set(pokemon.map { $0.url })
            let newPokemon = page.results.filter {
                !existingURLs.contains($0.url)
            }

            pokemon.append(contentsOf: newPokemon)

            if let next = page.next, let nextURL = URL(string: next) {
                nextPageURL = nextURL
                hasMorePages = true
            } else {
                nextPageURL = nil
                hasMorePages = false
            }

        } catch {
            requestedPageURLs.remove(pageKey)
            errorMessage =
                "Couldn't load Pokémon. Check your internet connection and try again."
        }
    }
}
// MARK: - Pokédex List

struct PokedexView: View {
    @StateObject private var viewModel = PokedexViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.pokemon) { pokemon in
                        NavigationLink {
                            PokemonDetailView(pokemon: pokemon)
                        } label: {
                            PokemonCardView(pokemon: pokemon)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            // When the final loaded item appears,
                            // request the next page automatically.
                            if pokemon.id == viewModel.pokemon.last?.id {
                                Task {
                                    await viewModel.loadNextPage()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if viewModel.isLoading {
                    ProgressView("Loading Pokémon...")
                        .padding(.vertical, 24)
                }

                if let message = viewModel.errorMessage {
                    VStack(spacing: 10) {
                        Text(message)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)

                        Button("Retry") {
                            Task {
                                await viewModel.loadNextPage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                if !viewModel.hasMorePages &&
                    !viewModel.pokemon.isEmpty {
                    Text("You've reached the end!")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 24)
                }
            }
            .navigationTitle("Pokédex")
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.loadNextPage()
            }
        }
    }
}

// MARK: - Pokémon Card

struct PokemonCardView: View {
    let pokemon: PokemonListItem

    private var imageURL: URL? {
        guard let id = pokemon.pokemonID else {
            return nil
        }

        return URL(
            string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 110, height: 110)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)

                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(width: 110, height: 110)

                @unknown default:
                    EmptyView()
                        .frame(width: 110, height: 110)
                }
            }

            Text(pokemon.formattedName)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let id = pokemon.pokemonID {
                Text(String(format: "#%03d", id))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

// MARK: - Pokémon Detail Screen

struct PokemonDetailView: View {
    let pokemon: PokemonListItem

    @State private var details: PokemonDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = PokemonService()

    private var imageURL: URL? {
        guard let id = pokemon.pokemonID else {
            return nil
        }

        return URL(
            string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 180, height: 180)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)

                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                            .frame(width: 180, height: 180)

                    @unknown default:
                        EmptyView()
                    }
                }

                Text(pokemon.formattedName)
                    .font(.largeTitle.bold())

                if let id = pokemon.pokemonID {
                    Text(String(format: "#%03d", id))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                if isLoading {
                    ProgressView("Loading details...")
                        .padding()
                } else if let details {
                    detailContent(details)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)

                        Button("Retry") {
                            Task {
                                await loadDetails()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(pokemon.formattedName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if details == nil {
                await loadDetails()
            }
        }
    }

    @ViewBuilder
    private func detailContent(
        _ details: PokemonDetail
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Types
            VStack(alignment: .leading, spacing: 10) {
                Text("Types")
                    .font(.title2.bold())

                HStack(spacing: 8) {
                    ForEach(details.types) { item in
                        Text(item.type.name.capitalized)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Color.blue.opacity(0.12),
                                in: Capsule()
                            )
                    }
                }
            }

            // Height and weight
            HStack(spacing: 12) {
                measurementCard(
                    title: "Height",
                    value: "\(Double(details.height) / 10, default: "%.1f") m",
                    icon: "ruler"
                )

                measurementCard(
                    title: "Weight",
                    value: "\(Double(details.weight) / 10, default: "%.1f") kg",
                    icon: "scalemass"
                )
            }

            // Base stats
            VStack(alignment: .leading, spacing: 16) {
                Text("Base Stats")
                    .font(.title2.bold())

                ForEach(details.stats) { stat in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(stat.formattedName)
                                .font(.subheadline)

                            Spacer()

                            Text("\(stat.baseStat)")
                                .font(.subheadline.bold())
                                .monospacedDigit()
                        }

                        ProgressView(
                            value: Double(min(stat.baseStat, 255)),
                            total: 255
                        )
                        .tint(statColor(for: stat.baseStat))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func measurementCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color.blue.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func statColor(for value: Int) -> Color {
        switch value {
        case 0..<50:
            return .red
        case 50..<100:
            return .orange
        case 100..<150:
            return .green
        default:
            return .blue
        }
    }

    @MainActor
    private func loadDetails() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            details = try await service.fetchPokemonDetails(
                for: pokemon.name
            )
        } catch {
            errorMessage =
                "Couldn't load Pokémon details. Check your connection."
        }
    }
}

#Preview {
    PokedexView()
}
