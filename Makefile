# One entry point for humans and CI. `make help` lists targets.
SHELL := /bin/bash
ROOT := $(shell pwd)
IOS_PKG := ios/NewsKit
IOS_ARTIFACTS := $(ROOT)/artifacts/ios
ANDROID_DIR := android

.PHONY: help ios-test ios-record ios-record-missing ios-app ios-run android-test android-record android-compare android-run lint-goldens clean

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

FIXTURE ?= feed_default

ios-run: ## Launch the iOS app on the simulator: make ios-run [FIXTURE=...] [OFFLINE=1] [TAB=games|account] [SIGNED_IN=1]
	@OFFLINE=$(OFFLINE) TAB=$(TAB) SIGNED_IN=$(SIGNED_IN) scripts/ios-run.sh $(FIXTURE)

# --- Android -----------------------------------------------------------------

android-test: ## Verify Android (Roborazzi) snapshots against committed goldens
	@rm -rf $(ANDROID_DIR)/app/build/outputs/roborazzi   # stale _compare.png files would mislead reviewers
	cd $(ANDROID_DIR) && ./gradlew verifyRoborazziDebug --stacktrace

android-record: ## Re-record ALL Android goldens
	cd $(ANDROID_DIR) && ./gradlew recordRoborazziDebug

android-compare: ## Produce _compare.png diff images without failing the build
	@rm -rf $(ANDROID_DIR)/app/build/outputs/roborazzi
	cd $(ANDROID_DIR) && ./gradlew compareRoborazziDebug

android-run: ## Launch the Android app (phone or emulator): same options as ios-run
	@OFFLINE=$(OFFLINE) TAB=$(TAB) SIGNED_IN=$(SIGNED_IN) scripts/android-run.sh $(FIXTURE)

lint-goldens: ## Fail if any golden image is blank/uniform (a blank golden makes a test pass while protecting nothing)
	@swift scripts/lint-goldens.swift ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__ $(ANDROID_DIR)/app/src/test/screenshots

clean:
	rm -rf artifacts ios/NewsKit/.build $(ANDROID_DIR)/build $(ANDROID_DIR)/app/build
