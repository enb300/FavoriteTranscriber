import SwiftUI

struct AudioControlSidebar: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header Section
                headerSection
                
                // Recording Section
                recordingSection
                
                // Import Section
                importSection
                
                // Service Configuration Section
                serviceConfigurationSection
                
                // Current Audio File Section
                if let audioFile = viewModel.audioService.currentAudioFile {
                    currentAudioFileSection(audioFile)
                } else {
                    emptyStateSection
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title)
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Controls")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Record or import audio for transcription")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Recording Section
    private var recordingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "record.circle", title: "Recording", color: .red)
            
            // Main Recording Button
            Button(action: {
                if viewModel.audioService.isRecording {
                    viewModel.stopRecording()
                } else {
                    Task {
                        await viewModel.startRecording()
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.audioService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3)
                    
                    Text(viewModel.audioService.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.audioService.isRecording ? 
                              Color.red.gradient : 
                              Color.green.gradient)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(ModernButtonStyle())
            .accessibilityLabel(viewModel.audioService.isRecording ? "Stop recording audio" : "Start recording audio")
            
            // Recording Status
            if viewModel.audioService.isRecording {
                recordingStatusView
            }
            
            // Permission Status
            if !viewModel.audioService.permissionStatus.isEmpty {
                permissionStatusView
            }
        }
    }
    
    // MARK: - Import Section
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "folder.badge.plus", title: "Import Audio", color: .blue)
            
            Button(action: viewModel.importAudioFile) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title3)
                    
                    Text("Import Audio File")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.gradient)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(ModernButtonStyle())
            .accessibilityLabel("Import audio file")
            
            // Supported Formats
            supportedFormatsView
        }
    }
    
    // MARK: - Service Configuration Section
    private var serviceConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "gearshape.2", title: "Transcription Service", color: .purple)
            
            // Service Selection
            VStack(alignment: .leading, spacing: 12) {
                Picker("Transcription Service", selection: $viewModel.selectedService) {
                    Text("Local Whisper").tag(TranscriptionService.local)
                    Text("OpenAI API").tag(TranscriptionService.openai)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.selectedService) { _, newService in
                    viewModel.selectService(newService)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: viewModel.selectedService == .local ? "desktopcomputer" : "cloud")
                        .foregroundColor(viewModel.selectedService == .local ? .green : .blue)
                    Text(viewModel.selectedService.description)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            }
            
            // OpenAI API Key Input (only show when OpenAI is selected)
            if viewModel.selectedService == .openai {
                apiKeySection
            }
            
            // Model Selection (only show for Local Whisper)
            if viewModel.selectedService == .local {
                modelSelectionSection
            }
        }
    }
    
    // MARK: - Current Audio File Section
    private func currentAudioFileSection(_ audioFile: AudioFile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "waveform", title: "Current Audio", color: .green)
            
            // Audio File Info Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 32, height: 32)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(audioFile.name)
                            .font(.headline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        HStack(spacing: 16) {
                            Label("\(audioFile.duration, specifier: "%.1f")s", systemImage: "clock")
                            Label(ByteCountFormatter.string(fromByteCount: audioFile.fileSize, countStyle: .file), systemImage: "doc")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            
            // Transcribe Button
            transcribeButton
        }
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Audio File")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Record or import an audio file to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .strokeBorder(Color(NSColor.separatorColor), lineWidth: 1, antialiased: true)
        )
    }
    
    // MARK: - Helper Views
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private var recordingStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "record.circle")
                .foregroundColor(.red)
                .font(.caption)
            
            Text("Recording: \(viewModel.audioService.recordingTime, specifier: "%.1f")s")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.red)
            
            Spacer()
            
            // Animated recording indicator
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.audioService.isRecording)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
    
    private var permissionStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            
            Text(viewModel.audioService.permissionStatus)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var supportedFormatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supported Formats")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("MP3, M4A, WAV, MP4, MPEG, MPGA, WEBM")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
    }
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenAI API Key")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            SecureField("Enter your OpenAI API key", text: Binding(
                get: { viewModel.openAIWhisperService?.apiKey ?? "" },
                set: { viewModel.openAIWhisperService?.updateAPIKey($0) }
            ))
            .textFieldStyle(ModernTextFieldStyle())
            
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Get your API key from")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Link("platform.openai.com", destination: URL(string: "https://platform.openai.com")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Whisper Model")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Picker("Model", selection: Binding(
                get: { viewModel.localWhisperService?.modelSize ?? "small" },
                set: { viewModel.localWhisperService?.modelSize = $0 }
            )) {
                ForEach(LocalWhisperService.availableModels, id: \.0) { model, description in
                    Text(model.capitalized)
                        .tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            
            if let currentModel = LocalWhisperService.availableModels.first(where: { $0.0 == (viewModel.localWhisperService?.modelSize ?? "small") }) {
                Text(currentModel.1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private var transcribeButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await viewModel.transcribeCurrentAudio()
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.currentWhisperService?.isTranscribing == true {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Transcribing...")
                            .font(.body)
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "waveform.and.mic")
                            .font(.title3)
                        
                        Text("Transcribe Audio")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.gradient)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(ModernButtonStyle())
            .disabled(viewModel.audioService.currentAudioFile == nil || viewModel.currentWhisperService?.isTranscribing == true)
            .accessibilityLabel("Transcribe the current audio file")
            
            // Show transcription progress
            if viewModel.currentWhisperService?.isTranscribing == true {
                transcriptionProgressView
            }
        }
    }
    
    private var transcriptionProgressView: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.currentWhisperService?.transcriptionProgress ?? 0)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            
            if let status = viewModel.currentWhisperService?.currentStatus, !status.isEmpty {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("\(Int((viewModel.currentWhisperService?.transcriptionProgress ?? 0) * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom Button Style
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.textBackgroundColor))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
    }
}

#Preview {
    AudioControlSidebar(viewModel: TranscriptionViewModel())
        .frame(width: 350, height: 800)
}