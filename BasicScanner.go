package main

import (
	"flag"
	"fmt"
	"net" // for synchronization
	"os"
	"sync"
	"time"
)

func main() {
	targetPtr := flag.String("target", "", "The target IP address to scan")
	flag.Parse()

	if *targetPtr == "" {
		fmt.Println("Error: No target specified.")
		fmt.Println("Usage: go run BasicScanner.go -target x.x.x.x")
		os.Exit(1)
	}

	target := *targetPtr
	var wg sync.WaitGroup

	fmt.Println("Scanning ports 1-100... ")

	for port := 1; port <= 100; port++ {
		wg.Add(1) // tell that we're adding one task

		go func(p int) { // launch background tasks
			defer wg.Done() //when this function ends

			address := fmt.Sprintf("%s:%d", target, p)
			conn, err := net.DialTimeout("tcp", address, time.Second)

			if err != nil {
				return // port closed or filtered
			}

			conn.Close()
			fmt.Printf("Port %d is OPEN\n", p)

		}(port)
	}

	wg.Wait() // bloche here count goes back to 0
	fmt.Println("Scan complete.")
}
