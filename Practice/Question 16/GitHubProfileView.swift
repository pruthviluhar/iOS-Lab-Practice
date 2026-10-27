
import SwiftUI

struct GitHubProfileView: View {
    let username: String

    @State private var profile: GitHubUserProfile?
    @State private var errorMessage: String?
    @State private var isLoading = true

    private let service = GitHubService()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading profile...")
            } else if let profile {
                ScrollView {
                    VStack(spacing: 16) {
                        AsyncImage(
                            url: URL(string: profile.avatar_url)
                        ) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())

                        Text(profile.login)
                            .font(.title2.bold())

                        Text(profile.bio ?? "No bio available")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 32) {
                            statistic(
                                title: "Followers",
                                value: profile.followers
                            )

                            statistic(
                                title: "Public Repos",
                                value: profile.public_repos
                            )
                        }
                        .padding(.top, 8)

                        Link(
                            "Open GitHub Profile",
                            destination: URL(
                                string: profile.html_url
                            )!
                        )
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Profile Unavailable",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(
                        errorMessage ?? "Unable to load this profile."
                    )
                )
            }
        }
        .navigationTitle("User Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    private func statistic(title: String, value: Int) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func loadProfile() async {
        do {
            profile = try await service.fetchProfile(username: username)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
