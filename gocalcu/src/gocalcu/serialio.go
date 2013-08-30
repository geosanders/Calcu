
package main

import "io"
import "os"
import "syscall"
import "github.com/tarm/goserial"


// type SerialDev struct {

// }

// func (s SerialDev) 


// return a Reader which can be used to read from the specified device,
// a null device returns a reader connected to the console (for testing)
func createSerialReader(devSpec string) (io.Reader, error) {

	// for an empty device name, use stdin
	if devSpec == "" {
		return os.NewFile(uintptr(syscall.Stdin), "/dev/stdin"), nil
	}

	c := &serial.Config{Name: devSpec, Baud: 115200}
	s, err := serial.OpenPort(c)
	return s, err
	// if err != nil {
	// 	panic(err.Error())
	// }

	// return s

}