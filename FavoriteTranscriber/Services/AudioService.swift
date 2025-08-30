import Foundation
import AVFoundation
import SwiftUI

@MainActor
class AudioService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var currentAudioFile: AudioFile?
    @Published var hasMicrophonePermission = false
    @Published var permissionStatus: String = "Not checked"
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    override init() {
        super.init()
        // Don't check microphone permission on init to avoid crash
        // Will check when actually needed for recording
        permissionStatus = "Ready to check"
    }
    
    func startRecording() async {
        // First, check if we can access the microphone without triggering a crash
        permissionStatus = "Checking microphone access..."
        
        do {
            // Try to get the current permission status first
            let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            permissionStatus = "Current status: \(permissionStatusString(currentStatus))"
            
            switch currentStatus {
            case .authorized:
                hasMicrophonePermission = true
                permissionStatus = "Permission granted"
                
            case .notDetermined:
                permissionStatus = "Requesting permission..."
                // Request permission
                let granted = await AVCaptureDevice.requestAccess(for: .audio)
                hasMicrophonePermission = granted
                permissionStatus = granted ? "Permission granted" : "Permission denied"
                
                if !granted {
                    print("Microphone permission denied by user")
                    return
                }
                
            case .denied:
                hasMicrophonePermission = false
                permissionStatus = "Permission denied - check System Preferences"
                print("Microphone permission denied - user needs to enable in System Preferences")
                return
                
            case .restricted:
                hasMicrophonePermission = false
                permissionStatus = "Permission restricted"
                print("Microphone permission restricted")
                return
                
            @unknown default:
                hasMicrophonePermission = false
                permissionStatus = "Unknown permission status"
                print("Unknown microphone permission status")
                return
            }
            
            // Only proceed if we have permission
            guard hasMicrophonePermission else {
                print("Microphone permission not granted")
                return
            }
            
            // Now proceed with recording setup
            permissionStatus = "Setting up recording..."
            await setupRecording()
            
        } catch {
            permissionStatus = "Error: \(error.localizedDescription)"
            print("Error during permission check: \(error)")
        }
    }
    
    private func setupRecording() async {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingStartTime = Date()
            startRecordingTimer()
            
            currentAudioFile = AudioFile(url: audioFilename)
            permissionStatus = "Recording started"
            print("Recording started successfully")
        } catch {
            permissionStatus = "Recording failed: \(error.localizedDescription)"
            print("Failed to start recording: \(error)")
        }
    }
    
    private func permissionStatusString(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopRecordingTimer()
        
        if let audioFile = currentAudioFile {
            processAudioFile(audioFile)
        }
        permissionStatus = "Recording stopped"
        print("Recording stopped")
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
    }
    
    private func processAudioFile(_ audioFile: AudioFile) {
        let asset = AVURLAsset(url: audioFile.url)
        Task {
            do {
                let duration = try await asset.load(.duration).seconds
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioFile.url.path)[.size] as? Int64) ?? 0
                let processedAudioFile = AudioFile(url: audioFile.url, duration: duration, fileSize: fileSize, format: audioFile.format)
                await MainActor.run {
                    currentAudioFile = processedAudioFile
                    print("Audio file processed: \(processedAudioFile.name), duration: \(duration)s, size: \(fileSize) bytes")
                }
            } catch {
                print("Failed to load audio duration: \(error)")
                await MainActor.run {
                    currentAudioFile = audioFile // Still set the audio file even if we can't get duration
                }
            }
        }
    }
    
    func importAudioFile(from url: URL) {
        let audioFile = AudioFile(url: url)
        processAudioFile(audioFile)
        print("Audio file imported: \(audioFile.name)")
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                print("Recording finished successfully")
            } else {
                print("Recording finished with error")
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Recording encode error: \(error)")
            }
        }
    }
}
