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
        .navigationSplitViewColumnVisibility(.all)
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
        .frame(minWidth: 1000, minHeight: 700)
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
}

#Preview {
    ContentView()
}
