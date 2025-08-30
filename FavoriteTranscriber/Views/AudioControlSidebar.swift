import SwiftUI

struct AudioControlSidebar: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Recording Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("Recording")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                // Recording Controls
                VStack(spacing: 12) {
                    HStack {
                        Text("Recording")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    // Permission Status
                    VStack(spacing: 4) {
                        Text("Microphone Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.audioService.permissionStatus)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                    }
                    
                    // Record Button
                    Button(action: {
                        Task {
                            await viewModel.startRecording()
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.audioService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                            Text(viewModel.audioService.isRecording ? "Stop Recording" : "Start Recording")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(viewModel.audioService.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .disabled(viewModel.audioService.permissionStatus.contains("denied") || viewModel.audioService.permissionStatus.contains("restricted"))
                    .accessibilityLabel(viewModel.audioService.isRecording ? "Stop recording" : "Start recording")
                    
                    // Recording Timer
                    if viewModel.audioService.isRecording {
                        VStack(spacing: 4) {
                            Text("Recording Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%02d:%02d", Int(viewModel.audioService.recordingTime) / 60, Int(viewModel.audioService.recordingTime) % 60))
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Divider()
                .background(Color(NSColor.separatorColor))
            
            // Import Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "folder.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Import Audio")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Button(action: viewModel.importAudioFile) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text("Import Audio File")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Import audio file")
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Supported formats:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("MP3, M4A, WAV, MP4, MPEG, MPGA, WEBM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
            
            Divider()
                .background(Color(NSColor.separatorColor))
            
            // Current Audio File Info
            if let audioFile = viewModel.audioService.currentAudioFile {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Current Audio File")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(audioFile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        
                        VStack(spacing: 8) {
                            AudioFileInfoRow(label: "Duration", value: viewModel.formatDuration(audioFile.duration), icon: "clock")
                            AudioFileInfoRow(label: "Size", value: viewModel.formatFileSize(audioFile.fileSize), icon: "externaldrive")
                            AudioFileInfoRow(label: "Format", value: audioFile.format.uppercased(), icon: "doc.text")
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    
                    // Transcribe Audio Button
                    Button(action: {
                        Task {
                            await viewModel.transcribeCurrentAudio()
                        }
                    }) {
                        HStack {
                            if viewModel.whisperService?.isTranscribing == true {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Transcribing...")
                            } else {
                                Image(systemName: "waveform")
                                Text("Transcribe Audio")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .disabled(viewModel.audioService.currentAudioFile == nil || viewModel.whisperService?.isTranscribing == true)
                    .accessibilityLabel("Transcribe the current audio file")
                    
                    // Show status if transcribing
                    if viewModel.whisperService?.isTranscribing == true {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.whisperService?.transcriptionProgress ?? 0)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text(viewModel.whisperService?.currentStatus ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Show message if no audio file
                    if viewModel.audioService.currentAudioFile == nil {
                        VStack(spacing: 12) {
                            Image(systemName: "waveform.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("No Audio File")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Record audio or import a file to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            } else {
                // No Audio File State
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "waveform.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No Audio File")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Record audio or import a file to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(20)
    }
}

struct AudioFileInfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    AudioControlSidebar(viewModel: TranscriptionViewModel())
}
