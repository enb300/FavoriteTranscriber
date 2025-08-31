import Foundation
import SwiftUI

@MainActor
protocol WhisperServiceProtocol: ObservableObject {
    var isTranscribing: Bool { get }
    var currentStatus: String { get }
    var transcriptionProgress: Double { get }
    
    func transcribeAudioFile(_ audioFile: AudioFile) async throws -> Transcription
}
