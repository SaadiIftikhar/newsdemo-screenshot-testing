# One entry point for humans and CI. `make help` lists targets.
SHELL := /bin/bash
ROOT := $(shell pwd)
IOS_PKG := ios/NewsKit
IOS_ARTIFACTS := $(ROOT)/artifacts/ios
ANDROID_DIR := android

.PHONY: help ios-test ios-record ios-record-missing ios-app android-test android-record android-compare clean

help:
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

# --- iOS ---------------------------------------------------------------------

define ios_xcodebuild
	@UDID=$$(scripts/ios-sim.sh) && rm -rf $(IOS_ARTIFACTS) && mkdir -p $(IOS_ARTIFACTS) && \
	cd $(IOS_PKG) && \
	TEST_RUNNER_SNAPSHOT_TESTING_RECORD=$(1) \
	TEST_RUNNER_SNAPSHOT_ARTIFACTS=$(IOS_ARTIFACTS)/failures \
	xcodebuild test -scheme NewsKit-Package -destination "platform=iOS Simulator,id=$$UDID" \
	  -resultBundlePath $(IOS_ARTIFACTS)/NewsKit.xcresult -quiet \
	  -skipPackagePluginValidation ; status=$$?; \
	cd $(ROOT) && scripts/ios-export-diffs.sh $(IOS_ARTIFACTS) ; exit $$status
endef

ios-test: ## Verify iOS snapshots against committed goldens (what CI runs)
	$(call ios_xcodebuild,never)

ios-record: ## Re-record ALL iOS goldens (review the git diff before committing!)
	$(call ios_xcodebuild,all)

ios-record-missing: ## Record only goldens that don't exist yet (new tests)
	$(call ios_xcodebuild,missing)

ios-app: ## Generate the Xcode project and build the demo app for the pinned simulator
	cd ios && xcodegen generate --quiet
	@UDID=$$(scripts/ios-sim.sh) && xcodebuild build -project ios/NewsDemo.xcodeproj -scheme NewsDemo \
	  -destination "platform=iOS Simulator,id=$$UDID" -quiet

# --- Android -----------------------------------------------------------------

android-test: ## Verify Android (Roborazzi) snapshots against committed goldens
	cd $(ANDROID_DIR) && ./gradlew verifyRoborazziDebug --stacktrace

android-record: ## Re-record ALL Android goldens
	cd $(ANDROID_DIR) && ./gradlew recordRoborazziDebug

android-compare: ## Produce _compare.png diff images without failing the build
	cd $(ANDROID_DIR) && ./gradlew compareRoborazziDebug

clean:
	rm -rf artifacts ios/NewsKit/.build $(ANDROID_DIR)/build $(ANDROID_DIR)/app/build
