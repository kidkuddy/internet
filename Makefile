APP_NAME = InternetTracker
PROJECT = $(APP_NAME).xcodeproj
BUILD_DIR = $(shell xcodebuild -project $(PROJECT) -scheme $(APP_NAME) -configuration Release -showBuildSettings 2>/dev/null | grep '^\s*BUILT_PRODUCTS_DIR' | head -1 | awk '{print $$3}')

.PHONY: build install run clean generate

generate:
	xcodegen generate

build:
	xcodebuild -project $(PROJECT) -scheme $(APP_NAME) -configuration Release build

install: build
	rm -rf /Applications/$(APP_NAME).app
	cp -r "$(BUILD_DIR)/$(APP_NAME).app" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

run: build
	open "$(BUILD_DIR)/$(APP_NAME).app"

clean:
	xcodebuild -project $(PROJECT) -scheme $(APP_NAME) clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*
