import SwiftUI

struct TranscriptionContentView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Current").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Divider()
                .background(Color(NSColor.separatorColor))
            
            // Tab Content
            TabView(selection: $selectedTab) {
                // Current Transcription Tab
                CurrentTranscriptionView(viewModel: viewModel)
                    .tag(0)
                
                // Transcription History Tab
                TranscriptionHistoryView(viewModel: viewModel)
                    .tag(1)
            }
            .tabViewStyle(DefaultTabViewStyle())
        }
    }
}

struct CurrentTranscriptionView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack {
            if let transcription = viewModel.currentTranscription {
                // Transcription Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Transcription Result")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            Label("Language: \(transcription.language.uppercased())", systemImage: "globe")
                            Label("Confidence: \(Int(transcription.confidence * 100))%", systemImage: "checkmark.circle")
                            Label("Processing Time: \(String(format: "%.1f", transcription.processingTime))s", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Clear") {
                        viewModel.clearCurrentTranscription()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Divider()
                    .background(Color(NSColor.separatorColor))
                
                // Transcription Text
                ScrollView {
                    Text(transcription.text)
                        .font(.body)
                        .lineSpacing(4)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .padding()
                
                // Action Buttons
                HStack {
                    Button("Copy to Clipboard") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcription.text, forType: .string)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Save to File") {
                        saveTranscriptionToFile(transcription)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                .padding()
                
            } else if viewModel.whisperService?.isTranscribing == true {
                // Transcription in Progress
                VStack(spacing: 24) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Transcribing Audio...")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    // Status and Progress
                    VStack(spacing: 16) {
                        if let status = viewModel.whisperService?.currentStatus, !status.isEmpty {
                            Text(status)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        ProgressView(value: viewModel.whisperService?.transcriptionProgress ?? 0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 300)
                        
                        Text("\(Int((viewModel.whisperService?.transcriptionProgress ?? 0) * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // No Transcription State
                VStack(spacing: 20) {
                    Image(systemName: "waveform")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Transcription Yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Record audio or import an audio file, then click 'Transcribe Audio' to get started.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func saveTranscriptionToFile(_ transcription: Transcription) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "transcription_\(Date().timeIntervalSince1970).txt"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            let content = """
            Transcription
            =============
            
            Date: \(transcription.timestamp)
            Language: \(transcription.language)
            Confidence: \(Int(transcription.confidence * 100))%
            Processing Time: \(String(format: "%.1f", transcription.processingTime))s
            
            Text:
            \(transcription.text)
            """
            
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to save transcription: \(error)")
            }
        }
    }
}

struct TranscriptionHistoryView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack {
            if viewModel.transcriptions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Transcription History")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Your transcriptions will appear here once you start transcribing audio files.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.transcriptions.reversed()) { transcription in
                        TranscriptionHistoryRow(
                            transcription: transcription,
                            onDelete: {
                                viewModel.deleteTranscription(transcription)
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct TranscriptionHistoryRow: View {
    let transcription: Transcription
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(transcription.text.prefix(100) + (transcription.text.count > 100 ? "..." : ""))
                        .font(.body)
                        .lineLimit(3)
                    
                    HStack(spacing: 16) {
                        Label(transcription.language.uppercased(), systemImage: "globe")
                        Label("\(Int(transcription.confidence * 100))%", systemImage: "checkmark.circle")
                        Label("\(String(format: "%.1f", transcription.processingTime))s", systemImage: "clock")
                        Label(formatDate(transcription.timestamp), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TranscriptionContentView(viewModel: TranscriptionViewModel())
}
