
.PHONY: install bootstrap


iOS_Scheme = "Nappa_iOS"
tvOS_Scheme = "Nappa_tvOS"
macOS_Scheme = "Nappa_macOS"
watchOS_Scheme = "Nappa_watchOS"

iPhone = "iPhone 7"
appleTV = "Apple TV 1080p"
appleWatch = "Apple Watch Series 3 - 42mm"

install:
	brew update
	brew install xcodegen

bootstrap:
	carthage bootstrap --no-use-binaries  --configuration Debug --cache-builds
	xcodegen

test_iOS:
	set -o pipefail && xcodebuild -scheme ${iOS_Scheme} \
		-destination 'OS=13.3,name=${iPhone}' \
		-destination 'OS=12.4,name=${iPhone}' \
		-destination 'OS=11.4,name=${iPhone}' \
		-destination 'OS=10.3,name=${iPhone}' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test_tvOS:
	set -o pipefail && xcodebuild -scheme ${tvOS_Scheme} \
		-destination 'OS=13.3,name=${appleTV}' \
		-destination 'OS=12.4,name=${appleTV}' \
		-destination 'OS=11.4,name=${appleTV}' \
		-destination 'OS=10.2,name=${appleTV}' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test_watchOS:
	set -o pipefail && xcodebuild -scheme ${watchOS_Scheme} \
		-destination 'OS=6.1,name=${appleWatch}' \
		-destination 'OS=5.3,name=${appleWatch}' \
		-destination 'OS=4.2,name=${appleWatch}' \
		-destination 'OS=3.2,name=${appleWatch}' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

test_macOS:
	set -o pipefail && xcodebuild -scheme ${macOS_Scheme} -destination 'arch=x86_64' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c
