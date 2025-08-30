# Favorite Transcriber

A native macOS application that uses OpenAI's Whisper model to transcribe audio files with high accuracy and support for multiple languages, built following Apple's Human Interface Guidelines and OpenAI's best practices.

## ✨ Features

- **Audio Recording**: Built-in audio recording with real-time timer display
- **File Import**: Support for various audio formats (MP3, M4A, WAV, MP4, MPEG, MPGA, WEBM)
- **OpenAI Whisper Integration**: High-quality transcription using OpenAI's Whisper API
- **Multi-language Support**: Automatic language detection and transcription
- **Transcription History**: Save and manage your transcription history
- **Export Options**: Copy to clipboard or save transcriptions to text files
- **Native macOS UI**: Built with SwiftUI following Apple's Human Interface Guidelines
- **Advanced Error Handling**: Comprehensive error handling with retry logic
- **Rate Limiting**: Built-in rate limiting and retry mechanisms

## 🎨 Apple Design Guidelines Compliance

This app follows Apple's Human Interface Guidelines for macOS:

### **Visual Design**
- **SF Symbols**: Consistent use of Apple's system icons
- **Typography**: Proper font weights and sizes following Apple's type scale
- **Colors**: System colors that automatically adapt to light/dark mode
- **Spacing**: Consistent 8pt grid system for margins and padding
- **Corner Radius**: Standard 8-12pt corner radius for modern macOS look

### **Layout & Navigation**
- **Sidebar Design**: Left sidebar following macOS app conventions
- **Tab Navigation**: Standard segmented control for content switching
- **Toolbar Integration**: Proper toolbar placement and functionality
- **Window Sizing**: Appropriate minimum window dimensions (900x700)

### **Accessibility**
- **VoiceOver Support**: Proper accessibility labels and hints
- **Dynamic Type**: Support for user's preferred text size
- **High Contrast**: Automatic adaptation to accessibility settings
- **Keyboard Navigation**: Full keyboard accessibility

## 🤖 OpenAI Whisper Implementation

### **API Best Practices**
- **Rate Limiting**: 100ms minimum interval between requests
- **Retry Logic**: Automatic retry with exponential backoff for failures
- **Error Handling**: Comprehensive error categorization and user feedback
- **Timeout Management**: 5-minute timeout for long audio files
- **Response Processing**: Proper handling of verbose JSON responses

### **Audio Processing**
- **Format Validation**: Pre-upload format and size validation
- **Multipart Form Data**: Proper multipart form construction
- **Progress Tracking**: Real-time progress updates during transcription
- **Status Updates**: Detailed status messages for user feedback

### **Model Configuration**
- **Model Selection**: Uses latest `whisper-1` model
- **Temperature Control**: Set to 0.0 for deterministic results
- **Language Detection**: Optional language specification for accuracy
- **Response Format**: Verbose JSON for detailed segment information

## 🏗️ Architecture

### **MVVM Pattern**
```
Models/
├── AudioFile.swift          # Audio file data structure
└── Transcription.swift      # Transcription result model

Services/
├── AudioService.swift       # Audio recording and file handling
└── WhisperService.swift     # OpenAI API integration

ViewModels/
└── TranscriptionViewModel.swift  # Business logic and state management

Views/
├── ContentView.swift        # Main app interface
├── APIKeyHeaderView.swift   # API key management
├── AudioControlSidebar.swift    # Audio controls
└── TranscriptionContentView.swift # Transcription display
```

### **Key Design Patterns**
- **ObservableObject**: SwiftUI state management
- **Async/Await**: Modern concurrency for API calls
- **Protocol-Oriented**: Swift protocol extensions for shared functionality
- **Dependency Injection**: Service injection through ViewModels

## 📋 Requirements

- macOS 12.0 or later
- Xcode 14.0 or later
- OpenAI API key
- Internet connection for API calls

