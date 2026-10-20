# CapsJump. `make test` runs the unit tests; `make app` builds CapsJump.app signed
# ad hoc (every rebuild asks for the permissions again; releases are signed and keep them);
# `make install-local` puts that build in ~/Applications and the CLI in ~/.local/bin, and
# clears the previous build's permission entries so `capsjump setup` asks afresh. It
# refuses while the release sits in /Applications: the two share an app ID, so that reset
# takes the release's permissions too (BESIDE_RELEASE=1 goes ahead anyway).
# `make uninstall-local` removes the local build and its entries, to go back to the release.

APP := .build/bundle/CapsJump.app
APPS_DIR := $(HOME)/Applications
BIN_DIR := $(HOME)/.local/bin
RELEASE_APP := /Applications/CapsJump.app
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: help test app install-local uninstall-local beside-release clean

help:
	@echo "make test             run the unit tests"
	@echo "make app              build $(APP), signed ad hoc"
	@echo "make install-local    build, then install to $(APPS_DIR) and link the CLI into $(BIN_DIR)"
	@echo "make uninstall-local  remove that install and its permission entries"
	@echo "make clean            remove .build"

test:
	swift test

app:
	scripts/bundle.sh

# Runs before the build, so a refusal costs nothing.
beside-release:
	@if [ -d "$(RELEASE_APP)" ] && [ "$(APPS_DIR)" != "/Applications" ] && [ -z "$(BESIDE_RELEASE)" ]; then \
		echo "CapsJump is installed in /Applications. Your build would share its app ID, and so its one set of"; \
		echo "permissions, and installing resets them, so the release would lose Accessibility."; \
		echo "Move the release out of Applications first (or brew uninstall --cask capsjump), or run"; \
		echo "make install-local BESIDE_RELEASE=1 to go ahead anyway."; \
		exit 1; \
	fi

install-local: beside-release app
	@pkill -x CapsJump || true
	rm -rf "$(APPS_DIR)/CapsJump.app"
	mkdir -p "$(APPS_DIR)" "$(BIN_DIR)"
	ditto "$(APP)" "$(APPS_DIR)/CapsJump.app"
	"$(LSREGISTER)" -f "$(APPS_DIR)/CapsJump.app"
	@# The grants of the previous ad hoc build stay listed, switched on, and no longer apply.
	tccutil reset Accessibility ai.stigmer.capsjump
	tccutil reset AppleEvents ai.stigmer.capsjump
	ln -sf "$(APPS_DIR)/CapsJump.app/Contents/Helpers/capsjump" "$(BIN_DIR)/capsjump"
	@echo "installed $(APPS_DIR)/CapsJump.app; CLI at $(BIN_DIR)/capsjump"
	@echo "next: capsjump setup (a local build asks for its permissions again after every rebuild)"

uninstall-local:
	"$(APPS_DIR)/CapsJump.app/Contents/Helpers/capsjump" quit || true
	"$(LSREGISTER)" -u "$(APPS_DIR)/CapsJump.app" || true
	rm -rf "$(APPS_DIR)/CapsJump.app"
	rm -f "$(BIN_DIR)/capsjump"
	tccutil reset Accessibility ai.stigmer.capsjump
	tccutil reset AppleEvents ai.stigmer.capsjump
	@echo "removed $(APPS_DIR)/CapsJump.app and its permission entries"
	@echo "next: brew reinstall --cask capsjump (or move the release back to /Applications); it asks for Accessibility once"

clean:
	rm -rf .build
