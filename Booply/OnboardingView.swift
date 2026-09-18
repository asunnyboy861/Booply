import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var birthdate = Date()
    @State private var companionName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.sageDeep)
                Text("Welcome to Booply")
                    .font(.largeTitle.bold())
                Text("Two quick questions and calm time begins.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("1 · Baby's birthday")
                        .font(.headline)
                    DatePicker(
                        "Birthday",
                        selection: $birthdate,
                        in: Calendar.current.date(byAdding: .year, value: -3, to: .now)!...Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Text("2 · Who's joining today?")
                        .font(.headline)
                    TextField("Mom, Dad, Grandma…", text: $companionName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                }
                .padding(20)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardCorner))

                Button {
                    save()
                } label: {
                    Text("Start Quiet Time")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                Spacer()
            }
            .padding(24)
            .background(Theme.background)
            .navigationTitle("")
        }
        .accessibilityElement(children: .contain)
    }

    private func save() {
        let profile = BabyProfile(birthdate: birthdate, companionName: companionName.isEmpty ? "You" : companionName)
        context.insert(profile)
        try? context.save()
    }
}
