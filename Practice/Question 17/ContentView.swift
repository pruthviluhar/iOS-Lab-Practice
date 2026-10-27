
import SwiftUI

struct ContentView: View {
    @StateObject private var store = DestinationStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let error = store.errorMessage {
                    ContentUnavailableView(
                        "Unable to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )

                } else if let destination = store.currentDestination {
                    Text("Discover Destinations")
                        .font(.title2.bold())

                    Text(
                        "\(store.currentIndex + 1) of \(store.destinations.count)"
                    )
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    DestinationCardView(destination: destination) { like in
                        withAnimation(.spring(response: 0.35)) {
                            store.decide(like: like)
                        }
                    }
                    .frame(height: 440)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)

                    HStack(spacing: 24) {
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                store.undo()
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .frame(width: 52, height: 52)
                                .background(.orange.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .disabled(!store.canUndo)

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                store.decide(like: false)
                            }
                        } label: {
                            Label("Skip", systemImage: "xmark")
                                .font(.headline)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                store.decide(like: true)
                            }
                        } label: {
                            Label("Like", systemImage: "heart.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                } else if store.isFinished {
                    likedPlacesView
                } else {
                    ProgressView("Loading destinations...")
                }
            }
            .navigationTitle("Travel Deck")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var likedPlacesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(.pink)

            Text("All Done!")
                .font(.largeTitle.bold())

            Text("You liked \(store.likedDestinations.count) destinations.")
                .foregroundStyle(.secondary)

            List(store.likedDestinations) { destination in
                HStack(spacing: 12) {
                    Text(destination.emoji)
                        .font(.largeTitle)

                    VStack(alignment: .leading) {
                        Text(destination.name)
                            .font(.headline)

                        Text(destination.country)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Undo Last Decision") {
                withAnimation {
                    store.undo()
                }
            }
            .disabled(!store.canUndo)
            .buttonStyle(.bordered)

            Button("Start Again") {
                withAnimation {
                    store.loadDestinations()
                    // Reload the deck by creating a fresh view state.
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top)
    }
}

#Preview {
    ContentView()
}
