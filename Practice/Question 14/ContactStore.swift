import Foundation
import Combine

@MainActor
final class ContactStore: ObservableObject {

    @Published private(set) var contacts: [Contact] = []
    @Published var errorMessage: String?

    private let fileURL: URL

    init() {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        fileURL = documentsURL.appendingPathComponent("contacts.json")
        loadContacts()
    }

    // MARK: - Load

    func loadContacts() {
        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            contacts = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            contacts = try JSONDecoder().decode(
                [Contact].self,
                from: data
            )
            errorMessage = nil
        } catch {
            errorMessage = "Unable to read contacts.json."
        }
    }

    // MARK: - Save JSON

    private func saveContacts() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(contacts)
            try data.write(to: fileURL, options: [.atomic])

            errorMessage = nil
        } catch {
            errorMessage = "Unable to save contacts."
        }
    }

    // MARK: - Add

    func addContact(_ contact: Contact) {
        contacts.append(contact)
        saveContacts()
    }

    // MARK: - Update

    func updateContact(_ updatedContact: Contact) {
        guard let index = contacts.firstIndex(
            where: { $0.id == updatedContact.id }
        ) else {
            return
        }

        contacts[index] = updatedContact
        saveContacts()
    }

    // MARK: - Favourite

    func toggleFavourite(_ contact: Contact) {
        guard let index = contacts.firstIndex(
            where: { $0.id == contact.id }
        ) else {
            return
        }

        contacts[index].isFavourite.toggle()
        saveContacts()
    }

    // MARK: - Delete

    func deleteContact(_ contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
}
