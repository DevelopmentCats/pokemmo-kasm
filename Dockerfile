FROM kasmweb/core-ubuntu-jammy:1.17.0
USER root

# Install minimal required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    openjdk-17-jre \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    mesa-utils \
    libegl1-mesa \
    libasound2 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g prettier

# Set up PokeMMO and download ROMs
RUN mkdir -p /pokemmo && \
    cd /pokemmo && \
    echo "Downloading PokeMMO client..." && \
    wget -v https://pokemmo.com/download_file/1/ -O PokeMMO-Client.zip && \
    echo "Extracting client..." && \
    unzip PokeMMO-Client.zip && \
    rm -f PokeMMO-Client.zip && \
    echo "Setting up permissions..." && \
    chmod +x PokeMMO.sh && \
    echo "Contents of /pokemmo:" && \
    ls -la /pokemmo && \
    mkdir -p /pokemmo/roms && \
    cd /pokemmo/roms && \
    echo "Downloading PokeMMO ROMs..." && \
    wget -v --timeout=30 "https://dir.chesher.xyz/Media/PokeMMO/PokeMMO-Roms.zip" -O PokeMMO-Roms.zip && \
    echo "Extracting ROMs..." && \
    unzip -j PokeMMO-Roms.zip && \
    rm -f PokeMMO-Roms.zip && \
    echo "Setting ROM permissions..." && \
    find /pokemmo/roms -type f -name "*.nds" -o -name "*.gba" -exec chmod 644 {} + && \
    chown -R 1000:1000 /pokemmo

# Create custom startup integration
RUN echo '#!/usr/bin/env bash\n\
set -ex\n\
START_COMMAND="cd /pokemmo && ./PokeMMO.sh"\n\
MAXIMIZE="false"\n\
MAXIMIZE_SCRIPT=$STARTUPDIR/maximize_window.sh\n\
DEFAULT_ARGS=""\n\
ARGS=${APP_ARGS:-$DEFAULT_ARGS}\n\
\n\
options=$(getopt -o gau: -l go,assign,url: -n "$0" -- "$@")\n\
eval set -- "$options"\n\
\n\
while [[ $1 != -- ]]; do\n\
    case $1 in\n\
        -g|--go)\n\
            if [ "${MAXIMIZE}" == "true" ]; then\n\
                bash ${MAXIMIZE_SCRIPT}\n\
            fi\n\
            eval $START_COMMAND $ARGS\n\
            ;;\n\
        -a|--assign)\n\
            ;;\n\
        -u|--url)\n\
            shift\n\
            ;;\n\
    esac\n\
    shift\n\
done\n\
\n\
# Start a bash shell if no arguments are provided\n\
if [[ $# -eq 1 ]]; then\n\
    eval $START_COMMAND $ARGS\n\
fi\n\
' > $STARTUPDIR/custom_startup.sh && \
    chmod +x $STARTUPDIR/custom_startup.sh

# Add OpenContainers labels
LABEL org.opencontainers.image.source=https://github.com/developmentcats/pokemmo-kasm
LABEL org.opencontainers.image.description="PokeMMO client as KASM workspace"
LABEL org.opencontainers.image.licenses=MIT

ENV KASM_STARTUP_SCRIPT="/dockerstartup/custom_startup.sh"
ENV STARTUP_SCRIPT="/dockerstartup/custom_startup.sh"
ENV DISPLAY=:1
ENV VNC_PORT=6901
ENV VNC_RESOLUTION=1280x1024
ENV MAX_FRAME_RATE=24
ENV VNCOPTIONS="-PreferBandwidth -DynamicQualityMin=4 -DynamicQualityMax=7"

USER 1000
