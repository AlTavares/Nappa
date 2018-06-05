package mage

import (
	"fmt"
	"io/ioutil"
	"regexp"
)

func SetVersion(version string) {
	Run("agvtool new-marketing-version", version)
}

func SetBuild(version string) {
	Run("agvtool new-version -all", version)
}

func IncrementBuildNumber() {
	Run("agvtool next-version -all")
}

func UpdatePodspecVersion(version string) {
	path := "../" + Name + ".podspec"
	var re = regexp.MustCompile(`version = '.*'`)
	input, err := ioutil.ReadFile(path)
	Check(err)
	newVersion := fmt.Sprintf("version = '%s'", version)
	output := re.ReplaceAllString(string(input), newVersion)
	err = ioutil.WriteFile(path, []byte(output), 0666)
	Check(err)
}
