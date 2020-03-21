LATEST_IOS_SDK_VERSION = $(call latestVersion,iphonesimulator)
LATEST_TVOS_SDK_VERSION = $(call latestVersion,appletvsimulator)
LATEST_WATCHOS_SDK_VERSION = $(call latestVersion,watchsimulator)

define latestVersion
$(shell xcodebuild -showsdks | grep $(1) | cut -d ' ' -f 4)
endef

.PHONY: install
install:
	brew update
	brew install xcodegen

.PHONY: bootstrap
bootstrap:
	xcodegen

.PHONY: test_iOS
test_iOS: scheme = Nappa_iOS
test_iOS: destination = OS=$(LATEST_IOS_SDK_VERSION),name=iPhone 11
test_iOS: test

.PHONY: test_tvOS
test_tvOS: scheme = Nappa_tvOS
test_tvOS: destination = OS=$(LATEST_TVOS_SDK_VERSION),name=Apple TV 4K
test_tvOS: test

.PHONY: test_watchOS
test_watchOS: scheme = Nappa_watchOS
test_watchOS: destination = OS=$(LATEST_WATCHOS_SDK_VERSION),name=Apple Watch Series 5 - 44mm
test_watchOS: test

.PHONY: test_macOS
test_macOS: scheme = Nappa_macOS
test_macOS: destination = arch=x86_64
test_macOS: test

.PHONY: test_all
test_all: test_iOS test_macOS test_tvOS test_watchOS

.PHONY: test
test:
	set -o pipefail && xcodebuild -scheme $(scheme) \
		-destination '$(destination)' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

.PHONY: release
release:
	@test ${version} || ( echo ">> version is not set"; exit 1 )
	git commit -m "Set version to ${version}" || echo "No changes to commit"
	git tag -a ${version} -m "Release ${version}" -f
	git push || true
	git push origin ${version} -f