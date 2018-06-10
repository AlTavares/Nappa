// +build mage

package main

import (
	"errors"
	"fmt"
	"os"

	"github.com/AlTavares/go/xcodeproject"

	"github.com/AlTavares/go/logger"
	"github.com/AlTavares/go/sh"
	"github.com/AlTavares/go/xcode"

	"github.com/magefile/mage/target"

	"github.com/magefile/mage/mg"
)

// Default target to run when none is specified
// If not set, running mage will list available targets
// var Default = Build

var (
	xCodeBuild          = xcode.NewXCodeBuild()
	xCodeBuildWorkspace = xcode.NewXCodeBuildWithWorkspace(Workspace, Scheme)
)

func init() {
	Compile()
}

// Install all the dependencies
func Bootstrap() {
	mg.Deps(initEnvironment)
	logger.Log("Bootstraping...")
	if xcodeproject.IsCarthage() {
		sh.Run("carthage bootstrap --no-use-binaries  --configuration Debug --cache-builds --platform", PlatformSelected)
	}
	if xcodeproject.IsCocoapods() {
		sh.Run("pod repo update")
		sh.Run("pod install")
	}
}

//Update all the dependencies
func Update() {
	mg.Deps(initEnvironment)
	logger.Log("Updating...")
	if xcodeproject.IsCarthage() {
		sh.Run("carthage update --no-use-binaries  --configuration Debug --cache-builds --platform", PlatformSelected)
	}
	if xcodeproject.IsCocoapods() {
		sh.Run("pod update")
	}
}

//Install all the needed tools
func UpdateTools() {
	logger.Log("Updating tools...")

	sh.Run("brew update")
	sh.Run("brew outdated carthage || brew upgrade carthage")

	sh.Run("gem install cocoapods")

}

func initEnvironment() {
	logger.Log("Initializing environment...")
	platform := os.Getenv("platform")
	if platform != "" {
		PlatformSelected = platform
	}
}

//Build an archive with xcodebuild archive
func Archive() {
	modified, err := target.Dir(PathArchive, PathSources)
	if !modified && err == nil {
		logger.Log("Archive skipped")
		return
	}
	logger.Log("Archiving...")
	xcw := xCodeBuildWorkspace
	xcw.Archive("iphoneos", PathArchive)
}

//Create the .ipa with xcodebuild -exportArchive
func ExportArchive() {
	Archive()
	modified, err := target.Dir(PathIpa, PathArchive)
	if !modified && err == nil {
		logger.Log("Export skipped")
		return
	}
	logger.Log("Exporting IPA...")
	xcb := xCodeBuild
	xcb.ExportArchive(PathArchive, PathExport, PathExportOptions)
}

//Upload IPA to TestFlight
func Testflight() {
	ExportArchive()
	logger.Log("Uploading IPA to TestFlight...")
	applicationLoader := "/Applications/Xcode.app/Contents/Applications/Application\\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
	user, password := setupItunes()
	sh.Run(applicationLoader, "--upload-app -f", PathIpa, "-u", user, "-p", password)
}

// Clean XCode build folder
func Clean() {
	logger.Log("Cleaning...")
	xcb := xCodeBuild
	xcb.Clean()
}

// Remove Xcode derived data folder
func RemoveDerivedData() {
	sh.Run("rm -rf ~/Library/Developer/Xcode/DerivedData ~/Library/Caches/com.apple.dt.Xcode")
}

//#region CARTHAGE ONLY

// Build all dependencies --Carthage Only--
func BuildFramework() {
	mg.Deps(initEnvironment)
	Clean()
	Bootstrap()
	logger.Log("Building...")
	sh.Run("carthage build --no-skip-current --cache-builds --platform", PlatformSelected)
}

// Archive framework --Carthage Only--
func ArchiveFramework() {
	sh.Run("carthage archive", Name)
}

//#endregion

//#region COCOAPODS ONLY

// Lint podspec --Cocoapods Only--
func PodLint() {
	sh.Run("pod repo update")
	sh.Run("pod lib lint --verbose --allow-warnings")
}

// Push pod to cocoapods trunk --Cocoapods Only--
func PodPush() {
	sh.Run("pod trunk push")
}

//#endregion

func Release() {
	logger.Log("Releasing...")
	tag := os.Getenv("tag")
	if tag == "" {
		logger.Error(errors.New("Tag not defined"))
		return
	}
	if !xcodeproject.IsGitTreeClean() {
		logger.Error(errors.New("Please commit all your changes before running a release"))
		return
	}
	logger.Log("Setting version to", tag)
	xcodeproject.SetVersion(tag)
	logger.Log("Updating podspec")
	xcodeproject.UpdatePodspecVersion(Name+".podspec", tag)
	sh.Run(fmt.Sprintf("git commit -a -m 'Update project to version %s'", tag))
	sh.Run("git tag", tag)
	sh.Run("git push")
	sh.Run("git push origin", tag)
}

func Compile() {
	modified, err := target.Path("swiftmage", "magefile.go", "tests.go")
	if !modified && err == nil {
		return
	}
	logger.Log("Updating binary...")
	sh.Run("mage --clean")
	sh.Run("mage -compile swiftmage")
}

func setupItunes() (user string, password string) {
	user = os.Getenv("itunesUser")
	if user == "" {
		user = ITunesUser
		if user == "" {
			fmt.Println()
			fmt.Print("Type your iTunes username: ")
			fmt.Scanln(&user)
		}
	}
	password = os.Getenv("itunesPassword")
	if password == "" {
		password = ITunesPassword
		if password == "" {
			fmt.Println()
			fmt.Print("Password for " + user + ": ")
			fmt.Scanln(&password)
		}
	}
	return
}

func UpdateSelf() {
	update("magefile.go")
}

func UpdateTests() {
	update("tests.go")
}

func update(files ...string) {
	sh.Run("git clone https://github.com/AlTavares/Swift-Mage")
	for _, file := range files {
		sh.Run(fmt.Sprintf("cp Swift-Mage/%s .", file))
	}
	sh.Run("cp Swift-Mage/install.sh .")
	sh.Check(os.RemoveAll("Swift-Mage"))
	sh.Run("sh install.sh")
}
