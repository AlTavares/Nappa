
.PHONY: install bootstrap test test_iOS test_tvOS test_watchOS test_macOS


install:
	brew update
	brew install xcodegen

bootstrap:
	xcodegen

test_iOS:
	set -o pipefail && xcodebuild -scheme Nappa_iOS \
		-destination 'OS=13.3,name=iPhone 11' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test_tvOS:
	set -o pipefail && xcodebuild -scheme Nappa_tvOS \
		-destination 'OS=13.3,name=Apple TV 4K' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test_watchOS:
	set -o pipefail && xcodebuild -scheme Nappa_watchOS \
		-destination 'OS=6.1,name=Apple Watch Series 5 - 44mm' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test_macOS:
	set -o pipefail && xcodebuild -scheme Nappa_macOS -destination 'arch=x86_64' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test: test_iOS test_macOS test_tvOS test_watchOS