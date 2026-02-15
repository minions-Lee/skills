#!/bin/bash
# Check if yt-dlp is installed and provide installation instructions if not

if command -v yt-dlp &> /dev/null; then
    echo "[video-downloader] yt-dlp is installed: $(yt-dlp --version)"
else
    echo "[video-downloader] yt-dlp is NOT installed."
    echo ""
    echo "Install using one of:"
    echo "  brew install yt-dlp       # macOS (recommended)"
    echo "  pip install yt-dlp        # Python"
    echo "  pipx install yt-dlp       # Isolated Python env"
    exit 1
fi
