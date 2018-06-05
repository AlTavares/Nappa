// +build mage

package main

import . "./mage"

// Default test, uses latest iOS environment
func Test() {
	test := NewXCodeBuildWithWorkspace(Workspace, SchemeIOS)
	test.Destination(DestinationForSimulator("11.3", "iPhone X")).
		Test("Debug")
}

func TestIOSDebug() {
	testIOS("Debug")
}

func TestIOSRelease() {
	testIOS("Release")
}

func testIOS(configuration string) {
	destinations := []Destination{
		DestinationForSimulator("11.3", "iPhone X"),
		DestinationForSimulator("10.3.1", "iPhone 7 Plus"),
		DestinationForSimulator("9.0", "iPhone 5s"),
	}
	test(SchemeIOS, destinations, configuration)
}

func TestMacOSDebug() {
	testMacOS("Debug")
}

func TestMacOSRelease() {
	testMacOS("Release")
}

func testMacOS(configuration string) {
	destinations := []Destination{DestinationForMac()}
	test(SchemeMacOS, destinations, configuration)
}

func TestTVOSDebug() {
	testTVOS("Debug")
}

func TestTVOSRelease() {
	testTVOS("Release")
}

func testTVOS(configuration string) {
	destinations := []Destination{
		DestinationForSimulator("11.3", "Apple TV 4K"),
		DestinationForSimulator("10.2", "Apple TV 1080p"),
		DestinationForSimulator("9.0", "Apple TV 1080p"),
	}
	test(SchemeTVOS, destinations, configuration)
}

func BuildWatchOSDebug() {
	buildWatchOS("Debug")
}

func BuildWatchOSRelease() {
	buildWatchOS("Release")
}

func buildWatchOS(configuration string) {
	destinations := []Destination{
		DestinationForSimulator("4.3", "Apple Watch Series 3 - 42mm"),
		DestinationForSimulator("3.2", "Apple Watch Series 2 - 42mm"),
		DestinationForSimulator("2.0", "Apple Watch - 38mm"),
	}
	xcw := NewXCodeBuildWithWorkspace(Workspace, SchemeWatchOS)
	for _, destination := range destinations {
		xcw.Destination(destination)
	}
	xcw.Build(configuration)
}

func test(scheme string, destinations []Destination, configuration string) {
	Clean()
	xcw := NewXCodeBuildWithWorkspace(Workspace, scheme)
	for _, destination := range destinations {
		xcw.Destination(destination)
	}
	xcw.Test(configuration)
}
