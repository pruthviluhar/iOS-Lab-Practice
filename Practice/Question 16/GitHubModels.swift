
import Foundation

struct GitHubSearchResponse: Decodable {
    let items: [GitHubUser]
}

struct GitHubUser: Decodable, Identifiable, Hashable {
    let id: Int
    let login: String
    let avatar_url: String
    let html_url: String
}

struct GitHubUserProfile: Decodable {
    let login: String
    let avatar_url: String
    let html_url: String
    let bio: String?
    let followers: Int
    let public_repos: Int
}
