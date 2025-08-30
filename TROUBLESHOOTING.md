# 🔧 Troubleshooting Guide

## 🎤 Audio Recording Issues

### **Problem: "Record Audio" button does nothing**

**Solution:**
1. **Check Microphone Permissions**: 
   - Go to System Preferences > Security & Privacy > Microphone
   - Make sure "Favorite Transcriber" is checked
   - If not listed, run the app first, then check again

2. **Grant Permission When Prompted**:
   - When you first click "Record Audio", macOS should prompt for microphone access
   - Click "Allow" when prompted

3. **Restart the App**:
   - Close the app completely
   - Reopen it and try recording again

### **Problem: Recording starts but no audio is captured**

**Solution:**
1. **Check Audio Input Source**:
   - Go to System Preferences > Sound > Input
   - Make sure your microphone is selected and the input level shows activity
   - Speak into the microphone to see if the level bar moves

2. **Check App Permissions**:
   - Go to System Preferences > Security & Privacy > Microphone
   - Ensure "Favorite Transcriber" has microphone access

## 📁 Audio File Import Issues

### **Problem: "Import Audio File" button does nothing**

**Solution:**
1. **Check File Format**:
   - Supported formats: MP3, M4A, WAV, MP4, MPEG, MPGA, WEBM
   - Make sure your audio file is in one of these formats

2. **Check File Size**:
   - Maximum file size: 25MB (OpenAI API limitation)
   - If your file is larger, consider compressing it

3. **Check File Permissions**:
   - Make sure the audio file isn't locked or read-only
   - Try copying the file to your Desktop first

## 🔑 API Key Issues

### **Problem: No "Transcribe Audio" button appears**

**Solution:**
1. **Enter OpenAI API Key**:
   - Click "Edit" in the API Key section at the top
   - Enter your valid OpenAI API key
   - Click "Save"
   - The status should show "Connected" with a green dot

2. **Check API Key Validity**:
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Verify your API key is active and has credits
   - Generate a new key if needed

## 🚨 Common Error Messages

### **"Microphone permission is required"**
- Grant microphone access in System Preferences
- Restart the app after granting permission

### **"No audio file selected"**
- Record audio or import an audio file first
- Wait for the audio file to finish processing

### **"Please enter your OpenAI API key"**
- Enter your API key in the header section
- Make sure it's saved and shows "Connected" status

### **"Audio file is too large"**
- Use a file under 25MB
- Compress your audio file if needed

## 🔍 Debug Steps

### **Step 1: Check Console Output**
1. Open Console app (Applications > Utilities > Console)
2. Filter by "Favorite Transcriber"
3. Look for error messages when you try to record/import

### **Step 2: Verify App State**
1. Check if the app shows "Connected" status for API key
2. Look for the "Current Audio File" section after importing
3. Verify the "Transcribe Audio" button appears

### **Step 3: Test Basic Functionality**
1. Try importing a small MP3 file first
2. Check if the file appears in the "Current Audio File" section
3. Verify the transcribe button becomes available

## 📱 System Requirements

- **macOS**: 12.0 or later
- **Microphone**: Built-in or external microphone
- **Internet**: Required for OpenAI API calls
- **Permissions**: Microphone access must be granted

## 🆘 Still Having Issues?

If you're still experiencing problems:

1. **Check the Console** for detailed error messages
2. **Verify your audio file** is in a supported format
3. **Ensure you have a valid OpenAI API key** with credits
4. **Try restarting the app** after granting permissions
5. **Check System Preferences** for microphone access

## 🔧 Technical Details

The app uses:
- **AVFoundation** for audio recording and playback
- **AVCaptureDevice** for microphone permission handling
- **OpenAI Whisper API** for transcription
- **UserDefaults** for storing API keys and transcriptions

All audio processing happens locally before sending to OpenAI, ensuring your privacy.
