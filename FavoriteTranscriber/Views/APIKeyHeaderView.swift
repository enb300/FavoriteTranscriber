import SwiftUI

struct APIKeyHeaderView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @State private var isEditing = false
    @State private var tempAPIKey = ""
    
    var body: some View {
        HStack {
            Image(systemName: "key.fill")
                .foregroundColor(.blue)
            
            if isEditing {
                SecureField("Enter OpenAI API Key", text: $tempAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Button("Save") {
                    viewModel.updateAPIKey(tempAPIKey)
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    tempAPIKey = viewModel.apiKey
                    isEditing = false
                }
                .buttonStyle(.bordered)
            } else {
                Text("OpenAI API Key: \(maskedAPIKey)")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Edit") {
                    tempAPIKey = viewModel.apiKey
                    isEditing = true
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.whisperService != nil ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.whisperService != nil ? "Connected" : "Not Connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 0.5)
    }
    
    private var maskedAPIKey: String {
        let key = viewModel.apiKey
        if key.isEmpty {
            return "Not Set"
        } else if key.count <= 8 {
            return String(repeating: "•", count: key.count)
        } else {
            let prefix = String(key.prefix(4))
            let suffix = String(key.suffix(4))
            let middle = String(repeating: "•", count: key.count - 8)
            return "\(prefix)\(middle)\(suffix)"
        }
    }
}

#Preview {
    APIKeyHeaderView(viewModel: TranscriptionViewModel())
}
