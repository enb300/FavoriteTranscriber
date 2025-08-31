import Foundation
import SwiftUI

@MainActor
class LocalWhisperService: ObservableObject, WhisperServiceProtocol {
    @Published var isTranscribing = false
    @Published var currentStatus = ""
    @Published var transcriptionProgress: Double = 0.0
    
    @Published var modelSize = "small" // Options: tiny, base, small, medium, large
    // small model provides better accuracy than base with reasonable speed
    
    // Model options with descriptions
    static let availableModels = [
        ("tiny", "Fastest, lowest accuracy (~32x realtime)"),
        ("base", "Fast, good for quick transcription (~16x realtime)"),
        ("small", "Balanced speed and accuracy (~6x realtime) - Recommended"),
        ("medium", "Better accuracy, slower (~2x realtime)"),
        ("large", "Best accuracy, slowest (~1x realtime)")
    ]
    
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
        _ = try await runWhisperCommand(audioFile: audioFile, outputDir: tempDir)
        
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
        // Try to find Python executable in various locations
        let possiblePythonPaths = [
            "/usr/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/opt/local/bin/python3"
        ]
        
        var pythonPath: String?
        for path in possiblePythonPaths {
            if FileManager.default.fileExists(atPath: path) {
                pythonPath = path
                break
            }
        }
        
        guard let executablePath = pythonPath else {
            throw LocalWhisperError.commandFailed(error: "Python3 not found. Please ensure Python 3 is installed.", output: "")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        
        // Arguments for the Whisper command with enhanced accuracy settings
        let args = [
            "-m", "whisper", // The whisper module
            audioFile.url.path, // Input audio file
            "--model", modelSize, // Model size (small for better accuracy)
            "--output_dir", outputDir.path, // Output directory
            "--output_format", "json", // JSON output format (most complete)
            "--language", "en", // Language (can be auto-detected by removing this)
            "--temperature", "0", // Lower temperature for more consistent results
            "--best_of", "5", // Try 5 different approaches and pick the best
            "--beam_size", "5", // Use beam search for better accuracy
            "--word_timestamps", "True", // Get word-level timestamps
            "--condition_on_previous_text", "True", // Use context from previous text
            "--compression_ratio_threshold", "2.4", // Filter out low-quality segments
            "--logprob_threshold", "-1.0", // Filter out uncertain words
            "--no_speech_threshold", "0.6" // Better silence detection
        ]
        
        process.arguments = args
        
        // Set environment to help find Python modules and FFmpeg
        var environment = ProcessInfo.processInfo.environment
        
        // Add Homebrew and other common paths to PATH
        let currentPath = environment["PATH"] ?? ""
        let additionalPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin", 
            "/usr/bin",
            "/bin"
        ]
        let newPath = (additionalPaths + currentPath.split(separator: ":").map(String.init)).joined(separator: ":")
        environment["PATH"] = newPath
        
        // Set Python path
        if let pythonPath = environment["PYTHONPATH"] {
            environment["PYTHONPATH"] = "\(pythonPath):/opt/homebrew/lib/python3.11/site-packages:/usr/local/lib/python3.11/site-packages"
        } else {
            environment["PYTHONPATH"] = "/opt/homebrew/lib/python3.11/site-packages:/usr/local/lib/python3.11/site-packages"
        }
        
        process.environment = environment
        
        print("DEBUG: Using Python path: \(executablePath)")
        print("DEBUG: Setting PATH to: \(newPath)")
        print("DEBUG: Audio file path: \(audioFile.url.path)")
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        currentStatus = "Running Whisper transcription..."
        transcriptionProgress = 0.5
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            print("Whisper command output: \(output)")
            print("Whisper command error: \(error)")
            
            if process.terminationStatus != 0 {
                throw LocalWhisperError.commandFailed(error: error, output: output)
            }
            
            return output
        } catch {
            let errorDescription = error.localizedDescription
            print("Process execution error: \(errorDescription)")
            throw LocalWhisperError.commandFailed(error: errorDescription, output: "")
        }
    }
    
    private func parseWhisperOutput(outputDir: URL, originalAudioFile: AudioFile) async throws -> Transcription {
        // Look for the JSON output file (should always exist with our output format)
        let baseFileName = originalAudioFile.url.deletingPathExtension().lastPathComponent
        let jsonFile = outputDir.appendingPathComponent("\(baseFileName).json")
        
        if FileManager.default.fileExists(atPath: jsonFile.path) {
            return try parseJSONOutput(jsonFile: jsonFile, originalAudioFile: originalAudioFile)
        }
        
        // If JSON doesn't exist, check for other formats with the base filename
        let txtFile = outputDir.appendingPathComponent("\(baseFileName).txt")
        if FileManager.default.fileExists(atPath: txtFile.path) {
            return try parseTextOutput(txtFile: txtFile, originalAudioFile: originalAudioFile)
        }
        
        throw LocalWhisperError.noOutputFilesFound
    }
    
    private func parseJSONOutput(jsonFile: URL, originalAudioFile: AudioFile) throws -> Transcription {
        let jsonData = try Data(contentsOf: jsonFile)
        let whisperResult = try JSONDecoder().decode(WhisperLocalResult.self, from: jsonData)
        
        return Transcription(
            audioFileId: originalAudioFile.id,
            text: whisperResult.text,
            language: whisperResult.language,
            confidence: whisperResult.confidence,
            processingTime: 0.0, // We could calculate this if needed
            modelUsed: modelSize,
            serviceType: "Local Whisper"
        )
    }
    
    private func parseTextOutput(txtFile: URL, originalAudioFile: AudioFile) throws -> Transcription {
        let text = try String(contentsOf: txtFile, encoding: .utf8)
        
        return Transcription(
            audioFileId: originalAudioFile.id,
            text: text,
            language: "en", // Default assumption
            confidence: 0.0, // Unknown for text output
            processingTime: 0.0,
            modelUsed: modelSize,
            serviceType: "Local Whisper"
        )
    }
}

// MARK: - Local Whisper Models

struct WhisperLocalResult: Codable {
    let text: String
    let language: String
    let segments: [WhisperSegment]?
    
    // Computed property to estimate confidence from segments
    var confidence: Double {
        guard let segments = segments, !segments.isEmpty else { return 0.0 }
        let totalConfidence = segments.compactMap { $0.avg_logprob }.reduce(0, +)
        return totalConfidence / Double(segments.count)
    }
}

struct WhisperSegment: Codable {
    let start: Double
    let end: Double
    let text: String
    let avg_logprob: Double?
}

enum LocalWhisperError: LocalizedError {
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
