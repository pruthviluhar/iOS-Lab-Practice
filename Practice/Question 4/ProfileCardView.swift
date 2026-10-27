
import SwiftUI

struct ProfileCardView: View {

    @State private var name = "Rahul Kumar Sharma"
    @State private var bio = "iOS Developer and UI/UX Designer"
    @State private var favoriteColor = Color.blue

    @State private var draftName = ""
    @State private var draftBio = ""
    @State private var draftColor = Color.blue

    @State private var showingEditSheet = false

    // Get initials from the first and last words
    private var initials: String {
        let words = name.split(
            whereSeparator: { $0.isWhitespace }
        )

        guard let first = words.first else {
            return ""
        }

        if words.count == 1 {
            return String(first.prefix(1)).uppercased()
        }

        let last = words[words.count - 1]

        return (
            String(first.prefix(1)) +
            String(last.prefix(1))
        ).uppercased()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                VStack(spacing: 16) {
                    Text(initials)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle().fill(.black.opacity(0.2))
                        )

                    Text(name)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text(bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(
                    favoriteColor.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 24)
                )

                Button {
                    // Copy original values into editable drafts
                    draftName = name
                    draftBio = bio
                    draftColor = favoriteColor
                    showingEditSheet = true
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("My Profile")
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView(
                    name: $draftName,
                    bio: $draftBio,
                    favoriteColor: $draftColor,
                    onSave: {
                        name = draftName
                        bio = draftBio
                        favoriteColor = draftColor
                    }
                )
            }
        }
    }
}

#Preview {
    ProfileCardView()
}
