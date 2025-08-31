import SwiftUI

struct TranscriptionContentView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content - just show current transcription
            CurrentTranscriptionView(viewModel: viewModel)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transcription Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(viewModel.transcriptions.count) transcription\(viewModel.transcriptions.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
        }
    }
}

// MARK: - Current Transcription View
struct CurrentTranscriptionView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        Group {
            if !viewModel.transcriptions.isEmpty {
                currentTranscriptionContent
            } else if viewModel.currentWhisperService?.isTranscribing == true {
                transcriptionInProgressView
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var currentTranscriptionContent: some View {
        let transcription = viewModel.transcriptions.first!
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Transcription Header Card
                transcriptionHeaderCard(transcription)
                
                // Transcription Text Card
                transcriptionTextCard(transcription)
                
                // Action Buttons
                actionButtonsSection(transcription)
                
                Spacer(minLength: 32)
            }
            .padding(24)
        }
    }
    
    private func transcriptionHeaderCard(_ transcription: Transcription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transcription Complete")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Generated \(formatDate(transcription.timestamp))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence Badge
                confidenceBadge(transcription.confidence)
            }
            
            // Metadata Row 1
            HStack(spacing: 20) {
                metadataItem(icon: "globe", title: "Language", value: transcription.language.uppercased())
                metadataItem(icon: "clock", title: "Processing", value: String(format: "%.1fs", transcription.processingTime))
                metadataItem(icon: "cpu", title: "Model", value: transcription.modelUsed)
                metadataItem(icon: "cloud", title: "Service", value: transcription.serviceType)
            }
            
            // Metadata Row 2
            HStack(spacing: 20) {
                metadataItem(icon: "textformat.size", title: "Characters", value: "\(transcription.text.count)")
                metadataItem(icon: "textformat", title: "Words", value: "\(transcription.wordCount)")
                metadataItem(icon: "list.bullet", title: "Sentences", value: "\(transcription.sentenceCount)")
                metadataItem(icon: "chart.bar", title: "Avg Words/Sentence", value: String(format: "%.1f", transcription.averageWordsPerSentence))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func transcriptionTextCard(_ transcription: Transcription) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.title3)
                    .foregroundColor(.primary)
                
                Text("Transcribed Text")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Copy button
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(transcription.text, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(ModernSecondaryButtonStyle())
            }
            
            ScrollView {
                Text(transcription.text)
                    .font(.body)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.textBackgroundColor))
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            }
            .frame(minHeight: 200, maxHeight: 400)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func actionButtonsSection(_ transcription: Transcription) -> some View {
        VStack(spacing: 12) {
            // Pages Integration Row
            HStack(spacing: 12) {
                Button(action: {
                    openInNewPagesDocument(transcription)
                }) {
                    Label("New Pages Document", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernPrimaryButtonStyle())
                
                Button(action: {
                    appendToCurrentPagesDocument(transcription)
                }) {
                    Label("Add to Current Pages", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernSecondaryButtonStyle())
            }
            
            // Other Actions Row
            HStack(spacing: 12) {
                Button(action: {
                    exportTranscription(transcription)
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernSecondaryButtonStyle())
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.deleteTranscription(transcription)
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernDangerButtonStyle())
            }
        }
    }
    
    private var transcriptionInProgressView: some View {
        VStack(spacing: 32) {
            // Animated waveform icon
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.currentWhisperService?.isTranscribing)
            
            VStack(spacing: 16) {
                Text("Transcription in Progress")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let status = viewModel.currentWhisperService?.currentStatus, !status.isEmpty {
                    Text(status)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.currentWhisperService?.transcriptionProgress ?? 0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .frame(width: 300)
                    
                    Text("\(Int((viewModel.currentWhisperService?.transcriptionProgress ?? 0) * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No Transcriptions Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Record or import an audio file to create your first transcription")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            // Quick action buttons
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await viewModel.startRecording()
                    }
                }) {
                    Label("Start Recording", systemImage: "mic.circle.fill")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(ModernPrimaryButtonStyle())
                
                Button(action: viewModel.importAudioFile) {
                    Label("Import File", systemImage: "folder.badge.plus")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(ModernSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Helper Views
    private func confidenceBadge(_ confidence: Double) -> some View {
        let color: Color = confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red
        let text = confidence > 0.8 ? "High" : confidence > 0.6 ? "Medium" : "Low"
        
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(text) Confidence")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
    
    private func metadataItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func exportTranscription(_ transcription: Transcription) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "transcription_\(Int(transcription.timestamp.timeIntervalSince1970)).txt"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            let content = createDetailedTranscriptionText(transcription)
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func openInNewPagesDocument(_ transcription: Transcription) {
        let content = createDetailedTranscriptionText(transcription)
        
        // Create a temporary file with the content
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcription_\(Int(transcription.timestamp.timeIntervalSince1970)).rtf")
        
        do {
            // Create RTF content for better formatting in Pages
            let rtfContent = createRTFContent(transcription)
            try rtfContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Open with Pages
            do {
                _ = try NSWorkspace.shared.open([tempURL], withApplicationAt: pagesAppURL(), options: [], configuration: [:])
            } catch {
                print("Error opening in Pages: \(error)")
                // Fallback to default app
                NSWorkspace.shared.open(tempURL)
            }
        } catch {
            print("Error creating document: \(error)")
        }
    }
    
    private func appendToCurrentPagesDocument(_ transcription: Transcription) {
        // Copy transcription text to clipboard
        let content = createDetailedTranscriptionText(transcription)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        
        // Try to bring Pages to front if it's running
        let runningApps = NSWorkspace.shared.runningApplications
        if let pagesApp = runningApps.first(where: { $0.bundleIdentifier == "com.apple.iWork.Pages" }) {
            pagesApp.activate()
            
            // Show notification that content is ready to paste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let alert = NSAlert()
                alert.messageText = "Content Ready"
                alert.informativeText = "The transcription has been copied to your clipboard. Switch to Pages and paste (⌘V) where you'd like to add it."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } else {
            // Pages is not running, offer to open it
            let alert = NSAlert()
            alert.messageText = "Pages Not Running"
            alert.informativeText = "Pages is not currently running. The transcription has been copied to your clipboard. Would you like to open Pages?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Pages")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(pagesAppURL())
            }
        }
    }
    
    private func createDetailedTranscriptionText(_ transcription: Transcription) -> String {
        return """
        Transcription Export
        Generated: \(formatDate(transcription.timestamp))
        
        Statistics:
        • Language: \(transcription.language.uppercased())
        • Service: \(transcription.serviceType)
        • Model: \(transcription.modelUsed)
        • Confidence: \(String(format: "%.1f%%", transcription.confidence * 100))
        • Processing Time: \(String(format: "%.1fs", transcription.processingTime))
        • Characters: \(transcription.text.count)
        • Words: \(transcription.wordCount)
        • Sentences: \(transcription.sentenceCount)
        • Average Words per Sentence: \(String(format: "%.1f", transcription.averageWordsPerSentence))
        
        ---
        
        \(transcription.text)
        """
    }
    
    private func createRTFContent(_ transcription: Transcription) -> String {
        return """
        {\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}
        \\f0\\fs24 
        {\\b Transcription Export}\\par
        \\par
        {\\b Generated:} \(formatDate(transcription.timestamp))\\par
        \\par
        {\\b Statistics:}\\par
        • Language: \(transcription.language.uppercased())\\par
        • Service: \(transcription.serviceType)\\par
        • Model: \(transcription.modelUsed)\\par
        • Confidence: \(String(format: "%.1f%%", transcription.confidence * 100))\\par
        • Processing Time: \(String(format: "%.1fs", transcription.processingTime))\\par
        • Characters: \(transcription.text.count)\\par
        • Words: \(transcription.wordCount)\\par
        • Sentences: \(transcription.sentenceCount)\\par
        • Average Words per Sentence: \(String(format: "%.1f", transcription.averageWordsPerSentence))\\par
        \\par
        {\\b Content:}\\par
        \(transcription.text.replacingOccurrences(of: "\n", with: "\\par "))\\par
        }
        """
    }
    
    private func pagesAppURL() -> URL {
        // Try to find Pages in Applications
        let possiblePaths = [
            "/Applications/Pages.app",
            "/System/Applications/Pages.app"
        ]
        
        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        // Fallback to bundle identifier
        return URL(fileURLWithPath: "/Applications/Pages.app")
    }
}

// MARK: - History View
struct TranscriptionHistoryView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        Group {
            if viewModel.transcriptions.isEmpty {
                emptyHistoryView
            } else {
                historyListView
            }
        }
    }
    
    private var historyListView: some View {
        List {
            ForEach(viewModel.transcriptions) { transcription in
                TranscriptionHistoryRow(transcription: transcription, viewModel: viewModel)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No History")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("Your transcription history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - History Row
struct TranscriptionHistoryRow: View {
    let transcription: Transcription
    @ObservedObject var viewModel: TranscriptionViewModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(transcription.timestamp))
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            Label(transcription.language.uppercased(), systemImage: "globe")
                            Label(transcription.serviceType, systemImage: transcription.serviceType.contains("OpenAI") ? "cloud" : "desktopcomputer")
                            Label(transcription.modelUsed, systemImage: "cpu")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Label("\(transcription.wordCount) words", systemImage: "textformat")
                            Label("\(transcription.sentenceCount) sentences", systemImage: "list.bullet")
                            Label(String(format: "%.1fs", transcription.processingTime), systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Preview text (always visible)
            Text(transcription.text)
                .font(.body)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)
            
            // Expanded content
            if isExpanded {
                HStack(spacing: 12) {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcription.text, forType: .string)
                    }
                    .buttonStyle(ModernSecondaryButtonStyle())
                    
                    Button("Delete") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.deleteTranscription(transcription)
                        }
                    }
                    .buttonStyle(ModernDangerButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Custom Button Styles
struct ModernPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.gradient)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.red)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    TranscriptionContentView(viewModel: TranscriptionViewModel())
}