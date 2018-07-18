// +build mage

package main

var (
	Name      = "Nappa"
	Workspace = Name + ".xcworkspace"
	Scheme    = Name

	SchemeIOS     = Name + "_iOS"
	SchemeMacOS   = Name + "_macOS"
	SchemeTVOS    = Name + "_tvOS"
	SchemeWatchOS = Name + "_watchOS"

	PlatformSelected = "all"

	PathSources       = "./Sources"
	PathExport        = "./build/"
	PathArchive       = PathExport + Name + ".xcarchive"
	PathExportOptions = PathExport + "ExportOptions.plist"
	PathIpa           = PathExport + Name + ".ipa"

	ITunesUser     = ""
	ITunesPassword = ""
)
