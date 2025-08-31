#!/bin/bash

# Script to add bundled resources to Xcode project
echo "Adding bundled resources to Xcode project..."

# Check if Resources directory exists
if [ ! -d "Resources" ]; then
    echo "Error: Resources directory not found!"
    echo "Please run this script from the FavoriteTranscriber directory"
    exit 1
fi

# Check if FFmpeg exists
if [ ! -f "Resources/ffmpeg" ]; then
    echo "Error: FFmpeg binary not found in Resources directory!"
    echo "Please ensure ffmpeg is downloaded to Resources/ffmpeg"
    exit 1
fi

echo "✅ FFmpeg binary found: Resources/ffmpeg"
echo "📁 File size: $(ls -lh Resources/ffmpeg | awk '{print $5}')"

echo ""
echo "📋 Next steps:"
echo "1. In Xcode, right-click on your project in the navigator"
echo "2. Select 'Add Files to FavoriteTranscriber'"
echo "3. Navigate to and select the Resources/ffmpeg file"
echo "4. Make sure 'Add to target' is checked for FavoriteTranscriber"
echo "5. Click 'Add'"
echo ""
echo "After adding, the app will use the bundled FFmpeg instead of requiring system installation!"
