# PokeMMO Docker Container

A lightweight Docker container for running PokeMMO as an X11 application. This container provides a minimal, secure environment for running PokeMMO with all necessary dependencies.

## Features

- Minimal Ubuntu-based container
- X11 application support
- Automatic ROM management
- Secure non-root user execution
- Persistent game configuration
- Optimized for performance
- Automated builds with version tracking

## Required ROMs

The following ROMs are required and will be automatically downloaded:
- Pokemon Black (NDS)
- Pokemon Emerald (GBA)
- Pokemon FireRed (GBA)
- Pokemon HeartGold (NDS)
- Pokemon Platinum (NDS)

## Quick Start

1. Pull the latest image:
```bash
docker pull forge.dualriver.com/cat/pokemmo-docker:latest
```

2. Run the container:
```bash
docker run -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.Xauthority:/home/pokemmo/.Xauthority:ro \
    --device /dev/snd \
    --name pokemmo \
    forge.dualriver.com/cat/pokemmo-docker:latest
```

## Persistent Storage

Mount these volumes to persist data between container restarts:

```bash
-v ./config:/pokemmo/config \
-v ./roms:/pokemmo/roms \
-v ./mods:/pokemmo/data/mods
```

## Automated Updates

This container is automatically updated through GitHub Actions:
- Daily checks for new PokeMMO versions
- Automatic builds on code changes
- Version-tagged images
- Latest tag always points to most recent build

## Security

- Runs as non-root user 'pokemmo'
- Minimal container footprint
- Read-only ROM access
- Secure X11 forwarding

## License

This project is licensed under the MIT License.

## Legal Notice

ROMs are downloaded for educational purposes only. Please ensure you have the right to use these ROMs in your jurisdiction. 