# One entry point for people and CI. `make help` lists every command.
SHELL := /bin/bash
ROOT := $(shell pwd)
IOS_PKG := ios/NewsKit
IOS_ARTIFACTS := $(ROOT)/artifacts/ios
IOS_GOLDENS := ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__
# Keep the Mac awake during long runs: a sleeping laptop turns green runs into wall-clock timeouts (STRATEGY §6).
AWAKE := $(shell command -v caffeinate >/dev/null 2>&1 && echo "caffeinate -i")
FIXTURE ?= feed_default

.PHONY: help ios-test ios-record ios-record-missing ios-ui-test ios-app ios-run lint-goldens gallery clean

help: ## List every command
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# --- Screenshot + logic tests (what CI runs on every pull request) ------------

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

ios-test: ## Compare every screenshot with its golden + run logic tests (diffs → artifacts/ios/diffs on failure)
	$(call ios_xcodebuild,never)

ios-ui-test: ## Tap through the real app on the simulator + Apple's accessibility audit (~5 min)
	cd ios && xcodegen generate --quiet
	@UDID=$$(scripts/ios-sim.sh) && $(AWAKE) xcodebuild test -project ios/NewsDemo.xcodeproj -scheme NewsDemo \
	  -destination "platform=iOS Simulator,id=$$UDID" -derivedDataPath ios/DerivedData -quiet

lint-goldens: ## Fail on blank or unreadable goldens (a blank golden makes a test pass while protecting nothing)
	@swift scripts/lint-goldens.swift $(IOS_GOLDENS)

gallery: ## Every golden on one page (artifacts/gallery/index.html), for design review
	@swift scripts/gallery.swift $(IOS_GOLDENS) artifacts/gallery

# --- Updating goldens (only after an INTENDED visual change) -------------------

ios-record: ## Re-record ALL goldens from an empty folder (review git status before committing!)
	@# Start from an empty folder: goldens of deleted/renamed tests show up as deletions instead of lingering.
	@find $(IOS_GOLDENS) -name '*.png' -delete
	$(call ios_xcodebuild,all)

ios-record-missing: ## Record goldens only for NEW tests (existing ones are still compared)
	$(call ios_xcodebuild,missing)

# --- Running the app ------------------------------------------------------------

ios-app: ## Generate the Xcode project and build the demo app for the pinned simulator
	cd ios && xcodegen generate --quiet
	@# Project-local build folder: ios-run always launches THIS build, never a stale one from Xcode's shared cache.
	@UDID=$$(scripts/ios-sim.sh) && xcodebuild build -project ios/NewsDemo.xcodeproj -scheme NewsDemo \
	  -destination "platform=iOS Simulator,id=$$UDID" -derivedDataPath ios/DerivedData -quiet

ios-run: ## Open the app: make ios-run [FIXTURE=…] [OFFLINE=1] [DROP_CONNECTION=1] [TAB=games|account] [SIGNED_IN=1]
	@OFFLINE=$(OFFLINE) DROP_CONNECTION=$(DROP_CONNECTION) TAB=$(TAB) SIGNED_IN=$(SIGNED_IN) scripts/ios-run.sh $(FIXTURE)

clean: ## Delete build output and artifacts (the next run rebuilds)
	rm -rf artifacts ios/NewsKit/.build ios/DerivedData
