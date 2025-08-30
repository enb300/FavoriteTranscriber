import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with app title
                VStack(spacing: 8) {
                    Text("Favorite Transcriber")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI-Powered Audio Transcription")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                HStack(spacing: 0) {
                    AudioControlSidebar(viewModel: viewModel)
                        .frame(width: 320)
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                        .background(Color(NSColor.separatorColor))
                    
                    TranscriptionContentView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Favorite Transcriber")
        .navigationSubtitle("AI-Powered Audio Transcription")
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            viewModel.loadTranscriptions()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    // Toggle sidebar visibility
                }) {
                    Image(systemName: "sidebar.left")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Help") {
                    // Show help documentation
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
