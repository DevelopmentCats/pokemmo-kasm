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

# Create wrapper script with Java optimizations
RUN echo '#!/bin/bash\n\
# Java 2D optimizations\n\
export _JAVA_OPTIONS="\n\
-Dsun.java2d.opengl=true\n\
-Dsun.java2d.pmoffscreen=false\n\
-Dsun.java2d.xrender=true\n\
-Dsun.java2d.d3d=false\n\
-Dawt.useSystemAAFontSettings=on\n\
-Dswing.aatext=true\n\
-Dsun.java2d.ddoffscreen=false\n\
-Dsun.java2d.ddscale=true\n\
-XX:+UseG1GC\n\
-XX:MaxGCPauseMillis=50\n\
-XX:G1HeapRegionSize=32m\n\
-Xms512m\n\
-Xmx2048m"\n\
\n\
# Launch original PokeMMO script\n\
exec ./PokeMMO.sh "$@"' > /pokemmo/pokemmo-optimized.sh && \
    chmod +x /pokemmo/pokemmo-optimized.sh

# Configure XFCE panel to auto-hide by default
RUN mkdir -p /etc/xdg/xfce4/panel && \
    echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<channel name="xfce4-panel" version="1.0">\n\
  <property name="configver" type="int" value="2"/>\n\
  <property name="panels" type="array">\n\
    <value type="int" value="1"/>\n\
    <property name="panel-1" type="empty">\n\
      <property name="position" type="string" value="p=6;x=640;y=0"/>\n\
      <property name="length" type="uint" value="100"/>\n\
      <property name="position-locked" type="bool" value="true"/>\n\
      <property name="size" type="uint" value="30"/>\n\
      <property name="autohide-behavior" type="uint" value="1"/>\n\
      <property name="enable-struts" type="bool" value="false"/>\n\
      <property name="plugin-ids" type="array">\n\
        <value type="int" value="1"/>\n\
        <value type="int" value="3"/>\n\
        <value type="int" value="15"/>\n\
        <value type="int" value="4"/>\n\
        <value type="int" value="5"/>\n\
        <value type="int" value="6"/>\n\
        <value type="int" value="2"/>\n\
      </property>\n\
    </property>\n\
  </property>\n\
  <property name="plugins" type="empty">\n\
    <property name="plugin-1" type="string" value="applicationsmenu"/>\n\
    <property name="plugin-2" type="string" value="actions"/>\n\
    <property name="plugin-3" type="string" value="tasklist"/>\n\
    <property name="plugin-15" type="string" value="separator">\n\
      <property name="expand" type="bool" value="true"/>\n\
      <property name="style" type="uint" value="0"/>\n\
    </property>\n\
    <property name="plugin-4" type="string" value="pager"/>\n\
    <property name="plugin-5" type="string" value="clock"/>\n\
    <property name="plugin-6" type="string" value="systray"/>\n\
  </property>\n\
</channel>' > /etc/xdg/xfce4/panel/default.xml

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
# Configure XFCE panel to auto-hide\n\
if command -v xfconf-query >/dev/null 2>&1; then\n\
    echo "Configuring XFCE panel to auto-hide..."\n\
    xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t int -s 1 || true\n\
    xfconf-query -c xfce4-panel -p /panels/panel-1/enable-struts -n -t bool -s false || true\n\
fi\n\
\n\
START_COMMAND="cd /pokemmo && ./pokemmo-optimized.sh"\n\
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
