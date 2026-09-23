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
                Text("Optional. The key is stored in the iOS Keychain and never sent to us. Without a key, all core features work and receipts use on-device Apple Intelligence or a local template. If you add a key, only the photo or session statistics you choose to process are sent directly to the provider you selected — nothing else is shared.")
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
