#!/bin/bash

# Exit immediately if a command fails
set -e

# Help manual if URL is missing
if [ -z "$1" ]; then
    echo "Usage: $0 <YOUTUBE_URL> [MINUTES]"
    echo "Example (Full Length):       $0 https://youtube.com..."
    echo "Example (First 15 minutes):  $0 https://youtube.com... 15"
    exit 1
fi

URL="$1"
MINUTES="$2"

# Dynamic output naming calculations
if [ -z "$MINUTES" ]; then
    echo "Processing full length audio stream..."
    OUTPUT_MP3="output_full_length.mp3"
    FFMPEG_CUT_ARGS=""
else
    echo "Processing first $MINUTES mins using live stream piping..."
    OUTPUT_MP3="output_${MINUTES}mins.mp3"

    # Convert target minutes cleanly to raw seconds
    TOTAL_SECONDS=$((MINUTES * 60))
    FFMPEG_CUT_ARGS="-t $TOTAL_SECONDS"
fi

# Fix 403 Forbidden: Pipe authentic streams natively to clear signature blocks
# This forces yt-dlp to own the download handshake while ffmpeg encodes on the fly
echo "Streaming audio and transcoding to pristine 320kbps MP3..."
yt-dlp -f "ba[ext=m4a]/ba" \
       --extractor-args "youtube:player-client=web_embedded,web" \
       -o - \
       "$URL" 2>/dev/null | ffmpeg -y -i pipe:0 $FFMPEG_CUT_ARGS -b:a 320k -vn -stats "$OUTPUT_MP3"

echo ""
echo "Done! Saved as $OUTPUT_MP3"
