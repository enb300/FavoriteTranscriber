import Foundation
import SwiftUI

@MainActor
class LocalWhisperService: ObservableObject {
    @Published var isTranscribing = false
    @Published var currentStatus = ""
    @Published var transcriptionProgress: Double = 0.0
    
    private let whisperScriptPath = "~/whisper.py"
    private let modelSize = "base" // Options: tiny, base, small, medium, large
    
    func transcribeAudioFile(_ audioFile: AudioFile) async throws -> Transcription {
        isTranscribing = true
        currentStatus = "Loading Whisper model..."
        transcriptionProgress = 0.1
        
        // Create a temporary directory for the transcription output
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("whisper_output_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        currentStatus = "Processing audio file..."
        transcriptionProgress = 0.3
        
        // Run the Whisper command
        let result = try await runWhisperCommand(audioFile: audioFile, outputDir: tempDir)
        
        currentStatus = "Finalizing transcription..."
        transcriptionProgress = 0.9
        
        // Parse the output files
        let transcription = try await parseWhisperOutput(outputDir: tempDir, originalAudioFile: audioFile)
        
        currentStatus = "Transcription complete!"
        transcriptionProgress = 1.0
        
        // Clean up temporary files
        try? FileManager.default.removeItem(at: tempDir)
        
        isTranscribing = false
        return transcription
    }
    
    private func runWhisperCommand(audioFile: AudioFile, outputDir: URL) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        
        // Arguments for the Whisper command
        let args = [
            "whisper", // The whisper command
            audioFile.url.path, // Input audio file
            "--model", modelSize, // Model size
            "--output_dir", outputDir.path, // Output directory
            "--output_format", "txt,json,srt,vtt", // Multiple output formats
            "--language", "en", // Language (can be auto-detected)
            "--verbose" // Verbose output for debugging
        ]
        
        process.arguments = args
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        currentStatus = "Running Whisper transcription..."
        transcriptionProgress = 0.5
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            throw WhisperError.commandFailed(error: error, output: output)
        }
        
        return output
    }
    
    private func parseWhisperOutput(outputDir: URL, originalAudioFile: AudioFile) async throws -> Transcription {
        // Look for the JSON output file first (most complete)
        let jsonFile = outputDir.appendingPathComponent("\(originalAudioFile.name).json")
        
        if FileManager.default.fileExists(atPath: jsonFile.path) {
            return try parseJSONOutput(jsonFile: jsonFile, originalAudioFile: originalAudioFile)
        }
        
        // Fallback to text file
        let txtFile = outputDir.appendingPathComponent("\(originalAudioFile.name).txt")
        if FileManager.default.fileExists(atPath: txtFile.path) {
            return try parseTextOutput(txtFile: txtFile, originalAudioFile: originalAudioFile)
        }
        
        throw WhisperError.noOutputFilesFound
    }
    
    private func parseJSONOutput(jsonFile: URL, originalAudioFile: AudioFile) throws -> Transcription {
        let jsonData = try Data(contentsOf: jsonFile)
        let whisperResult = try JSONDecoder().decode(WhisperLocalResult.self, from: jsonData)
        
        return Transcription(
            id: UUID(),
            audioFileName: originalAudioFile.name,
            audioFileSize: originalAudioFile.fileSize,
            audioDuration: originalAudioFile.duration,
            transcriptionText: whisperResult.text,
            language: whisperResult.language,
            confidence: whisperResult.confidence,
            timestamp: Date(),
            segments: whisperResult.segments.map { segment in
                TranscriptionSegment(
                    start: segment.start,
                    end: segment.end,
                    text: segment.text,
                    confidence: segment.confidence
                )
            }
        )
    }
    
    private func parseTextOutput(txtFile: URL, originalAudioFile: AudioFile) throws -> Transcription {
        let text = try String(contentsOf: txtFile, encoding: .utf8)
        
        return Transcription(
            id: UUID(),
            audioFileName: originalAudioFile.name,
            audioFileSize: originalAudioFile.fileSize,
            audioDuration: originalAudioFile.duration,
            transcriptionText: text,
            language: "en", // Default assumption
            confidence: 0.0, // Unknown for text output
            timestamp: Date(),
            segments: []
        )
    }
}

// MARK: - Local Whisper Models

struct WhisperLocalResult: Codable {
    let text: String
    let language: String
    let confidence: Double
    let segments: [WhisperLocalSegment]
}

struct WhisperLocalSegment: Codable {
    let start: Double
    let end: Double
    let text: String
    let confidence: Double
}

enum WhisperError: LocalizedError {
    case commandFailed(error: String, output: String)
    case noOutputFilesFound
    case modelNotFound
    case audioFileNotFound
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let error, let output):
            return "Whisper command failed: \(error)\nOutput: \(output)"
        case .noOutputFilesFound:
            return "No output files were generated by Whisper"
        case .modelNotFound:
            return "Whisper model not found. Please ensure Whisper is properly installed"
        case .audioFileNotFound:
            return "Audio file not found"
        }
    }
}
