import Foundation

enum PokemonServiceError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Pokémon API URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        }
    }
}

struct PokemonService {
    private let baseURL =
        "https://pokeapi.co/api/v2/pokemon"

    func fetchPage(from url: URL) async throws -> PokemonPage {
        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw PokemonServiceError.invalidResponse
        }

        return try JSONDecoder().decode(
            PokemonPage.self,
            from: data
        )
    }

    func fetchPokemonDetails(
        for name: String
    ) async throws -> PokemonDetail {
        guard let url = URL(
            string: "\(baseURL)/\(name.lowercased())"
        ) else {
            throw PokemonServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            throw PokemonServiceError.invalidResponse
        }

        return try JSONDecoder().decode(
            PokemonDetail.self,
            from: data
        )
    }
}
