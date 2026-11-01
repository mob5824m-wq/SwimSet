SHELL := /bin/bash
PORT ?= 8080
VERSION ?= 2.0.0
NATIVE := native

.PHONY: help apk linux deb screens test-native serve test test-ui icons clean

help:
	@echo "SwimSet targets:"
	@echo "  make apk         build $(NATIVE)/build/app/outputs/flutter-apk/app-release.apk"
	@echo "  make linux       build the Linux desktop bundle with Flutter"
	@echo "  make deb         build $(NATIVE)/build/deb/swimset_$(VERSION)_amd64.deb"
	@echo "  make test-native run the Flutter unit and widget tests"
	@echo "  make screens     render the UI screenshots into $(NATIVE)/build/screens"
	@echo "  make serve       serve the legacy web build at http://localhost:$(PORT)"
	@echo "  make test        run the legacy web logic tests (Node)"
	@echo "  make test-ui     run the legacy jsdom UI test (npm install first)"
	@echo "  make icons       regenerate the legacy web icons (needs Pillow)"
	@echo "  make clean       remove build output"

# Native apps (Android/Chromebook and Debian). CI is the supported builder:
# these targets are for a machine with Flutter 3.24+ and the Linux toolchain.
apk:
	cd $(NATIVE) && flutter pub get && flutter build apk --release

linux:
	cd $(NATIVE) && flutter pub get && flutter build linux --release

deb: linux
	cd $(NATIVE) && bash tool/package_deb.sh $(VERSION)

test-native:
	cd $(NATIVE) && flutter test

screens:
	cd $(NATIVE) && flutter test test/screenshots_test.dart

# Legacy web build kept as the reference implementation of the practice maths.
serve:
	python3 -m http.server $(PORT) --bind 0.0.0.0

test:
	node --test

test-ui:
	node --test tests/ui.test.js

icons:
	python3 tools/make-icons.py

clean:
	rm -rf build dist $(NATIVE)/build
