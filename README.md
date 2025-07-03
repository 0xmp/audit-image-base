# Audit Base Image

This repository contains a Dockerfile to build a base Ubuntu image pre-configured with essential development and system administration tools, a non-root user, and Oh-My-Zsh for an enhanced terminal experience.

## Dockerfile Highlights

The Dockerfile performs the following actions:

- Starts with the latest Ubuntu image.
- Installs common tools like `curl`, `wget`, `vim`, `neovim`, `git`, `zsh`, and more.
- Creates a non-root user `auditor`.
- Sets `zsh` as the default shell for the non-root user.
- Installs Oh-My-Zsh.
- Sets the default command to run `zsh`.

## Usage

You can pull this image using the following command:

```bash
docker pull ghcr.io/0xmp/audit-image-base:main
```

You can then run a container based on this image:

```bash
docker run -it ghcr.io/0xmp/audit-image-base:main
```
