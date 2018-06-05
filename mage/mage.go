package mage

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/fatih/color"
)

const arrow = "➜ "

var DryRun = false

func Run(command ...string) {
	c := strings.Join(command, " ")
	LogColor(color.FgHiGreen, c)
	if IsDryRun() {
		return
	}
	cmd := exec.Command("sh", "-c", c)
	cmd.Stdout = os.Stdout
	var errorBuffer bytes.Buffer
	cmd.Stderr = &errorBuffer
	err := cmd.Run()
	if err != nil {
		fmt.Println()
		LogColor(color.FgHiRed, "Error running the following command:")
		LogColor(color.FgHiGreen, "\t", c)
		rawError := strings.TrimSpace(errorBuffer.String())
		LogColor(color.FgHiRed, rawError)
		Check(err)
	}
}

func RunAt(path string, command ...string) {
	cmd := append([]string{"cd", path, "&&"}, command...)
	Run(cmd...)
}

func Check(e error) {
	if e != nil {
		Error(e)
	}
}

func InitEnvironment() {
	Log("Initializing environment...")
	platform := os.Getenv("platform")
	if platform != "" {
		PlatformSelected = platform
	}
}

func Log(a ...interface{}) {
	LogColor(color.FgHiCyan, a...)
}

func LogColor(c color.Attribute, a ...interface{}) {
	color.Set(c)
	msg := append([]interface{}{arrow}, a...)
	fmt.Println(msg...)
	color.Unset()
}

func Error(e error) {
	color.Set(color.FgHiRed)
	fmt.Print(arrow, " ")
	panic(color.HiRedString(e.Error()))
}

func IsDryRun() bool {
	return DryRun || strings.EqualFold(os.Getenv("dryrun"), "true")
}
