
import SwiftUI

struct Login: View {

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var loginError = ""
    @State private var showWelcome = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    // Email validation using Regex
    var isEmailValid: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    // Password validation
    var hasEightCharacters: Bool {
        password.count >= 8
    }

    var hasCapitalLetter: Bool {
        password.range(
            of: "[A-Z]",
            options: .regularExpression
        ) != nil
    }

    var hasNumber: Bool {
        password.range(
            of: "[0-9]",
            options: .regularExpression
        ) != nil
    }

    var hasSpecialCharacter: Bool {
        password.range(
            of: #"[^A-Za-z0-9]"#,
            options: .regularExpression
        ) != nil
    }

    // All requirements must be satisfied
    var isPasswordValid: Bool {
        hasEightCharacters &&
        hasCapitalLetter &&
        hasNumber &&
        hasSpecialCharacter
    }

    var canLogin: Bool {
        isEmailValid && isPasswordValid
    }

    func checkLogin() {
        if email.lowercased() == "test@ios.com"
            && password == "Swift@123" {
            loginError = ""
            focusedField = nil
            showWelcome = true
        } else {
            loginError = "Incorrect email or password."
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {

                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }

                    if !email.isEmpty {
                        Label(
                            isEmailValid
                                ? "Valid email"
                                : "Enter a valid email address",
                            systemImage: isEmailValid
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                        )
                        .foregroundStyle(
                            isEmailValid ? .green : .red
                        )
                        .font(.caption)
                    }

                    HStack {
                        Group {
                            if showPassword {
                                TextField(
                                    "Password",
                                    text: $password
                                )
                            } else {
                                SecureField(
                                    "Password",
                                    text: $password
                                )
                            }
                        }
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            if canLogin {
                                checkLogin()
                            }
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(
                                systemName: showPassword
                                    ? "eye.slash"
                                    : "eye"
                            )
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Password Requirements") {
                    RequirementRow(
                        title: "At least 8 characters",
                        isValid: hasEightCharacters
                    )

                    RequirementRow(
                        title: "1 capital letter",
                        isValid: hasCapitalLetter
                    )

                    RequirementRow(
                        title: "1 number",
                        isValid: hasNumber
                    )

                    RequirementRow(
                        title: "1 special character",
                        isValid: hasSpecialCharacter
                    )
                }

                Section {
                    Button("Login") {
                        checkLogin()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!canLogin)
                }

                if !loginError.isEmpty {
                    Section {
                        Text(loginError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Login")
            .navigationDestination(
                isPresented: $showWelcome
            ) {
                WelcomeView(
                    name: String(
                        email.split(separator: "@").first ?? "User"
                    )
                )
            }
        }
    }
}

// Checklist row
struct RequirementRow: View {
    let title: String
    let isValid: Bool

    var body: some View {
        Label(
            title,
            systemImage: isValid
                ? "checkmark.circle.fill"
                : "circle"
        )
        .foregroundStyle(isValid ? .green : .secondary)
    }
}

// Welcome screen
struct WelcomeView: View {
    let name: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)

            Text("Welcome, \(name)!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You have logged in successfully.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    Login()
}
