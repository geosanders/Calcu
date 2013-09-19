
package main

import "io"
import "os"
import "syscall"
import "github.com/tarm/goserial"


// return a Reader which can be used to read from the specified device,
// a null device returns a reader connected to the console (for testing)
func createSerialReader(devSpec string, baud uint) (io.Reader, error) {

	// for an empty device name, use stdin
	if devSpec == "" {
		return os.NewFile(uintptr(syscall.Stdin), "/dev/stdin"), nil
	}

	c := &serial.Config{Name: devSpec, Baud: int(baud)}
	s, err := serial.OpenPort(c)
	return s, err

}