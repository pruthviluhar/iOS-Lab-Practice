
import SwiftUI

struct ContactDetailView: View {
    @EnvironmentObject private var store: ContactStore

    let contact: Contact

    @State private var showingEditForm = false
    @Environment(\.openURL) private var openURL

    private var currentContact: Contact {
        store.contacts.first { $0.id == contact.id } ?? contact
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(.blue)

                    Text(currentContact.name)
                        .font(.title2.bold())

                    if currentContact.isFavourite {
                        Label("Favourite", systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }

            Section("Contact Details") {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(currentContact.phone)
                            .foregroundStyle(.blue)
                    }
                } icon: {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.green)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard let url = URL(
                        string: "tel:\(currentContact.phone)"
                    ) else {
                        return
                    }

                    openURL(url)
                }

                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(currentContact.email)
                            .foregroundStyle(.primary)
                    }
                } icon: {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.blue)
                }
            }

            Section {
                Button {
                    store.toggleFavourite(currentContact)
                } label: {
                    Label(
                        currentContact.isFavourite
                            ? "Remove from Favourites"
                            : "Add to Favourites",
                        systemImage: "star"
                    )
                }
            }
        }
        .navigationTitle("Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditForm = true
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            ContactFormView(contact: currentContact) { updated in
                store.updateContact(updated)
            }
        }
    }
}
