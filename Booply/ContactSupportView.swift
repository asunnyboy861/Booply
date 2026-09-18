import SwiftUI

struct ContactSupportView: View {
    private enum Subject: String, CaseIterable, Identifiable {
        case general = "General"
        case feature = "Feature Suggestion"
        case bug = "Bug Report"
        case usage = "Usage Question"
        case performance = "Performance Issue"
        case ui = "UI Improvement"
        case other = "Other"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .general: return "bubble.left.fill"
            case .feature: return "lightbulb.fill"
            case .bug: return "ant.fill"
            case .usage: return "questionmark.circle.fill"
            case .performance: return "gauge.with.dots.needle.67percent"
            case .ui: return "paintpalette.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    private struct FeedbackRequest: Codable {
        let name: String
        let email: String
        let subject: String
        let message: String
        let app_name: String
    }

    private struct FeedbackResponse: Codable {
        let success: Bool?
        let id: Int?
        let error: String?
    }

    private static let backendURL = URL(string: "https://feedback-board.iocompile67692.workers.dev/api/feedback")!

    @State private var subject: Subject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var banner: Banner?
    @FocusState private var messageFocused: Bool

    fileprivate enum Banner {
        case success, error(String)
    }

    private var emailValid: Bool {
        email.contains("@") && email.contains(".") && email.count > 4
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailValid
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && !isSending
            && (subject != .other || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach([Subject.general, .feature, .bug, .usage, .performance, .ui]) { item in
                        tile(item)
                    }
                    tile(.other)
                }
                if subject == .other {
                    TextField("Tell us the topic…", text: $customSubject)
                }
            } header: {
                Text("Subject")
            }

            Section {
                TextField("Your name", text: $name)
                    .textContentType(.name)
                TextField("yourname@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !email.isEmpty && !emailValid {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Tell us what's on your mind…")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .focused($messageFocused)
                        .accessibilityLabel("Message")
                }
                Text("\(message.count) / 1000")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onChange(of: message) { _, newValue in
                        if newValue.count > 1000 {
                            message = String(newValue.prefix(1000))
                        }
                    }
            }

            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        if isSending {
                            ProgressView().tint(.white)
                        }
                        Text(isSending ? "Sending…" : "Submit")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)

                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Contact Support")
        .banner(banner: $banner)
    }

    private func tile(_ item: Subject) -> some View {
        Button {
            subject = item
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.symbol)
                    .font(.title3)
                Text(item.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                if subject == item {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                } else {
                    Color.clear.frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                subject == item ? Theme.sage : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(subject == item ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(subject == item ? Theme.sageDeep : Theme.separator, lineWidth: subject == item ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Subject \(item.rawValue)")
    }

    private func submit() {
        isSending = true
        let finalSubject = subject == .other ? customSubject : subject.rawValue
        let payload = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: finalSubject,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: "Booply"
        )
        var request = URLRequest(url: Self.backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try? JSONEncoder().encode(payload)

        Task {
            defer { isSending = false }
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    banner = .error("Unexpected server response.")
                    return
                }
                let decoded = try? JSONDecoder().decode(FeedbackResponse.self, from: data)
                if http.statusCode == 200, decoded?.success == true {
                    banner = .success
                    message = ""
                    customSubject = ""
                } else {
                    banner = .error(decoded?.error ?? "Something went wrong. Please try again.")
                }
            } catch {
                banner = .error("Something went wrong. Please try again.")
            }
        }
    }
}

private struct BannerModifier: ViewModifier {
    @Binding var banner: ContactSupportView.Banner?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let banner {
                Group {
                    switch banner {
                    case .success:
                        Label("Thank you! Your feedback has been sent.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.green, in: Capsule())
                    case .error(let text):
                        Label(text, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.orange, in: Capsule())
                    }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { self.banner = nil }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: banner != nil)
    }
}

private extension View {
    func banner(banner: Binding<ContactSupportView.Banner?>) -> some View {
        modifier(BannerModifier(banner: banner))
    }
}
