.PHONY: install
install:
	brew update
	brew install xcodegen

.PHONY: bootstrap
bootstrap:
	xcodegen

.PHONY: test_iOS
test_iOS:
	set -o pipefail && xcodebuild -scheme Nappa_iOS \
		-destination 'OS=13.3,name=iPhone 11' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

.PHONY: test_tvOS
test_tvOS:
	set -o pipefail && xcodebuild -scheme Nappa_tvOS \
		-destination 'OS=13.3,name=Apple TV 4K' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

.PHONY: test_watchOS
test_watchOS:
	set -o pipefail && xcodebuild -scheme Nappa_watchOS \
		-destination 'OS=6.1.1,name=Apple Watch Series 5 - 44mm' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

.PHONY: test_macOS
test_macOS:
	set -o pipefail && xcodebuild -scheme Nappa_macOS -destination 'arch=x86_64' \
		-configuration Debug ONLY_ACTIVE_ARCH=NO ENABLE_TESTABILITY=YES test | xcpretty -c

.PHONY: test
test: test_iOS test_macOS test_tvOS test_watchOS

.PHONY: release
release:
	@test ${version} || ( echo ">> version is not set"; exit 1 )
	git commit -m "Set version to ${version}" || echo "No changes to commit"
	git tag -a ${version} -m "Release ${version}" -f
	git push || true
	git push origin ${version} -f