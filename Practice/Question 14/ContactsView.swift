
import SwiftUI

struct ContactsView: View {
    @StateObject private var store = ContactStore()
    @State private var showingAddForm = false

    private var favourites: [Contact] {
        store.contacts
            .filter(\.isFavourite)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }
    }

    private var sectionLetters: [String] {
        Array(Set(store.contacts.map(\.sectionLetter)))
            .sorted {
                if $0 == "#" { return false }
                if $1 == "#" { return true }
                return $0 < $1
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if !favourites.isEmpty {
                    Section("Favourites") {
                        ForEach(favourites) { contact in
                            contactRow(contact)
                        }
                    }
                }

                ForEach(sectionLetters, id: \.self) { letter in
                    Section(letter) {
                        ForEach(
                            store.contacts
                                .filter { $0.sectionLetter == letter }
                                .sorted {
                                    $0.name.localizedCaseInsensitiveCompare(
                                        $1.name
                                    ) == .orderedAscending
                                }
                        ) { contact in
                            contactRow(contact)
                        }
                    }
                }
            }
            .overlay {
                if store.contacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts",
                        systemImage: "person.crop.circle",
                        description: Text("Tap + to add your first contact.")
                    )
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Contact")
                }
            }
            .sheet(isPresented: $showingAddForm) {
                ContactFormView { contact in
                    store.addContact(contact)
                }
            }
            .alert(
                "Contacts Error",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    store.errorMessage = nil
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
        .environmentObject(store)
    }

    @ViewBuilder
    private func contactRow(_ contact: Contact) -> some View {
        NavigationLink {
            ContactDetailView(contact: contact)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.body)

                    Text(contact.phone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if contact.isFavourite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            .padding(.vertical, 3)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                store.toggleFavourite(contact)
            } label: {
                Label(
                    contact.isFavourite ? "Unfavourite" : "Favourite",
                    systemImage: contact.isFavourite ? "star.slash" : "star.fill"
                )
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.deleteContact(contact)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ContactsView()
}
