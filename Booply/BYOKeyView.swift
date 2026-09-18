import SwiftUI

struct BYOKeyView: View {
    @StateObject private var keyStore = BYOKeyStore.shared
    @State private var input = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section {
                if keyStore.hasKey {
                    Label("API key configured", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.sageDeep)
                    Button("Remove Key", role: .destructive) {
                        keyStore.deleteKey()
                        input = ""
                    }
                } else {
                    SecureField("Your API key", text: $input)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save Key") {
                        keyStore.setKey(input.trimmingCharacters(in: .whitespaces))
                        saved = true
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Your Own API Key")
            } footer: {
                Text("The key is stored in the iOS Keychain and is never logged or included in backups of your feedback. With a key, milestone photo tagging and the weekly report run without limits.")
            }

            Section {
                Label("Apple Intelligence is used by default when available — no key needed for basic receipts.", systemImage: "apple.logo")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI Configuration")
        .onDisappear { saved = false }
    }
}
