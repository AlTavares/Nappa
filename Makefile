
.PHONY: install bootstrap

install:
	brew update
	brew install mint
	mint install yonaskolb/xcodegen
	mint install yonaskolb/beak

bootstrap:
	carthage bootstrap --no-use-binaries  --configuration Debug --cache-builds
	xcodegen
