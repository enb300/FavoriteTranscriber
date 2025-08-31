import Foundation
import SwiftUI
import Combine

enum TranscriptionService: String, CaseIterable {
    case local = "Local Whisper"
    case openai = "OpenAI API"
    
    var description: String {
        switch self {
        case .local:
            return "Free, runs locally, slower"
        case .openai:
            return "Paid, cloud-based, faster & more accurate"
        }
    }
}

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var audioService = AudioService()
    @Published var localWhisperService: LocalWhisperService?
    @Published var openAIWhisperService: OpenAIWhisperService?
    @Published var selectedService: TranscriptionService = .local
    @Published var transcriptions: [Transcription] = []
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentWhisperService: (any WhisperServiceProtocol)? {
        switch selectedService {
        case .local:
            return localWhisperService
        case .openai:
            return openAIWhisperService
        }
    }
    
    init() {
        // Initialize both services
        localWhisperService = LocalWhisperService()
        openAIWhisperService = OpenAIWhisperService()
        loadTranscriptions()
        loadSelectedService()
        
        // Subscribe to audioService changes to propagate to our objectWillChange
        audioService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Subscribe to both whisper services
        localWhisperService?.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        openAIWhisperService?.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
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
        
        guard let whisperService = currentWhisperService else {
            showError(message: "Whisper service not available. Please select a transcription service.")
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
        guard let whisperService = currentWhisperService else {
            showError(message: "Whisper service not available. Please select a transcription service.")
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
    
    // MARK: - Service Selection
    
    func selectService(_ service: TranscriptionService) {
        selectedService = service
        saveSelectedService()
    }
    
    private func saveSelectedService() {
        UserDefaults.standard.set(selectedService.rawValue, forKey: "selected_transcription_service")
    }
    
    private func loadSelectedService() {
        if let savedService = UserDefaults.standard.string(forKey: "selected_transcription_service"),
           let service = TranscriptionService(rawValue: savedService) {
            selectedService = service
        }
    }
    
    // MARK: - Data Persistence
    
    func saveTranscriptions() {
        if let encoded = try? JSONEncoder().encode(transcriptions) {
            UserDefaults.standard.set(encoded, forKey: "transcriptions")
        }
    }
    
    func loadTranscriptions() {
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
