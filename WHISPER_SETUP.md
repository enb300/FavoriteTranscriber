# 🎯 Whisper Local Installation Guide

This app now uses **local Whisper** instead of the OpenAI API - it's completely free and works offline!

## 🚀 Quick Installation

### 1. Install Homebrew (if you don't have it)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install FFmpeg
```bash
brew install ffmpeg
```

### 3. Install Python (if you don't have it)
Download from: https://www.python.org/downloads/
Or use Homebrew:
```bash
brew install python
```

### 4. Install Whisper
```bash
pip install -U openai-whisper
```

### 5. Install Rust (if needed)
```bash
pip install setuptools-rust
```

## 🧪 Test Installation

Create a test script `whisper.py` in your home directory:

```python
import whisper

model = whisper.load_model("base")

# Test with a short audio file
audio = whisper.load_audio("test.mp3")
audio = whisper.pad_or_trim(audio)

# Make log-Mel spectrogram
mel = whisper.log_mel_spectrogram(audio).to(model.device)

# Detect language
_, probs = model.detect_language(mel)
print(f"Detected language: {max(probs, key=probs.get)}")

# Decode audio
options = whisper.DecodingOptions()
result = whisper.decode(model, mel, options)

print(result.text)
```

## 📱 How to Use

1. **Launch the app** - it will automatically use local Whisper
2. **Record audio** or **import audio files** (.mp3, .wav, .m4a, .webm)
3. **Click "Transcribe Audio"** - no API key needed!
4. **Wait for processing** - the first time will download the model (~150MB)

## 🔧 Troubleshooting

### "Command not found: whisper"
- Make sure you installed Whisper with `pip install -U openai-whisper`
- Try restarting your terminal

### "FFmpeg not found"
- Install FFmpeg: `brew install ffmpeg`
- Restart your terminal

### "Model download failed"
- Check your internet connection
- The base model is ~150MB, larger models are available

## 📊 Model Options

You can change the model size in `LocalWhisperService.swift`:

- **tiny**: Fastest, least accurate (~39MB)
- **base**: Good balance (~150MB) ← **Default**
- **small**: Better accuracy (~500MB)
- **medium**: High accuracy (~1.5GB)
- **large**: Best accuracy (~3GB)

## 🎵 Supported Audio Formats

- MP3, MP4, WAV, M4A, WebM
- Up to 25MB files (configurable)
- Multiple languages (auto-detected)

## 💡 Tips

- **First run** will be slower as it downloads the model
- **CPU usage** increases with longer audio files
- **M1 Macs** work great with Whisper!
- **Offline transcription** - no internet needed after setup

## 🆘 Still Having Issues?

1. Check that Python 3.7+ is installed: `python3 --version`
2. Verify Whisper installation: `python3 -c "import whisper; print('OK')"`
3. Test FFmpeg: `ffmpeg -version`
4. Check Homebrew: `brew --version`

The app will show detailed error messages if something goes wrong during transcription.
