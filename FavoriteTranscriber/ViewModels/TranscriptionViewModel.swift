import Foundation
import SwiftUI

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var audioService = AudioService()
    @Published var whisperService: LocalWhisperService?
    @Published var transcriptions: [Transcription] = []
    @Published var showError = false
    @Published var errorMessage: String?
    
    init() {
        // Initialize local Whisper service (no API key needed)
        whisperService = LocalWhisperService()
        loadTranscriptions()
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        // Let AudioService handle permission checking when actually needed
        // This prevents early microphone access that could cause privacy crashes
        Task {
            await audioService.startRecording()
        }
    }
    
    func stopRecording() {
        audioService.stopRecording()
    }
    
    // MARK: - Audio Import
    
    func importAudioFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Select Audio File"
        panel.message = "Choose an audio file to transcribe"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            audioService.importAudioFile(from: url)
        }
    }
    
    // MARK: - Transcription
    
    func transcribeCurrentAudio() async {
        guard let audioFile = audioService.currentAudioFile else {
            showError(message: "No audio file selected. Please record or import an audio file first.")
            return
        }
        
        guard let whisperService = whisperService else {
            showError(message: "Whisper service not available. Please ensure Whisper is properly installed.")
            return
        }
        
        do {
            let transcription = try await whisperService.transcribeAudioFile(audioFile)
            transcriptions.insert(transcription, at: 0)
            saveTranscriptions()
        } catch {
            showError(message: "Transcription failed: \(error.localizedDescription)")
        }
    }
    
    func transcribeAudioFile(_ audioFile: AudioFile) async {
        guard let whisperService = whisperService else {
            showError(message: "Whisper service not available. Please ensure Whisper is properly installed.")
            return
        }
        
        do {
            let transcription = try await whisperService.transcribeAudioFile(audioFile)
            transcriptions.insert(transcription, at: 0)
            saveTranscriptions()
        } catch {
            showError(message: "Transcription failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Data Persistence
    
    private func saveTranscriptions() {
        if let encoded = try? JSONEncoder().encode(transcriptions) {
            UserDefaults.standard.set(encoded, forKey: "transcriptions")
        }
    }
    
    private func loadTranscriptions() {
        if let data = UserDefaults.standard.data(forKey: "transcriptions"),
           let decoded = try? JSONDecoder().decode([Transcription].self, from: data) {
            transcriptions = decoded
        }
    }
    
    func deleteTranscription(_ transcription: Transcription) {
        transcriptions.removeAll { $0.id == transcription.id }
        saveTranscriptions()
    }
}
