// +build mage

package main

import (
	"errors"
	"fmt"
	"os"

	"github.com/magefile/mage/target"

	"github.com/magefile/mage/mg"

	. "./mage"
)

// Default target to run when none is specified
// If not set, running mage will list available targets
// var Default = Build

var (
	xCodeBuild          = NewXCodeBuild()
	xCodeBuildWorkspace = NewXCodeBuildWithWorkspace(Workspace, Scheme)
)

// Install all the dependencies
func Bootstrap() {
	mg.Deps(InitEnvironment)
	Log("Bootstraping...")
	if IsCarthage() {
		Run("carthage bootstrap --no-use-binaries  --configuration Debug --cache-builds --platform", PlatformSelected)
	}
	if IsCocoapods() {
		Run("pod repo update")
		Run("pod install")
	}
}

//Update all the dependencies
func Update() {
	mg.Deps(InitEnvironment)
	Log("Updating...")
	if IsCarthage() {
		Run("carthage update --no-use-binaries  --configuration Debug --cache-builds --platform", PlatformSelected)
	}
	if IsCocoapods() {
		Run("pod update")
	}
}

//Install all the needed tools
func UpdateTools() {
	Log("Updating tools...")

	Run("brew update")
	Run("brew outdated carthage || brew upgrade carthage")

	Run("gem install cocoapods")

}

//Build an archive with xcodebuild archive
func Archive() {
	modified, err := target.Dir(PathArchive, PathSources)
	if !modified && err == nil {
		Log("Archive skipped")
		return
	}
	Log("Archiving...")
	xcw := xCodeBuildWorkspace
	xcw.Archive("iphoneos", PathArchive)
}

//Create the .ipa with xcodebuild -exportArchive
func ExportArchive() {
	Archive()
	modified, err := target.Dir(PathIpa, PathArchive)
	if !modified && err == nil {
		Log("Export skipped")
		return
	}
	Log("Exporting IPA...")
	xcb := xCodeBuild
	xcb.ExportArchive(PathArchive, PathExport, PathExportOptions)
}

//Upload IPA to TestFlight
func Testflight() {
	ExportArchive()
	Log("Uploading IPA to TestFlight...")
	applicationLoader := "/Applications/Xcode.app/Contents/Applications/Application\\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
	user, password := SetupItunes()
	Run(applicationLoader, "--upload-app -f", PathIpa, "-u", user, "-p", password)
}

// Clean XCode build folder
func Clean() {
	Log("Cleaning...")
	xcb := xCodeBuild
	xcb.Clean()
}

// Remove Xcode derived data folder
func RemoveDerivedData() {
	Run("rm -rf ~/Library/Developer/Xcode/DerivedData ~/Library/Caches/com.apple.dt.Xcode")
}

//#region CARTHAGE ONLY

// Build all dependencies --Carthage Only--
func BuildFramework() {
	mg.Deps(InitEnvironment)
	Clean()
	Bootstrap()
	Log("Building...")
	Run("carthage build --no-skip-current --cache-builds --platform %s", PlatformSelected)
}

// Archive framework --Carthage Only--
func ArchiveFramework() {
	Run("carthage archive", Name)
}

//#endregion

//#region COCOAPODS ONLY

// Lint podspec --Cocoapods Only--
func PodLint() {
	Clean()
	Run("pod lib lint --verbose --allow-warnings")
}

// Push pod to cocoapods trunk --Cocoapods Only--
func PodPush() {
	Run("pod trunk push")
}

//#endregion

func Release() {
	Log("Releasing...")
	tag := os.Getenv("tag")
	if tag == "" {
		Error(errors.New("Tag not defined"))
		return
	}
	if !IsGitTreeClean() {
		Error(errors.New("Please commit all your changes before running a release"))
		return
	}
	SetVersion(tag)
	UpdatePodspecVersion(tag)
	Run("git add .")
	Run(fmt.Sprintf("git commit -m 'Update project to version %s'", tag))
	Run("git tag", tag)
	Run("git push")
	Run("git push origin", tag)
}
