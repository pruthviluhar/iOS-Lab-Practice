import Foundation

struct PokemonPage: Decodable {
    let next: String?
    let results: [PokemonListItem]
}

struct PokemonListItem: Decodable, Identifiable {
    let name: String
    let url: String

    // The API URL ends with the Pokémon's numeric ID.
    var pokemonID: Int? {
        URL(string: url)?
            .pathComponents
            .compactMap { Int($0) }
            .last
    }

    var id: String {
        url
    }

    var formattedName: String {
        name.capitalized
    }
}

struct PokemonDetail: Decodable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [PokemonTypeSlot]
    let stats: [PokemonStatEntry]

    var formattedName: String {
        name.capitalized
    }
}

struct PokemonTypeSlot: Decodable, Identifiable {
    let slot: Int
    let type: PokemonType

    var id: Int {
        slot
    }
}

struct PokemonType: Decodable {
    let name: String
}

struct PokemonStatEntry: Decodable, Identifiable {
    let baseStat: Int
    let stat: PokemonStat

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }

    var id: String {
        stat.name
    }

    var formattedName: String {
        stat.name
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

struct PokemonStat: Decodable {
    let name: String
}
