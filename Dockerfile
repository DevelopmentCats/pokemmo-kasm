FROM kasmweb/core-ubuntu-jammy:1.17.0
USER root

# Set X11 environment
ENV XDG_SESSION_TYPE=x11
ENV DISPLAY=:1
ENV DONT_PROMPT_WSL_INSTALL=1

# Install minimal required packages and X11 dependencies
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
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxcursor1 \
    libxinerama1 \
    libxxf86vm1 \
    libxkbfile1 \
    curl \
    openbox \
    xcompmgr \
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

# Create custom startup integration with proper X11 setup
RUN echo '#!/usr/bin/env bash\n\
set -ex\n\
echo "Starting PokeMMO launcher..."\n\
\n\
# Wait for desktop to be ready\n\
if [ -f /dockerstartup/vnc_startup.sh ]; then\n\
    echo "Waiting for VNC startup..."\n\
    sleep 2\n\
fi\n\
\n\
# Ensure display is set\n\
export DISPLAY=${DISPLAY:-:1}\n\
export XDG_SESSION_TYPE=x11\n\
\n\
# Start window manager if not running\n\
if ! pgrep -x "openbox" > /dev/null; then\n\
    echo "Starting openbox window manager..."\n\
    openbox &\n\
    sleep 1\n\
fi\n\
\n\
# Start compositor for better X11 compatibility\n\
if ! pgrep -x "xcompmgr" > /dev/null; then\n\
    echo "Starting xcompmgr compositor..."\n\
    xcompmgr -n &\n\
    sleep 1\n\
fi\n\
\n\
START_COMMAND="cd /pokemmo && ./PokeMMO.sh --fullscreen"\n\
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
            if [ "${MAXIMIZE}" == "true" ] && [ -f "${MAXIMIZE_SCRIPT}" ]; then\n\
                bash ${MAXIMIZE_SCRIPT}\n\
            fi\n\
            echo "Launching PokeMMO..."\n\
            eval $START_COMMAND $ARGS\n\
            ;;\n\
        -a|--assign)\n\
            echo "Assign mode"\n\
            ;;\n\
        -u|--url)\n\
            shift\n\
            ;;\n\
    esac\n\
    shift\n\
done\n\
\n\
# Start if no arguments are provided\n\
if [[ $# -eq 1 ]]; then\n\
    echo "Default launch of PokeMMO..."\n\
    eval $START_COMMAND $ARGS\n\
fi\n\
' > $STARTUPDIR/custom_startup.sh && \
    chmod +x $STARTUPDIR/custom_startup.sh

# Create desktop entry for PokeMMO
RUN mkdir -p /usr/share/applications && \
    echo '[Desktop Entry]\n\
Type=Application\n\
Name=PokeMMO\n\
Comment=Pokemon MMO Game\n\
Exec=/pokemmo/PokeMMO.sh\n\
Icon=/pokemmo/PokeMMO.png\n\
Terminal=false\n\
Categories=Game;\n\
' > /usr/share/applications/pokemmo.desktop && \
    chmod 644 /usr/share/applications/pokemmo.desktop

# Add OpenContainers labels
LABEL org.opencontainers.image.source=https://github.com/developmentcats/pokemmo-kasm
LABEL org.opencontainers.image.description="PokeMMO client as KASM workspace"
LABEL org.opencontainers.image.licenses=MIT

# Environment variables for KASM
ENV KASM_STARTUP_SCRIPT="/dockerstartup/custom_startup.sh"
ENV STARTUP_SCRIPT="/dockerstartup/custom_startup.sh"
ENV VNC_PORT=6901
ENV VNC_RESOLUTION=1280x1024
ENV MAX_FRAME_RATE=24
ENV VNCOPTIONS="-PreferBandwidth -DynamicQualityMin=4 -DynamicQualityMax=7"

WORKDIR /pokemmo
USER 1000
