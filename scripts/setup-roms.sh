#!/bin/bash

# Exit on any error and enable debug output
set -ex

echo "Creating required directories..."
# Create required directories if they don't exist
mkdir -p /pokemmo/{config,roms,data/mods}

# Required ROM files
ROM_FILES=(
    "pokemon_black.nds"
    "pokemon_emerald.gba"
    "pokemon_firered.gba"
    "pokemon_heartgold.nds"
    "pokemon_platinum.nds"
)

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
    # Attempt download with more verbose output
    if ! wget -v --timeout=30 "$ROMS_URL" -O /tmp/PokeMMO-Roms.zip; then
        echo "Failed to download ROMs from primary source"
        echo "wget exit code: $?"
        echo "Current directory contents:"
        ls -la
        echo "Temp directory contents:"
        ls -la /tmp
        exit 1
    fi
    
    echo "Download completed. Extracting ROMs..."
    echo "Contents of downloaded file:"
    unzip -l /tmp/PokeMMO-Roms.zip
    
    echo "Extracting to /pokemmo/roms/..."
    if ! unzip -j -v /tmp/PokeMMO-Roms.zip -d /pokemmo/roms/; then
        echo "Failed to extract ROMs"
        echo "unzip exit code: $?"
        echo "Current directory contents:"
        ls -la
        echo "/pokemmo/roms contents:"
        ls -la /pokemmo/roms/
        rm -f /tmp/PokeMMO-Roms.zip
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/PokeMMO-Roms.zip
    echo "ROMs extracted successfully"
    
    # Verify all required ROMs are present
    echo "Verifying extracted ROMs..."
    for rom in "${ROM_FILES[@]}"; do
        if [ ! -f "/pokemmo/roms/$rom" ]; then
            echo "ERROR: ROM $rom is still missing after download"
            echo "Contents of /pokemmo/roms:"
            ls -la /pokemmo/roms/
            exit 1
        fi
    done
fi

# Set proper permissions
echo "Setting permissions..."
find /pokemmo/roms -type f -name "*.nds" -o -name "*.gba" -exec chmod 644 {} +
chown -R pokemmo:pokemmo /pokemmo/{config,roms,data/mods}

echo "ROM setup completed successfully"
echo "Final contents of /pokemmo/roms:"
ls -la /pokemmo/roms/ 