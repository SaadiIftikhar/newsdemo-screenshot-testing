# One entry point for humans and CI. `make help` lists targets.
SHELL := /bin/bash
ROOT := $(shell pwd)
IOS_PKG := ios/NewsKit
IOS_ARTIFACTS := $(ROOT)/artifacts/ios
ANDROID_DIR := android
# Keep the Mac awake during long runs: a sleeping laptop turned green runs into wall-clock timeouts (STRATEGY §6).
AWAKE := $(shell command -v caffeinate >/dev/null 2>&1 && echo "caffeinate -i")

.PHONY: help gallery ios-test ios-record ios-record-missing ios-ui-test ios-app ios-run android-test android-record android-compare android-run lint-goldens clean

help:
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

# --- iOS ---------------------------------------------------------------------

define ios_xcodebuild
	@UDID=$$(scripts/ios-sim.sh) && rm -rf $(IOS_ARTIFACTS) && mkdir -p $(IOS_ARTIFACTS) && \
	cd $(IOS_PKG) && \
	TEST_RUNNER_SNAPSHOT_TESTING_RECORD=$(1) \
	TEST_RUNNER_SNAPSHOT_ARTIFACTS=$(IOS_ARTIFACTS)/failures \
	$(AWAKE) xcodebuild test -scheme NewsKit-Package -destination "platform=iOS Simulator,id=$$UDID" \
	  -resultBundlePath $(IOS_ARTIFACTS)/NewsKit.xcresult -quiet \
	  -skipPackagePluginValidation ; status=$$?; \
	cd $(ROOT) && scripts/ios-export-diffs.sh $(IOS_ARTIFACTS) ; exit $$status
endef

ios-test: ## Verify iOS snapshots against committed goldens (what CI runs)
	$(call ios_xcodebuild,never)

IOS_GOLDENS := ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__
ANDROID_GOLDENS := $(ANDROID_DIR)/app/src/test/screenshots

ios-record: ## Re-record ALL iOS goldens (review the git diff before committing!)
	@# Start from an empty folder: goldens of deleted/renamed tests show up as deletions instead of lingering.
	@find $(IOS_GOLDENS) -name '*.png' -delete
	$(call ios_xcodebuild,all)

ios-ui-test: ## Run iOS UI interaction tests (XCUITest) against the real app on the simulator
	cd ios && xcodegen generate --quiet
	@UDID=$$(scripts/ios-sim.sh) && $(AWAKE) xcodebuild test -project ios/NewsDemo.xcodeproj -scheme NewsDemo \
	  -destination "platform=iOS Simulator,id=$$UDID" -derivedDataPath ios/DerivedData -quiet

ios-record-missing: ## Record only goldens that don't exist yet (new tests)
	$(call ios_xcodebuild,missing)

ios-app: ## Generate the Xcode project and build the demo app for the pinned simulator
	cd ios && xcodegen generate --quiet
	@# Project-local build folder: ios-run always launches THIS build, never a stale one from Xcode's shared cache.
	@UDID=$$(scripts/ios-sim.sh) && xcodebuild build -project ios/NewsDemo.xcodeproj -scheme NewsDemo \
	  -destination "platform=iOS Simulator,id=$$UDID" -derivedDataPath ios/DerivedData -quiet

FIXTURE ?= feed_default

ios-run: ## Launch the iOS app: make ios-run [FIXTURE=...] [OFFLINE=1] [DROP_CONNECTION=1] [TAB=games|account] [SIGNED_IN=1]
	@OFFLINE=$(OFFLINE) DROP_CONNECTION=$(DROP_CONNECTION) TAB=$(TAB) SIGNED_IN=$(SIGNED_IN) scripts/ios-run.sh $(FIXTURE)

# --- Android -----------------------------------------------------------------

android-test: ## Verify Android (Roborazzi) snapshots against committed goldens
	@rm -rf $(ANDROID_DIR)/app/build/outputs/roborazzi artifacts/android   # stale diffs would mislead reviewers
	@cd $(ANDROID_DIR) && $(AWAKE) ./gradlew verifyRoborazziDebug --stacktrace; status=$$?; cd $(ROOT); \
	if ls $(ANDROID_DIR)/app/build/outputs/roborazzi/*_actual.png >/dev/null 2>&1; then \
	  if [ "$$(uname)" = Darwin ]; then \
	    swift scripts/diff-report.swift $(ANDROID_GOLDENS) $(ANDROID_DIR)/app/build/outputs/roborazzi artifacts/android/diffs; \
	  else echo "diff gallery needs macOS (CoreGraphics); on CI the android-diffs job builds it"; fi; \
	fi; exit $$status

android-record: ## Re-record ALL Android goldens
	@find $(ANDROID_GOLDENS) -name '*.png' -delete   # orphans of deleted/renamed tests show up as deletions
	cd $(ANDROID_DIR) && ./gradlew recordRoborazziDebug

android-compare: ## Produce _compare.png diff images without failing the build
	@rm -rf $(ANDROID_DIR)/app/build/outputs/roborazzi
	cd $(ANDROID_DIR) && ./gradlew compareRoborazziDebug

android-run: ## Launch the Android app (phone or emulator): same options as ios-run
	@OFFLINE=$(OFFLINE) DROP_CONNECTION=$(DROP_CONNECTION) TAB=$(TAB) SIGNED_IN=$(SIGNED_IN) scripts/android-run.sh $(FIXTURE)

gallery: ## iOS vs Android goldens side by side (artifacts/side-by-side/index.html) for cross-platform design review
	@swift scripts/side-by-side.swift $(IOS_GOLDENS) $(ANDROID_GOLDENS) artifacts/side-by-side

lint-goldens: ## Fail if any golden image is blank/uniform (a blank golden makes a test pass while protecting nothing)
	@swift scripts/lint-goldens.swift ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__ $(ANDROID_DIR)/app/src/test/screenshots

clean:
	rm -rf artifacts ios/NewsKit/.build ios/DerivedData $(ANDROID_DIR)/build $(ANDROID_DIR)/app/build
