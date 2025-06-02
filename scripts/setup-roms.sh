#!/bin/bash

# Exit on any error and enable debug output
set -ex

# Required ROM files
ROM_FILES=(
    "pokemon_black.nds"
    "pokemon_emerald.gba"
    "pokemon_firered.gba"
    "pokemon_heartgold.nds"
    "pokemon_platinum.nds"
)

# Ensure roms directory exists and has correct permissions
if [ ! -d "/pokemmo/roms" ]; then
    echo "Creating /pokemmo/roms directory..."
    mkdir -p /pokemmo/roms
    chown pokemmo:pokemmo /pokemmo/roms
fi

cd /pokemmo/roms || {
    echo "❌ Failed to change to /pokemmo/roms directory"
    exit 1
}

# Check if any ROM files are missing
ROMS_MISSING=false
for rom in "${ROM_FILES[@]}"; do
    if [ ! -f "/pokemmo/roms/$rom" ]; then
        ROMS_MISSING=true
        echo "Missing ROM: $rom"
    fi
done

# Download and extract ROMs if any are missing
if [ "$ROMS_MISSING" = true ]; then
    echo "Downloading PokeMMO ROMs..."
    
    # Primary download URL
    ROMS_URL="https://dir.chesher.xyz/Media/PokeMMO/PokeMMO-Roms.zip"
    
    echo "Attempting download from: $ROMS_URL"
    
    # Try the download with retries
    MAX_RETRIES=3
    RETRY_COUNT=0
    DOWNLOAD_SUCCESS=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if wget -v --timeout=30 "$ROMS_URL" -O PokeMMO-Roms.zip; then
            DOWNLOAD_SUCCESS=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            echo "Download attempt $RETRY_COUNT failed. Exit code: $?"
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "❌ Failed to download ROMs after $MAX_RETRIES attempts"
        echo "Please ensure the ROM files are available at the specified URL"
        echo "Current directory contents:"
        ls -la
        echo "You will need to manually add the following ROM files to the /pokemmo/roms directory:"
        printf '%s\n' "${ROM_FILES[@]}"
        exit 1
    fi
    
    echo "Download completed. Extracting ROMs..."
    echo "Contents of downloaded file:"
    unzip -l PokeMMO-Roms.zip || {
        echo "❌ Failed to list contents of zip file"
        rm -f PokeMMO-Roms.zip
        exit 1
    }
    
    echo "Extracting to /pokemmo/roms/..."
    if ! unzip -j PokeMMO-Roms.zip; then
        echo "❌ Failed to extract ROMs"
        echo "unzip exit code: $?"
        echo "Current directory contents:"
        ls -la
        rm -f PokeMMO-Roms.zip
        exit 1
    fi
    
    # Clean up
    rm -f PokeMMO-Roms.zip
    echo "ROMs extracted successfully"
    
    # Verify all required ROMs are present
    echo "Verifying extracted ROMs..."
    MISSING_AFTER_DOWNLOAD=false
    for rom in "${ROM_FILES[@]}"; do
        if [ ! -f "/pokemmo/roms/$rom" ]; then
            MISSING_AFTER_DOWNLOAD=true
            echo "❌ ROM $rom is still missing after download"
        fi
    done
    
    if [ "$MISSING_AFTER_DOWNLOAD" = true ]; then
        echo "❌ Some ROMs are missing after download"
        echo "Contents of /pokemmo/roms:"
        ls -la /pokemmo/roms/
        echo "Required ROMs:"
        printf '%s\n' "${ROM_FILES[@]}"
        exit 1
    fi
fi

# Set proper permissions
echo "Setting permissions..."
find /pokemmo/roms -type f -name "*.nds" -o -name "*.gba" -exec chmod 644 {} +
chown -R pokemmo:pokemmo /pokemmo/roms

echo "ROM setup completed successfully"
echo "Final contents of /pokemmo/roms:"
ls -la /pokemmo/roms/ 