import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        NavigationSplitView {
            AudioControlSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 450)
                .background(Color(NSColor.controlBackgroundColor))
        } detail: {
            TranscriptionContentView(viewModel: viewModel)
                .background(Color(NSColor.textBackgroundColor))
        }
        .navigationTitle("FavoriteTranscriber")
        .navigationSubtitle("AI-Powered Audio Transcription")
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Service indicator
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedService == .local ? "desktopcomputer" : "cloud")
                        .foregroundColor(viewModel.selectedService == .local ? .green : .blue)
                    Text(viewModel.selectedService.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
                
                Divider()
                    .frame(height: 20)
                
                // Clear all button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.transcriptions.removeAll()
                        viewModel.saveTranscriptions()
                    }
                }) {
                    Label("Clear All", systemImage: "trash")
                }
                .disabled(viewModel.transcriptions.isEmpty)
                .help("Clear all transcriptions")
                
                // Help button
                Button(action: {
                    if let url = URL(string: "https://developer.apple.com/design/human-interface-guidelines") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .help("View help documentation")
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            viewModel.loadTranscriptions()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

#Preview {
    ContentView()
}
