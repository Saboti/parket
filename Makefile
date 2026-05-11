APP_NAME = parket
BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications/$(BUNDLE)
BUILD_DIR = .build/release
ICON_SOURCE = icon.png
ICON_FILE = AppIcon.icns
ICON_BUILD = .build/$(ICON_FILE)

.PHONY: build test check icon install clean dist benchmark

build:
	swift build --product parket -c release

icon:
	/bin/sh scripts/build_icon.sh $(ICON_SOURCE) $(ICON_BUILD)

test:
	swift build --product parket-tests
	.build/debug/parket-tests

check: test build

install: build icon
	@if [ ! -d "$(INSTALL_DIR)" ]; then \
		mkdir -p $(INSTALL_DIR)/Contents/MacOS $(INSTALL_DIR)/Contents/Resources; \
		cp Info.plist $(INSTALL_DIR)/Contents/; \
		echo "fresh install to $(INSTALL_DIR)"; \
		echo "grant accessibility permission in system settings, then: open /Applications/$(APP_NAME).app"; \
	fi
	mkdir -p $(INSTALL_DIR)/Contents/MacOS $(INSTALL_DIR)/Contents/Resources
	cp Info.plist $(INSTALL_DIR)/Contents/
	cp $(BUILD_DIR)/$(APP_NAME) $(INSTALL_DIR)/Contents/MacOS/
	cp $(ICON_BUILD) $(INSTALL_DIR)/Contents/Resources/$(ICON_FILE)
	codesign --force --sign - $(INSTALL_DIR)
	@echo "updated $(INSTALL_DIR)"

dist: build icon
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp Info.plist $(BUNDLE)/Contents/
	cp $(BUILD_DIR)/$(APP_NAME) $(BUNDLE)/Contents/MacOS/
	cp $(ICON_BUILD) $(BUNDLE)/Contents/Resources/$(ICON_FILE)
	codesign --force --sign - $(BUNDLE)
	zip -r $(APP_NAME).zip $(BUNDLE)
	@shasum -a 256 $(APP_NAME).zip

clean:
	swift package clean
	rm -rf $(BUNDLE) $(APP_NAME).zip .build/AppIcon.iconset .build/AppIcon-square.png $(ICON_BUILD)

benchmark:
	bash scripts/benchmark.sh run

uninstall:
	rm -rf $(INSTALL_DIR)