## 🚀 Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FavoriteTranscriber
   ```

2. **Open in Xcode**
   - Open `FavoriteTranscriber.xcodeproj` in Xcode
   - Ensure the target is set to macOS (not iOS)

3. **Get OpenAI API Key**
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create a new API key
   - Copy the key for use in the app

4. **Build and Run**
   - Select your target device (Mac)
   - Press Cmd+R to build and run

## 🔑 First Launch

1. Launch the app
2. Click "Edit" in the API Key section
3. Enter your OpenAI API key
4. Click "Save"
5. Status should show "Connected" with a green dot

## 📖 Usage

### **Recording Audio**
1. Click "Start Recording" to begin
2. Speak into your microphone
3. Click "Stop Recording" when finished
4. Click "Transcribe Audio" to process

### **Importing Audio Files**
1. Click "Import Audio File"
2. Select an audio file from your system
3. Click "Transcribe Audio" to process

### **Viewing Results**
- **Current Tab**: Shows the most recent transcription with options to copy or save
- **History Tab**: Displays all previous transcriptions with metadata

## 🔧 Technical Implementation

### **Audio Processing**
- **AVFoundation**: Native macOS audio framework
- **File Formats**: Support for industry-standard audio formats
- **Quality Settings**: High-quality recording settings (44.1kHz, AAC)
- **Error Handling**: Comprehensive audio error handling

### **Network Layer**
- **URLSession**: Modern networking with async/await
- **Multipart Forms**: Proper multipart form data construction
- **Headers**: Correct API authentication and content type headers
- **Timeout**: Appropriate timeout values for audio processing

### **Data Persistence**
- **UserDefaults**: Lightweight storage for settings and history
- **Codable**: Swift-native JSON encoding/decoding
- **Error Handling**: Graceful handling of corrupted data

## 🚨 Error Handling

### **Common Error Scenarios**
1. **API Key Issues**: Invalid or expired API keys
2. **Network Problems**: Connection timeouts and failures
3. **File Format Issues**: Unsupported audio formats
4. **Size Limitations**: Files exceeding 25MB limit
5. **Rate Limiting**: API rate limit exceeded

### **User Experience**
- **Clear Messages**: User-friendly error descriptions
- **Actionable Advice**: Specific steps to resolve issues
- **Retry Logic**: Automatic retry for transient failures
- **Progress Feedback**: Real-time status updates

## 🧪 Testing

### **Unit Testing**
- **ViewModels**: Business logic testing
- **Services**: API integration testing
- **Models**: Data structure validation

### **UI Testing**
- **User Flows**: Complete transcription workflows
- **Error Scenarios**: Error handling validation
- **Accessibility**: VoiceOver and keyboard navigation

### **Performance Testing**
- **Memory Usage**: Memory leak detection
- **Network Performance**: API call optimization
- **UI Responsiveness**: Smooth user interactions

## 🔒 Security & Privacy

### **Data Protection**
- **Local Storage**: All data stored locally on device
- **API Security**: Secure API key storage
- **Network Security**: HTTPS-only API communication
- **App Sandbox**: Proper macOS security entitlements

### **Privacy Features**
- **No Data Collection**: No user data sent to external services
- **Audio Processing**: Audio files processed locally before API calls
- **Transient Storage**: Temporary audio files automatically cleaned up

## 📱 Platform Considerations

### **macOS Specific Features**
- **App Sandbox**: Proper security entitlements
- **System Integration**: Native macOS appearance and behavior
- **Window Management**: Proper window sizing and positioning
- **Menu Integration**: Standard macOS menu structure

### **Accessibility Support**
- **VoiceOver**: Full screen reader support
- **Dynamic Type**: User preference text sizing
- **High Contrast**: Accessibility mode support
- **Keyboard Navigation**: Complete keyboard accessibility

## 🚀 Performance Optimization

### **Memory Management**
- **Weak References**: Proper memory management in closures
- **Lazy Loading**: On-demand resource loading
- **Image Caching**: Efficient icon and image handling

### **Network Optimization**
- **Request Batching**: Efficient API call management
- **Caching**: Local result caching
- **Compression**: Optimized audio file handling

## 🔮 Future Enhancements

- [ ] **Apple Pages Integration**: Direct document creation
- [ ] **Batch Processing**: Multiple file handling
- [ ] **Advanced Audio Editing**: Audio trimming and enhancement
- [ ] **Custom Models**: Fine-tuned transcription models
- [ ] **Real-time Streaming**: Live transcription capabilities
- [ ] **Cloud Sync**: iCloud integration for transcriptions
- [ ] **Export Formats**: Multiple export format support
- [ ] **Advanced Analytics**: Transcription quality metrics

## 📚 Resources

### **Apple Documentation**
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [AVFoundation Guide](https://developer.apple.com/documentation/avfoundation)
- [App Sandbox](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AboutAppSandbox/AboutAppSandbox.html)

### **OpenAI Documentation**
- [Whisper API Reference](https://platform.openai.com/docs/api-reference/audio)
- [Best Practices](https://platform.openai.com/docs/guides/rate-limits)
- [Error Handling](https://platform.openai.com/docs/guides/error-codes)

### **Development Resources**
- [Swift Style Guide](https://swift.org/documentation/api-design-guidelines/)
- [macOS Development](https://developer.apple.com/macos/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following Apple's guidelines
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
- Check the troubleshooting section above
- Review OpenAI's API documentation
- Open an issue on GitHub
- Consult Apple's developer documentation

---

**Built with ❤️ following Apple's Human Interface Guidelines and OpenAI's best practices**
