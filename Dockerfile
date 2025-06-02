FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    LANG=en_US.UTF-8 \
    HOME=/home/pokemmo

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
    wget https://pokemmo.com/download_file/1/ -O PokeMMO-Client.zip && \
    unzip PokeMMO-Client.zip && \
    rm -f PokeMMO-Client.zip && \
    chmod +x PokeMMO.sh && \
    mkdir -p /pokemmo/{config,roms,data/mods} && \
    chown -R pokemmo:pokemmo /pokemmo

# Copy ROM setup script
COPY scripts/setup-roms.sh /usr/local/bin/setup-roms
RUN chmod +x /usr/local/bin/setup-roms

# Create startup script
RUN echo '#!/bin/bash\n\
/usr/local/bin/setup-roms\n\
cd /pokemmo\n\
exec java -Xmx384M -Dfile.encoding="UTF-8" -Djava.awt.headless=false -cp PokeMMO.exe com.pokeemu.client.Client\n\
' > /usr/local/bin/start-pokemmo && \
    chmod +x /usr/local/bin/start-pokemmo

WORKDIR /pokemmo
USER pokemmo

CMD ["/usr/local/bin/start-pokemmo"]
