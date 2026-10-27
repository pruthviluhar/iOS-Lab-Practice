import SwiftUI

struct ContactFormView: View {

    @Environment(\.dismiss) private var dismiss

    let existingContact: Contact?
    let onSave: (Contact) -> Void

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var isFavourite = false
    @State private var validationError: String?

    init(
        contact: Contact? = nil,
        onSave: @escaping (Contact) -> Void
    ) {
        self.existingContact = contact
        self.onSave = onSave

        _name = State(initialValue: contact?.name ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
        _email = State(initialValue: contact?.email ?? "")
        _isFavourite = State(
            initialValue: contact?.isFavourite ?? false
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)

                    TextField("10-digit Phone Number", text: $phone)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: phone) { _, newValue in
                            let digits = String(
                                newValue.filter(\.isNumber).prefix(10)
                            )

                            if digits != newValue {
                                phone = digits
                            }
                        }

                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                }

                Section {
                    Toggle("Favourite", isOn: $isFavourite)
                }

                if let validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(
                existingContact == nil ? "New Contact" : "Edit Contact"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                }
            }
        }
    }

    private func saveContact() {
        let cleanName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let cleanPhone = phone.filter(\.isNumber)

        guard !cleanName.isEmpty else {
            validationError = "Please enter a contact name."
            return
        }

        guard cleanPhone.count == 10 else {
            validationError = "Phone number must contain exactly 10 digits."
            return
        }

        guard isValidEmail(cleanEmail) else {
            validationError = "Please enter a valid email address."
            return
        }

        let contact = Contact(
            id: existingContact?.id ?? UUID(),
            name: cleanName,
            phone: cleanPhone,
            email: cleanEmail,
            isFavourite: isFavourite
        )

        onSave(contact)
        dismiss()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return email.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}
