import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct MilestoneAlbumView: View {
    @Query(filter: #Predicate<Milestone> { $0.confirmedAt != nil }, sort: \Milestone.confirmedAt, order: .reverse)
    private var milestones: [Milestone]

    @Environment(\.modelContext) private var modelContext

    @State private var selectedMilestone: Milestone?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showShare = false
    @State private var pdfURL: URL?
    @State private var tagging = false

    var body: some View {
        Group {
            if milestones.isEmpty {
                emptyState
            } else {
                timeline
            }
        }
        .navigationTitle("Milestone Album")
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(milestones.isEmpty)
                .accessibilityLabel("Export PDF")
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item, let target = selectedMilestone else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    target.photoData = data
                    try? modelContext.save()
                    if PurchaseManager.shared.isPro, let image = UIImage(data: data) {
                        tagging = true
                        let tag = await MilestoneVisionService.tagMilestone(image: image)
                        tagging = false
                        if let tag {
                            target.aiTag = tag
                            try? modelContext.save()
                        }
                    }
                }
                selectedMilestone = nil
                pickerItem = nil
            }
        }
        .sheet(isPresented: $showShare) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        .overlay {
            if tagging {
                ProgressView("Tagging photo…")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.leadinghalf.filled")
                .font(.system(size: 48))
                .foregroundStyle(Theme.sage)
            Text("No milestones yet")
                .font(.title3.bold())
            Text("After each quiet time, Booply suggests milestones your baby showed. Confirm them to build this album.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var timeline: some View {
        List {
            ForEach(groupedByMonth(), id: \.key) { group in
                Section("Month \(group.key)") {
                    ForEach(group.value) { milestone in
                        row(milestone)
                    }
                }
            }
        }
    }

    private func row(_ milestone: Milestone) -> some View {
        HStack(spacing: 14) {
            if let data = milestone.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.sage)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.body.bold())
                if let tag = milestone.aiTag {
                    Text("AI: \(tag)")
                        .font(.caption)
                        .foregroundStyle(Theme.sageDeep)
                }
                Text(milestone.confirmedAt ?? milestone.suggestedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PhotosPicker(selection: Binding(
                get: { pickerItem },
                set: { newValue in
                    pickerItem = newValue
                    selectedMilestone = milestone
                }
            ), matching: .images) {
                Image(systemName: "photo.on.rectangle.angled")
            }
            .accessibilityLabel("Add growth photo")
        }
    }

    private func groupedByMonth() -> [(key: String, value: [Milestone])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        var groups: [String: [Milestone]] = [:]
        for milestone in milestones {
            let key = formatter.string(from: milestone.confirmedAt ?? milestone.suggestedAt)
            groups[key, default: []].append(milestone)
        }
        return groups.sorted { $0.key > $1.key }.map { (key: $0.key, value: $0.value) }
    }

    private func exportPDF() {
        guard let url = AlbumPDFExporter.export(milestones: milestones) else { return }
        pdfURL = url
        showShare = true
    }
}

enum AlbumPDFExporter {
    static func export(milestones: [Milestone]) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let titleFont = UIFont.boldSystemFont(ofSize: 20)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        let url = FileManager.default.temporaryDirectory.appending(path: "Booply-Milestones.pdf")

        do {
            try renderer.writePDF(to: url) { context in
                var y: CGFloat = 50
                context.beginPage()
                "Milestone Album".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: titleFont])
                y += 34
                for milestone in milestones {
                    if y > 720 {
                        context.beginPage()
                        y = 50
                    }
                    let date = milestone.confirmedAt ?? milestone.suggestedAt
                    let line = "* \(milestone.title) — \(date.formatted(date: .abbreviated, time: .omitted))"
                    line.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: bodyFont])
                    y += 20
                }
            }
            return url
        } catch {
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
