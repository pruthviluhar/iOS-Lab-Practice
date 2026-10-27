
import Foundation
import Combine

@MainActor
final class MovieViewModel: ObservableObject {
    @Published private(set) var movies: [Movie] = []
    @Published var selectedGenre = "All"
    @Published private(set) var errorMessage: String?

    private let service: any MovieServiceProtocol

    init(service: any MovieServiceProtocol) {
        self.service = service
        loadMovies()
    }

    var genres: [String] {
        ["All"] + Array(Set(movies.map { $0.genre })).sorted()
    }

    var filteredMovies: [Movie] {
        if selectedGenre == "All" {
            return movies
        }

        return movies.filter { $0.genre == selectedGenre }
    }

    func loadMovies() {
        do {
            movies = try service.loadMovies()
            errorMessage = nil
        } catch {
            movies = []
            errorMessage = "Unable to load movies. Check movies.json."
        }
    }

    func toggleWatched(for movie: Movie) {
        guard let index = movies.firstIndex(where: {
            $0.id == movie.id
        }) else {
            return
        }

        movies[index].isWatched.toggle()
    }

    func setRating(_ rating: Int, for movie: Movie) {
        guard let index = movies.firstIndex(where: {
            $0.id == movie.id
        }) else {
            return
        }

        movies[index].rating = min(max(rating, 0), 5)
    }
}
