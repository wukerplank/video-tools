# video-tools

Two Ruby command-line utilities for transcoding video to HEVC/MP4.

- **`tomp4`** — Convert a single video file (or a folder of `.mkv` files) to HEVC-in-MP4. Uses `HandBrakeCLI` when available, falls back to `ffmpeg`.
- **`video-converter`** — Walk a directory, detect non-HEVC video files, run them through `tomp4`, validate the result (HEVC codec, sane filesize, valid duration), and replace originals in-place. Skips files that wouldn't shrink. Writes a JSON log.

## Prerequisites

- **Ruby >= 2.7** with `bundler` (ships with modern Ruby).
- **ffmpeg** on `PATH` (required).
- **HandBrakeCLI** on `PATH` (optional, used when present).

The installer detects all three and prints install hints for whatever is missing.

## Install

One-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/wukerplank/video-tools/main/install.sh | bash
```

Or clone and run:

```sh
git clone https://github.com/wukerplank/video-tools.git
cd video-tools
./install.sh
```

This places thin wrappers at `~/.local/bin/video-converter` and `~/.local/bin/tomp4`, and unpacks the Ruby payload + vendored gems under `~/.local/share/video-tools/`. Gems are installed into `vendor/bundle/` inside the share dir — nothing pollutes your system gem path.

Override the prefix with:

```sh
PREFIX=/opt/video-tools ./install.sh
```

If `~/.local/bin` isn't on your `PATH`, the installer prints the line to add to your shell rc file.

## Usage

```sh
tomp4                       # prints usage
video-converter --help
```

Common examples:

```sh
# Simulate (print the command without converting)
tomp4 -s movie.mkv

# Convert a single file, scale to 1080p, quality 22
tomp4 -w 1920 -q 22 movie.mkv

# Walk a folder, convert everything non-HEVC, replace in place
video-converter -r /Volumes/Media/Shows
```

## Uninstall

```sh
./uninstall.sh
```

Removes the wrappers and the share dir. Honors `PREFIX` the same way.

## Layout

```
video-tools/
├── install.sh
├── uninstall.sh
├── Gemfile
├── Gemfile.lock
├── libexec/
│   ├── video-converter
│   ├── tomp4
│   └── UserPresets.json   ← HandBrake preset
└── README.md
```
