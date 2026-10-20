# Club Drive

Club Drive source code for Atari Jaguar.
This is based upon leaked source code for it released a while back,
it was missing a few files so with the help of LLMs (ChatGPT etc...), the rest of the files
were recovered from a retail ROM so it could build

The assembly, source data, build scripts, and source comments are preserved where available. 
See `ASSET_ORIGINS.txt` for provenance and reproduction limitations.

You can compile it using the precompiled toolkit here :
[https://github.com/gameblabla/jaguar-sdk/releases/tag/1](https://github.com/gameblabla/jaguar-sdk/releases/tag/1)


## Source tree

```text
src/
├── assets/
│   ├── 3d/            ASC models, OBJ/MTL, native model authoring
│   ├── graphics/      Editable PNG sprites, artwork and UI
│   ├── sounds/        WAV effects and instruments
│   ├── music/         MIDI songs
│   ├── maps/          Arena, house and race-world files
│   ├── bsp/           Spatial partitions and native tree data
│   ├── native/        Original Jaguar-format inputs needed for exact builds
│   └── diagnostics/   GPU and collision test fixtures
├── build/             Asset tools, assemblers' build support
├── tests/             Conversion and validation tests
└── *.s, *.gas, *.inc  68000, GPU and DSP source
```

Uppercase and lowercase title-font glyphs use distinct filenames (e.g. let_upper_A.png and let_lower_a.png), and case-only file aliases have been removed.
No compiled graphic blobs are presented as editable PNG artwork. Packed Jaguar
resource inputs are kept under `assets/native/`; tools and tests live outside the
asset folders. Build tools read resources directly from `src/assets`; no legacy asset copies or
staging directories are created. Generated files are written to build outputs.

## Building

`src/build.sh` is the single cartridge build script. It runs the resource,
assembly, linking and verification stages without wrapper scripts or asset staging.


Requires Python 3, the Jaguar RMAC/Linux SDK, and a user-supplied retail ROM ZIP
for validation. No cartridge or SDK is included.

```sh
make test
make rom RETAIL=/path/to/retail.zip SDK=/path/to/jaguar-sdk
```

The clean cartridge output is `src/Club_Drive.j64` (2 MiB). It is compared with
the provided reference during the build.

Editable audio uses 42 mono WAV samples in `src/assets/sounds/wav` and seven
standard MIDI songs in `src/assets/music/midi`. To encode or check the audio:

```sh
make audio-check
make audio
```

The preview sample rate is not the Jaguar playback clock. Native FullSynth
voice patches and score structure remain authoritative; unsupported edits
are rejected instead of guessed.

Club Drive, Atari, Jaguar and their associated copyrights remain with their
respective owners.
