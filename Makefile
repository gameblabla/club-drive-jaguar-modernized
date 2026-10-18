PYTHON ?= python3
RETAIL ?=
SDK ?=
EMU ?= /bin/true

.PHONY: audio-check audio test rom audio-rom check-paths

check-paths:
	$(PYTHON) src/build/check_case_paths.py

audio-check:
	cd src && $(PYTHON) build/audio_portable.py check

audio:
	cd src && $(PYTHON) build/audio_portable.py compile

test: check-paths audio-check
	cd src && $(PYTHON) build/audio_roundtrip.py compile
	cd src && $(PYTHON) tests/test_audio_portable.py
	cd src && $(PYTHON) tests/test_audio_roundtrip.py

rom: check-paths
	@test -n "$(RETAIL)" || (echo 'Set RETAIL=/path/to/retail.zip' >&2; exit 2)
	@test -n "$(SDK)" || (echo 'Set SDK=/path/to/jaguar-sdk' >&2; exit 2)
	cd src && ./build.sh "$(shell realpath -- '$(RETAIL)')" "$(shell realpath -- '$(SDK)')" "$(EMU)" Club_Drive.j64

audio-rom: audio
	cd src && $(PYTHON) build/audio_portable.py patch-rom --reference Club_Drive.j64 --output Club_Drive_audio_test.j64
