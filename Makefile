APP_NAME = InternetTracker
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

.PHONY: build install run clean

build:
	swift build -c release
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/

install: build
	rm -rf /Applications/$(APP_BUNDLE)
	cp -r $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_BUNDLE)"

run: build
	./$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
