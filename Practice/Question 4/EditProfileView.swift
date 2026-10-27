
import SwiftUI

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var name: String
    @Binding var bio: String
    @Binding var favoriteColor: Color

    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)

                    TextField("Short Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Favourite Colour") {
                    ColorPicker(
                        "Choose Background Colour",
                        selection: $favoriteColor,
                        supportsOpacity: false
                    )

                    RoundedRectangle(cornerRadius: 12)
                        .fill(favoriteColor.opacity(0.3))
                        .frame(height: 70)
                        .overlay {
                            Text("Preview")
                                .font(.headline)
                        }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Discard drafts by dismissing the sheet
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
    }
}

#Preview {
    EditProfileView(
        name: .constant("Rahul Kumar Sharma"),
        bio: .constant("iOS Developer"),
        favoriteColor: .constant(.blue),
        onSave: {}
    )
}
