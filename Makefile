SHELL := /bin/bash
PORT ?= 8080

.PHONY: help serve test test-ui deb icons clean

help:
	@echo "SwimSet targets:"
	@echo "  make serve     serve the app at http://localhost:$(PORT) (bound to 0.0.0.0)"
	@echo "  make test      run the logic test suite (Node, no dependencies)"
	@echo "  make test-ui   run the jsdom UI smoke test (npm install first)"
	@echo "  make deb       build build/swimset_<version>_all.deb"
	@echo "  make icons     regenerate PNG icons (needs Pillow)"
	@echo "  make clean     remove build output"

serve:
	python3 -m http.server $(PORT) --bind 0.0.0.0

test:
	node --test

test-ui:
	node --test tests/ui.test.js

deb:
	bash packaging/linux/build-deb.sh

icons:
	python3 tools/make-icons.py

clean:
	rm -rf build dist
