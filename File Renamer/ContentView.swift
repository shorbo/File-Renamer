import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SelectedFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ContentView: View {
    @State private var selectedFiles: [SelectedFile] = []
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var matchCase = false
    @State private var useRegex = false
    @State private var isDropTargeted = false
    @State private var renameError: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var successCount = 0

    private var matches: [(file: SelectedFile, newName: String)] {
        guard !findText.isEmpty else { return [] }
        return selectedFiles.compactMap { file in
            let newName = replacedName(for: file.name)
            if newName != file.name {
                return (file, newName)
            }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            dropZone
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            findReplaceSection
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            optionsSection
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            Divider()

            fileTable

            Divider()

            bottomBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(minWidth: 600, minHeight: 450)
        .alert("Rename Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(renameError ?? "An unknown error occurred.")
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Renamed \(successCount) file\(successCount == 1 ? "" : "s") successfully.")
        }
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: 4) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            if selectedFiles.isEmpty {
                HStack(spacing: 4) {
                    Text("Drop files here or")
                        .foregroundStyle(.secondary)
                    Button("choose files...") {
                        chooseFiles()
                    }
                    .buttonStyle(.link)
                }
            } else {
                HStack(spacing: 4) {
                    Text("\(selectedFiles.count) file\(selectedFiles.count == 1 ? "" : "s") ready")
                        .fontWeight(.medium)
                }
                HStack(spacing: 4) {
                    Text("or")
                        .foregroundStyle(.secondary)
                    Button("choose files...") {
                        chooseFiles()
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                )
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Find / Replace

    private var findReplaceSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FIND")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                TextField("Search text...", text: $findText)
                    .textFieldStyle(.roundedBorder)
            }

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("REPLACE WITH")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                TextField("Replacement text...", text: $replaceText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Options

    private var optionsSection: some View {
        HStack(spacing: 16) {
            Toggle("Match case", isOn: $matchCase)
                .toggleStyle(.checkbox)
            Toggle("Use regular expression", isOn: $useRegex)
                .toggleStyle(.checkbox)
            Spacer()
        }
    }

    // MARK: - File Table

    private var fileTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ORIGINAL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("NEW NAME")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("SIZE")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(selectedFiles) { file in
                        fileRow(file)
                        Divider()
                    }
                }
            }
        }
    }

    private func fileRow(_ file: SelectedFile) -> some View {
        let newName = findText.isEmpty ? file.name : replacedName(for: file.name)
        let hasMatch = newName != file.name

        return HStack {
            HStack(spacing: 6) {
                fileIcon(for: file.url)
                    .frame(width: 20, height: 20)
                highlightedOriginal(file.name)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                if hasMatch {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    highlightedReplacement(newName)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(file.formattedSize)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func fileIcon(for url: URL) -> some View {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        return Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private func highlightedOriginal(_ name: String) -> Text {
        guard !findText.isEmpty else { return Text(name).font(.callout) }

        let ranges = findRanges(in: name)
        guard !ranges.isEmpty else { return Text(name).font(.callout) }

        var result = Text("")
        var currentIndex = name.startIndex

        for range in ranges {
            if currentIndex < range.lowerBound {
                result = result + Text(name[currentIndex..<range.lowerBound]).font(.callout)
            }
            result = result + Text(name[range])
                .font(.callout)
                .foregroundColor(.blue)
                .bold()
            currentIndex = range.upperBound
        }

        if currentIndex < name.endIndex {
            result = result + Text(name[currentIndex..<name.endIndex]).font(.callout)
        }

        return result
    }

    private func highlightedReplacement(_ newName: String) -> Text {
        guard !findText.isEmpty, !replaceText.isEmpty else {
            return Text(newName).font(.callout)
        }

        let replaceRanges = findReplacementRanges(in: newName)
        guard !replaceRanges.isEmpty else { return Text(newName).font(.callout) }

        var result = Text("")
        var currentIndex = newName.startIndex

        for range in replaceRanges {
            if currentIndex < range.lowerBound {
                result = result + Text(newName[currentIndex..<range.lowerBound]).font(.callout)
            }
            result = result + Text(newName[range])
                .font(.callout)
                .foregroundColor(.green)
                .bold()
            currentIndex = range.upperBound
        }

        if currentIndex < newName.endIndex {
            result = result + Text(newName[currentIndex..<newName.endIndex]).font(.callout)
        }

        return result
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Text("\(selectedFiles.count) file\(selectedFiles.count == 1 ? "" : "s") · ")
                .foregroundStyle(.secondary) +
            Text("\(matches.count) match\(matches.count == 1 ? "" : "es")")
                .fontWeight(.medium)

            Spacer()

            Button("Cancel") {
                clearAll()
            }

            Button("Rename \(matches.count) file\(matches.count == 1 ? "" : "s")") {
                renameFiles()
            }
            .buttonStyle(.borderedProminent)
            .disabled(matches.isEmpty)
        }
    }

    // MARK: - Logic

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            if response == .OK {
                addFiles(urls: panel.urls)
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    addFiles(urls: [url])
                }
            }
        }
    }

    private func addFiles(urls: [URL]) {
        let newFiles = urls.compactMap { url -> SelectedFile? in
            guard !selectedFiles.contains(where: { $0.url == url }) else { return nil }
            let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
            let size = Int64(resourceValues?.fileSize ?? 0)
            return SelectedFile(url: url, name: url.lastPathComponent, size: size)
        }
        selectedFiles.append(contentsOf: newFiles)
    }

    private func replacedName(for name: String) -> String {
        if useRegex {
            let options: NSRegularExpression.Options = matchCase ? [] : [.caseInsensitive]
            guard let regex = try? NSRegularExpression(pattern: findText, options: options) else {
                return name
            }
            let range = NSRange(name.startIndex..., in: name)
            return regex.stringByReplacingMatches(in: name, range: range, withTemplate: replaceText)
        } else {
            if matchCase {
                return name.replacingOccurrences(of: findText, with: replaceText)
            } else {
                return name.replacingOccurrences(of: findText, with: replaceText, options: .caseInsensitive)
            }
        }
    }

    private func findRanges(in name: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        if useRegex {
            let options: NSRegularExpression.Options = matchCase ? [] : [.caseInsensitive]
            guard let regex = try? NSRegularExpression(pattern: findText, options: options) else {
                return []
            }
            let nsRange = NSRange(name.startIndex..., in: name)
            let results = regex.matches(in: name, range: nsRange)
            for result in results {
                if let range = Range(result.range, in: name) {
                    ranges.append(range)
                }
            }
        } else {
            var searchRange = name.startIndex..<name.endIndex
            let compareOptions: String.CompareOptions = matchCase ? [] : [.caseInsensitive]
            while let range = name.range(of: findText, options: compareOptions, range: searchRange) {
                ranges.append(range)
                searchRange = range.upperBound..<name.endIndex
            }
        }
        return ranges
    }

    private func findReplacementRanges(in newName: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = newName.startIndex..<newName.endIndex
        while let range = newName.range(of: replaceText, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<newName.endIndex
        }
        return ranges
    }

    private func renameFiles() {
        var renamed = 0
        var errors: [String] = []

        for match in matches {
            let originalURL = match.file.url
            let newURL = originalURL.deletingLastPathComponent().appendingPathComponent(match.newName)

            do {
                try FileManager.default.moveItem(at: originalURL, to: newURL)
                renamed += 1
            } catch {
                errors.append("\(match.file.name): \(error.localizedDescription)")
            }
        }

        if !errors.isEmpty {
            renameError = errors.joined(separator: "\n")
            showError = true
        }

        if renamed > 0 {
            successCount = renamed
            showSuccess = true
            selectedFiles.removeAll()
            findText = ""
            replaceText = ""
        }
    }

    private func clearAll() {
        selectedFiles.removeAll()
        findText = ""
        replaceText = ""
        matchCase = false
        useRegex = false
    }
}

#Preview {
    ContentView()
}
