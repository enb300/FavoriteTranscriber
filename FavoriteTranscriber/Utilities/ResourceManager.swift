import Foundation

class ResourceManager {
    static let shared = ResourceManager()
    
    private init() {}
    
    // MARK: - Bundled Binary Paths
    
    func getBundledFFmpegPath() -> String? {
        return Bundle.main.path(forResource: "ffmpeg", ofType: nil)
    }
    
    func getBundledWhisperPath() -> String? {
        return Bundle.main.path(forResource: "whisper", ofType: nil)
    }
    
    // MARK: - System Tool Detection
    
    func isFFmpegAvailable() -> Bool {
        // Check if FFmpeg is available in system PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func isWhisperAvailable() -> Bool {
        // Check if Whisper is available via Python
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", "import whisper; print('OK')"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func isCommandLineToolsAvailable() -> Bool {
        // Check if Command Line Tools are available
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--version"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // MARK: - Setup Instructions
    
    func getSetupInstructions() -> String {
        var instructions = "To enable local transcription, you need to install some tools:\n\n"
        
        if !isCommandLineToolsAvailable() {
            instructions += "1. Install Command Line Tools:\n"
            instructions += "   • Open Terminal and run: xcode-select --install\n"
            instructions += "   • Or download from: https://developer.apple.com/download/all/\n\n"
        }
        
        if !isFFmpegAvailable() {
            instructions += "2. Install FFmpeg:\n"
            instructions += "   • Install Homebrew: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n"
            instructions += "   • Run: brew install ffmpeg\n\n"
        }
        
        if !isWhisperAvailable() {
            instructions += "3. Install Whisper:\n"
            instructions += "   • Run: pip3 install openai-whisper\n\n"
        }
        
        instructions += "Alternatively, you can use the OpenAI API option for transcription without installing any tools."
        
        return instructions
    }
    
    func getRecommendedAction() -> String {
        if isFFmpegAvailable() && isWhisperAvailable() {
            return "Local transcription is ready to use!"
        } else if !isCommandLineToolsAvailable() {
            return "Command Line Tools need to be installed first"
        } else if !isFFmpegAvailable() {
            return "FFmpeg needs to be installed"
        } else if !isWhisperAvailable() {
            return "Whisper needs to be installed"
        } else {
            return "Unknown issue detected"
        }
    }
}
