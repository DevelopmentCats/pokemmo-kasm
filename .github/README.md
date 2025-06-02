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

The following ROMs are required and will be automatically downloaded during first launch:
- Pokemon Black (NDS)
- Pokemon Emerald (GBA)
- Pokemon FireRed (GBA)
- Pokemon HeartGold (NDS)
- Pokemon Platinum (NDS)

## Quick Start

1. Pull the latest image:
```bash
docker pull ghcr.io/developmentcats/pokemmo-kasm:latest
```

You can also use a specific version by replacing `latest` with a version number:
```bash
docker pull ghcr.io/developmentcats/pokemmo-kasm:28887  # Replace with actual version
```

2. Run the container:
```bash
docker run -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.Xauthority:/home/pokemmo/.Xauthority:ro \
    --device /dev/snd \
    --name pokemmo \
    ghcr.io/developmentcats/pokemmo-kasm:latest
```

## Persistent Storage

Mount these volumes to persist data between container restarts:

```bash
docker run -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.Xauthority:/home/pokemmo/.Xauthority:ro \
    -v ./config:/pokemmo/config \
    -v ./roms:/pokemmo/roms \
    -v ./mods:/pokemmo/data/mods \
    --device /dev/snd \
    --name pokemmo \
    ghcr.io/developmentcats/pokemmo-kasm:latest
```

## Automated Updates

This container is automatically updated through GitHub Actions:
- Daily checks at 3 AM UTC for new PokeMMO versions
- Automatic builds when new PokeMMO versions are detected
- Version-tagged images matching PokeMMO version numbers
- Latest tag always points to most recent build
- Automated testing before any image is published

## Version Tags

The container follows PokeMMO's version numbering:
- `:latest` - Always points to the most recent version
- `:{version}` - Points to specific PokeMMO versions (e.g., `:28887`)

## Security

- Runs as non-root user 'pokemmo'
- Minimal container footprint
- Read-only ROM access
- Secure X11 forwarding
- Automated security scanning through GitHub Actions

## Container Registry

This image is hosted on GitHub Container Registry (ghcr.io) and is publicly available. You can:
- Pull without authentication
- View container details at: https://github.com/developmentcats/pokemmo-kasm/pkgs/container/pokemmo-kasm
- Use version tags for specific releases
- Track image history and changes
- View security scan results

## Troubleshooting

If you encounter X11 forwarding issues:
1. Ensure you have X11 running on your host
2. Check that the DISPLAY variable is set correctly
3. Verify .Xauthority permissions

For ROM-related issues:
1. Check the container logs: `docker logs pokemmo`
2. Verify ROM files in the mounted directory
3. Check file permissions if using persistent storage

## License

This project is licensed under the MIT License.

## Legal Notice

ROMs are downloaded for educational purposes only. Please ensure you have the right to use these ROMs in your jurisdiction. 