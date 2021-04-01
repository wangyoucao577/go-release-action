package main

import "fmt"

const notSet string = "not set"

// these information will be collected when build, by `-ldflags "-X main.gitCommit=06b8d24"`
var (
	buildTime = notSet
	gitCommit = notSet
	gitRef    = notSet
)

func printVersion() {
	fmt.Printf("Build Time: %s\n", buildTime)
	fmt.Printf("Git Commit: %s\n", gitCommit)
	fmt.Printf("Git Ref:    %s\n", gitRef)
}

func main() {
	fmt.Println("Hello Action!")
	printVersion()
}
