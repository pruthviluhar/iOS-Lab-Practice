
import SwiftUI

struct GitHubSearchView: View {
    @StateObject private var viewModel = GitHubSearchViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search GitHub users", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                content
            }
            .navigationTitle("GitHub Users")
            .task(id: viewModel.query) {
                await viewModel.search()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.trimmedQuery.count < 3 {
            ContentUnavailableView(
                "Search GitHub",
                systemImage: "person.2",
                description: Text("Enter at least 3 characters to search.")
            )
        } else if viewModel.isLoading {
            ProgressView("Searching users...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            ContentUnavailableView {
                Label("Search Failed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") {
                    Task {
                        await viewModel.search()
                    }
                }
            }
        } else if viewModel.users.isEmpty {
            ContentUnavailableView(
                "No Users Found",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Try another username.")
            )
        } else {
            List(viewModel.users) { user in
                NavigationLink {
                    GitHubProfileView(username: user.login)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: user.avatar_url)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.login)
                                .font(.headline)

                            Text(user.html_url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    GitHubSearchView()
}
