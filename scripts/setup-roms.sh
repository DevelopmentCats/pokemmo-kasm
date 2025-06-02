#!/bin/bash

# Exit on any error
set -e

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
    
    # Attempt download
    if ! wget -q --timeout=30 "$ROMS_URL" -O /tmp/PokeMMO-Roms.zip; then
        echo "Failed to download ROMs from primary source"
        exit 1
    fi
    
    echo "Extracting ROMs..."
    if ! unzip -j -q /tmp/PokeMMO-Roms.zip -d /pokemmo/roms/; then
        echo "Failed to extract ROMs"
        rm -f /tmp/PokeMMO-Roms.zip
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/PokeMMO-Roms.zip
    echo "ROMs extracted successfully"
    
    # Verify all required ROMs are present
    for rom in "${ROM_FILES[@]}"; do
        if [ ! -f "/pokemmo/roms/$rom" ]; then
            echo "ERROR: ROM $rom is still missing after download"
            exit 1
        fi
    done
fi

# Set proper permissions
find /pokemmo/roms -type f -name "*.nds" -o -name "*.gba" -exec chmod 644 {} +
chown -R pokemmo:pokemmo /pokemmo/{config,roms,data/mods}

echo "ROM setup completed successfully" 