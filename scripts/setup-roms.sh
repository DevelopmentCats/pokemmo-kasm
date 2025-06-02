#!/bin/bash

# Exit on any error and enable debug output
set -ex

echo "Creating required directories..."
# Create required directories if they don't exist
mkdir -p /pokemmo/{config,roms,data/mods}
chown -R pokemmo:pokemmo /pokemmo

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
    # Create temp directory owned by pokemmo user
    mkdir -p /tmp/pokemmo-roms
    chown pokemmo:pokemmo /tmp/pokemmo-roms
    
    # Download as pokemmo user
    cd /tmp/pokemmo-roms
    if ! sudo -u pokemmo wget -v --timeout=30 "$ROMS_URL" -O PokeMMO-Roms.zip; then
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
    unzip -l PokeMMO-Roms.zip
    
    echo "Extracting to /pokemmo/roms/..."
    if ! sudo -u pokemmo unzip -j -v PokeMMO-Roms.zip -d /pokemmo/roms/; then
        echo "Failed to extract ROMs"
        echo "unzip exit code: $?"
        echo "Current directory contents:"
        ls -la
        echo "/pokemmo/roms contents:"
        ls -la /pokemmo/roms/
        rm -f PokeMMO-Roms.zip
        exit 1
    fi
    
    # Clean up
    cd /
    rm -rf /tmp/pokemmo-roms
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