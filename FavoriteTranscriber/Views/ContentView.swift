import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        NavigationSplitView {
            AudioControlSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 350, ideal: 420, max: 500)
                .background(Color(NSColor.controlBackgroundColor))
        } detail: {
            TranscriptionContentView(viewModel: viewModel)
                .background(Color(NSColor.textBackgroundColor))
        }
        .navigationTitle("FavoriteTranscriber")
        .navigationSubtitle("AI-Powered Audio Transcription")
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                textSizeControl
                Divider().frame(height: 20)
                serviceIndicator
                Divider().frame(height: 20)
                clearAllButton
                helpButton
            }
        }
        .frame(minWidth: 1200, minHeight: 1000)
        .environment(\.textSizeMultiplier, viewModel.textSizeMultiplier)
        .onAppear {
            viewModel.loadTranscriptions()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Toolbar Components
    private var textSizeControl: some View {
        HStack(spacing: 6) {
            Image(systemName: "textformat.size")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Slider(
                value: Binding(
                    get: { viewModel.textSizeMultiplier },
                    set: { viewModel.setTextSize($0) }
                ),
                in: 0.8...2.0,
                step: 0.2
            )
            .frame(width: 80)
            .controlSize(.mini)
            
            Text("\(Int(viewModel.textSizeMultiplier * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 28)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
    
    private var serviceIndicator: some View {
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
    }
    
    private var clearAllButton: some View {
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
    }
    
    private var helpButton: some View {
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

#Preview {
    ContentView()
}
