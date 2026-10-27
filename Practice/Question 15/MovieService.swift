
import Foundation

protocol MovieServiceProtocol {
    func loadMovies() throws -> [Movie]
}

struct LocalMovieService: MovieServiceProtocol {
    func loadMovies() throws -> [Movie] {
        guard let url = Bundle.main.url(
            forResource: "movies",
            withExtension: "json"
        ) else {
            throw MovieServiceError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Movie].self, from: data)
    }
}

struct MockMovieService: MovieServiceProtocol {
    var movies: [Movie] = [
        Movie(
            id: 1,
            title: "Interstellar",
            genre: "Sci-Fi",
            year: 2014,
            isWatched: false,
            rating: 0
        ),
        Movie(
            id: 2,
            title: "Inception",
            genre: "Sci-Fi",
            year: 2010,
            isWatched: true,
            rating: 5
        ),
        Movie(
            id: 3,
            title: "The Dark Knight",
            genre: "Action",
            year: 2008,
            isWatched: false,
            rating: 0
        ),
        Movie(
            id: 4,
            title: "Toy Story",
            genre: "Animation",
            year: 1995,
            isWatched: false,
            rating: 0
        )
    ]

    func loadMovies() throws -> [Movie] {
        movies
    }
}

enum MovieServiceError: Error {
    case fileNotFound
}
