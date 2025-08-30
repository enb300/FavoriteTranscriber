import Foundation
import AVFoundation

enum WhisperError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case transcriptionFailed(String)
    case audioFileTooLarge
    case unsupportedFormat
    case rateLimitExceeded
    case quotaExceeded
    case invalidAudioFile
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your API key and try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .audioFileTooLarge:
            return "Audio file is too large. Maximum size is 25MB."
        case .unsupportedFormat:
            return "Unsupported audio format. Please use MP3, M4A, WAV, MP4, MPEG, MPGA, or WEBM."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .quotaExceeded:
            return "API quota exceeded. Please check your OpenAI account usage."
        case .invalidAudioFile:
            return "Invalid audio file. Please ensure the file is not corrupted."
        case .serverError(let code):
            return "Server error (HTTP \(code)). Please try again later."
        }
    }
}

@MainActor
class WhisperService: ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var currentStatus: String = ""
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    
    // Rate limiting and retry configuration
    private var lastRequestTime: Date = Date.distantPast
    private let minRequestInterval: TimeInterval = 0.1 // 100ms between requests
    private let maxRetries = 3
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func transcribeAudio(_ audioFile: AudioFile) async throws -> Transcription {
        guard !apiKey.isEmpty else {
            throw WhisperError.invalidAPIKey
        }
        
        // Check file size (Whisper API has a 25MB limit)
        let maxSize: Int64 = 25 * 1024 * 1024 // 25MB
        guard audioFile.fileSize <= maxSize else {
            throw WhisperError.audioFileTooLarge
        }
        
        // Check supported formats
        let supportedFormats = ["mp3", "mp4", "mpeg", "mpga", "m4a", "wav", "webm"]
        guard supportedFormats.contains(audioFile.format.lowercased()) else {
            throw WhisperError.unsupportedFormat
        }
        
        // Rate limiting
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < minRequestInterval {
            try await Task.sleep(nanoseconds: UInt64((minRequestInterval - timeSinceLastRequest) * 1_000_000_000))
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        currentStatus = "Preparing audio file..."
        
        defer {
            isTranscribing = false
            transcriptionProgress = 0.0
            currentStatus = ""
            lastRequestTime = Date()
        }
        
        let startTime = Date()
        
        do {
            let transcription = try await performTranscriptionWithRetry(audioFile)
            let processingTime = Date().timeIntervalSince(startTime)
            
            return Transcription(
                audioFileId: audioFile.id,
                text: transcription.text,
                language: transcription.language ?? "en",
                confidence: transcription.confidence ?? 0.0,
                processingTime: processingTime
            )
        } catch {
            throw error
        }
    }
    
    private func performTranscriptionWithRetry(_ audioFile: AudioFile) async throws -> WhisperResponse {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                currentStatus = "Transcribing audio (attempt \(attempt)/\(maxRetries))..."
                return try await performTranscription(audioFile)
            } catch WhisperError.rateLimitExceeded where attempt < maxRetries {
                // Wait longer for rate limit errors
                let waitTime = TimeInterval(attempt * 2)
                currentStatus = "Rate limited, waiting \(Int(waitTime))s..."
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                lastError = WhisperError.rateLimitExceeded
            } catch WhisperError.serverError(let code) where code >= 500 && attempt < maxRetries {
                // Retry server errors
                let waitTime = TimeInterval(attempt)
                currentStatus = "Server error, retrying in \(Int(waitTime))s..."
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                lastError = WhisperError.serverError(code)
            } catch {
                throw error
            }
        }
        
        throw lastError ?? WhisperError.transcriptionFailed("Max retries exceeded")
    }
    
    private func performTranscription(_ audioFile: AudioFile) async throws -> WhisperResponse {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 300 // 5 minutes for long audio files
        
        // Set headers
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("OpenAI-Organization", forHTTPHeaderField: "OpenAI-Organization") // Optional
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        let audioData = try Data(contentsOf: audioFile.url)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioFile.name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/\(audioFile.format)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model parameter (using latest Whisper model)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter (optional, for better accuracy)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response format for detailed information
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        // Add temperature for controlling randomness (0.0 = deterministic)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0.0\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Progress tracking for long files
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.transcriptionProgress < 0.9 {
                self.transcriptionProgress += 0.05
            }
        }
        
        defer {
            progressTimer.invalidate()
        }
        
        currentStatus = "Sending audio to OpenAI..."
        transcriptionProgress = 0.1
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.networkError(NSError(domain: "WhisperService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        // Handle different HTTP status codes
        switch httpResponse.statusCode {
        case 200:
            transcriptionProgress = 1.0
            currentStatus = "Processing response..."
        case 400:
            throw WhisperError.invalidAudioFile
        case 401:
            throw WhisperError.invalidAPIKey
        case 429:
            throw WhisperError.rateLimitExceeded
        case 500...599:
            throw WhisperError.serverError(httpResponse.statusCode)
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WhisperError.transcriptionFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            let whisperResponse = try JSONDecoder().decode(WhisperResponse.self, from: data)
            return whisperResponse
        } catch {
            throw WhisperError.transcriptionFailed("Failed to decode response: \(error.localizedDescription)")
        }
    }
}

// MARK: - Response Models

struct WhisperResponse: Codable {
    let text: String
    let language: String?
    let confidence: Double?
    let duration: Double?
    let segments: [WhisperSegment]?
    
    enum CodingKeys: String, CodingKey {
        case text
        case language
        case confidence
        case duration
        case segments
    }
}

struct WhisperSegment: Codable {
    let id: Int
    let start: Double
    let end: Double
    let text: String
    let confidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case start
        case end
        case text
        case confidence
    }
}
