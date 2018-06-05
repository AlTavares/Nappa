package mage

import (
	"fmt"
	"os"
	"os/exec"
)

func IsCarthage() bool {
	return FileExists("Cartfile")
}

func IsCocoapods() bool {
	return FileExists("Podfile")
}

func FileExists(filename string) bool {
	_, err := os.Stat(filename)
	return !os.IsNotExist(err)
}

func SetupItunes() (user string, password string) {
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

func IsGitTreeClean() bool {
	cmd := exec.Command("git", "diff --quiet")
	return cmd.Run() == nil
}
