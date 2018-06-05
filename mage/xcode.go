package mage

import (
	"fmt"
	"strings"
)

type XCodeBuild struct {
	pretty bool
	args   []string
}

func NewXCodeBuild() XCodeBuild {
	xc := XCodeBuild{}
	xc.Pretty()
	return xc
}

func NewXCodeBuildWithWorkspace(workspace string, scheme string) XCodeBuild {
	xc := NewXCodeBuild()
	xc.Workspace(workspace).
		Scheme(scheme)
	return xc
}

func (xc XCodeBuild) Run() {
	Run(xc.BuildCommand())
}

func (xc XCodeBuild) BuildCommand() string {
	cmd := "xcodebuild " + strings.Join(xc.args, " ")
	if xc.pretty {
		cmd = fmt.Sprintf("set -o pipefail && %s | xcpretty -c", cmd)
	}
	return cmd
}

func (xc *XCodeBuild) Archive(sdk string, path string) {
	xc.AddKVArgument("-sdk", sdk).
		AddKVArgument("-archivePath", path).
		Configuration("Release").
		Action("archive").
		Run()
}

func (xc *XCodeBuild) ExportArchive(archivePath string, exportPath string, exportOptionsPath string) {
	xc.AddKVArgument("-archivePath", archivePath).
		AddKVArgument("-exportPath", exportPath).
		AddKVArgument("-exportOptionsPlist", exportOptionsPath).
		AddArgument("-allowProvisioningUpdates").
		Action("-exportArchive").
		Run()
}

//Build target
func (xc *XCodeBuild) Build(configuration string) {
	xc.Configuration(configuration).
		DisableOnlyActiveArch().
		Action("build").
		Run()
}

// test target
func (xc *XCodeBuild) Test(configuration string) {
	xc.Configuration(configuration).
		DisableOnlyActiveArch().
		EnableTestability().
		Action("test").
		Run()
}

func (xc *XCodeBuild) Clean() {
	xc.Action("clean").
		AllTargets().
		Run()
}

// builder

func (xc *XCodeBuild) Action(value string) *XCodeBuild {
	if value != "" {
		xc.AddArgument(value)
	}
	return xc
}

func (xc *XCodeBuild) Workspace(value string) *XCodeBuild {
	if value != "" {
		xc.AddKVArgument("-workspace", value)
	}
	return xc
}
func (xc *XCodeBuild) Scheme(value string) *XCodeBuild {
	if value != "" {
		xc.AddKVArgument("-scheme", value)
	}
	return xc
}
func (xc *XCodeBuild) Destination(value Destination) *XCodeBuild {
	xc.AddKVArgument("-destination", value.String())
	return xc
}
func (xc *XCodeBuild) Configuration(value string) *XCodeBuild {
	if value != "" {
		xc.AddKVArgument("-configuration", value)
	}
	return xc
}

func (xc *XCodeBuild) UseNewBuildSystem() *XCodeBuild {
	xc.AddArgument("-UseNewBuildSystem=YES")
	return xc
}
func (xc *XCodeBuild) EnableTestability() *XCodeBuild {
	xc.AddArgument("ENABLE_TESTABILITY=YES")
	return xc
}
func (xc *XCodeBuild) DisableOnlyActiveArch() *XCodeBuild {
	xc.AddArgument("ONLY_ACTIVE_ARCH=NO")
	return xc
}
func (xc *XCodeBuild) AllTargets() *XCodeBuild {
	xc.AddArgument("-alltargets")
	return xc
}

func (xc *XCodeBuild) Pretty() *XCodeBuild {
	xc.pretty = true
	return xc
}

func (xc *XCodeBuild) AddArgument(arg string) *XCodeBuild {
	xc.args = append(xc.args, arg)
	return xc
}

func (xc *XCodeBuild) AddKVArgument(key string, value string) *XCodeBuild {
	xc.AddArgument(key + " " + value)
	return xc
}
