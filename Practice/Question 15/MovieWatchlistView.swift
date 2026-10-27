
import SwiftUI

struct MovieWatchlistView: View {
    @StateObject private var viewModel: MovieViewModel

    init(service: any MovieServiceProtocol = LocalMovieService()) {
        _viewModel = StateObject(
            wrappedValue: MovieViewModel(service: service)
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Genre", selection: $viewModel.selectedGenre) {
                    ForEach(viewModel.genres, id: \.self) { genre in
                        Text(genre).tag(genre)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                }

                List(viewModel.filteredMovies) { movie in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movie.title)
                                    .font(.headline)

                                Text("\(movie.genre) • \(movie.year)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                viewModel.toggleWatched(for: movie)
                            } label: {
                                Image(
                                    systemName: movie.isWatched
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .font(.title2)
                                .foregroundStyle(
                                    movie.isWatched ? .green : .gray
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                movie.isWatched
                                    ? "Mark Unwatched"
                                    : "Mark Watched"
                            )
                        }

                        HStack {
                            Text(movie.isWatched ? "Watched" : "Unwatched")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            StarRatingView(rating: movie.rating) { rating in
                                viewModel.setRating(rating, for: movie)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Movie Watchlist")
        }
    }
}

#Preview {
    MovieWatchlistView(service: MockMovieService())
}
