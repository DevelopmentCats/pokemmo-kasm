FROM kasmweb/core-ubuntu-focal:1.17.0
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

# Set up PokeMMO
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
    chown -R 1000:1000 /pokemmo

# Create startup script
RUN echo '#!/bin/bash\n\
set -x\n\
echo "Changing to PokeMMO directory..."\n\
cd /pokemmo\n\
echo "Listing PokeMMO directory contents:"\n\
ls -la\n\
echo "Setting up ROMs..."\n\
/usr/local/bin/setup-roms\n\
echo "Starting PokeMMO client..."\n\
if [ -f "PokeMMO.sh" ]; then\n\
  exec ./PokeMMO.sh\n\
elif [ -f "PokeMMO.jar" ]; then\n\
  exec java -Xmx384M -Dfile.encoding="UTF-8" -Djava.awt.headless=false -jar PokeMMO.jar\n\
elif [ -f "PokeMMO.exe" ]; then\n\
  exec java -Xmx384M -Dfile.encoding="UTF-8" -Djava.awt.headless=false -jar PokeMMO.exe\n\
else\n\
  echo "ERROR: No PokeMMO executable found!"\n\
  echo "Root directory contents:"\n\
  ls -la\n\
  exit 1\n\
fi\n\
' > /usr/local/bin/start-pokemmo && \
    chmod +x /usr/local/bin/start-pokemmo

# Copy ROM setup script
COPY scripts/setup-roms.sh /usr/local/bin/setup-roms
RUN chmod +x /usr/local/bin/setup-roms

# Add OpenContainers labels
LABEL org.opencontainers.image.source=https://github.com/developmentcats/pokemmo-kasm
LABEL org.opencontainers.image.description="PokeMMO client as KASM workspace"
LABEL org.opencontainers.image.licenses=MIT

WORKDIR /pokemmo
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=/dockerstartup/install
ENV KASM_VNC_PATH=/usr/share/kasmvnc
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_PORT=6901
ENV VNC_RESOLUTION=1280x1024
ENV MAX_FRAME_RATE=24
ENV VNCOPTIONS="-PreferBandwidth -DynamicQualityMin=4 -DynamicQualityMax=7"

USER 1000

CMD ["/usr/local/bin/start-pokemmo"]
