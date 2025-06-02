FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    LANG=en_US.UTF-8 \
    HOME=/home/pokemmo

# Add OpenContainers labels
LABEL org.opencontainers.image.source=https://github.com/developmentcats/pokemmo-kasm
LABEL org.opencontainers.image.description="PokeMMO client as X11 application"
LABEL org.opencontainers.image.licenses=MIT

# Create non-root user
RUN groupadd -g 1000 pokemmo && \
    useradd -m -d /home/pokemmo -s /bin/bash -u 1000 -g pokemmo pokemmo

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
    && rm -rf /var/lib/apt/lists/*

# Set up PokeMMO
RUN mkdir -p /pokemmo && \
    cd /pokemmo && \
    echo "Downloading PokeMMO client..." && \
    wget -v https://pokemmo.com/download_file/1/ -O PokeMMO-Client.zip && \
    echo "Extracting client..." && \
    unzip -v PokeMMO-Client.zip && \
    rm -f PokeMMO-Client.zip && \
    echo "Setting up permissions..." && \
    chmod +x PokeMMO.sh && \
    echo "Contents of /pokemmo:" && \
    ls -la /pokemmo && \
    chown -R pokemmo:pokemmo /pokemmo

# Create startup script
RUN echo '#!/bin/bash\n\
set -x\n\
echo "Setting up ROMs..."\n\
/usr/local/bin/setup-roms\n\
echo "Changing to PokeMMO directory..."\n\
cd /pokemmo\n\
echo "Listing PokeMMO directory contents:"\n\
ls -la\n\
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

WORKDIR /pokemmo
USER pokemmo

CMD ["/usr/local/bin/start-pokemmo"]
