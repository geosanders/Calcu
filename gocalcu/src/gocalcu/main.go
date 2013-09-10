
package main

import "net/http"
// import "io"
import "math/rand"
import "time"
import "fmt"
import "strings"
import "strconv"
// import "bytes"
import "bufio"
import "code.google.com/p/go.net/websocket"
import "github.com/jessevdk/go-flags"
// import "github.com/tarm/goserial"
// import "encoding/hex"
import "encoding/json"


var opts struct {

	Verbose []bool `short:"v" long:"verbose" description:"Show verbose information"`

	Port uint `short:"p" long:"port" description:"Port number for server to listen on"`

	Interface string `short:"I" long:"interface" description:"Interface IP to listen on"`

	BaseDir string `short:"d" long:"basedir" description:"Base directory to serve files out of"`

	SerialDevice string `short:"s" long:"serial" description:"Specifies the serial device to communicate with. If unspecified, read from the console.  (Mac example: /dev/tty.usbserial-A900YUBL, Windows example: COM1"`

	SerialBaud uint `short:"b" long:"baud" description:"Specifies the baud rate (speed) at which to communicate with the serial port."`

}

func main() {



	/////////////////////////////////
	// defaults
	opts.Port = 5565
	opts.Interface = ""
	opts.BaseDir = "../"
	opts.SerialDevice = ""
	opts.SerialBaud = 9600


	parser := flags.NewParser(&opts, flags.Default)

	args, err := parser.Parse()

	// args, err := flags.Parse()
	if err != nil {
		if _, ok := err.(*flags.Error); ok {
			// no error, this is the help screen
			return
		} else {
			// ... deal with non-flags.Error case, if that's possible.
			panic("Error parsing args: " + err.Error())
		}
	}

	if len(args) > 0 {
		panic("No idea what to do with extra args on the command line...")
	}

	// a channel for the events we read from the serial port
	event_channel := make(chan string)


	// run IO separately
	go func() {


		s, err := createSerialReader(opts.SerialDevice, opts.SerialBaud)
		if err != nil {
			panic(err.Error())
		}

		if len(opts.Verbose) > 0 {
			fmt.Printf("Starting to listen for serial IO...\n")
		}

		scanner := bufio.NewScanner(s)

		// line := scanner.Text()
		for scanner.Scan() {
			line := scanner.Text()
			if len(opts.Verbose) > 0 {
				fmt.Printf("got line: %s\n", line)
			}
			line = "\"" + strings.TrimSpace(line) + "\""
			var v interface{}
			err2 := json.Unmarshal([]byte(line), &v)
			if err2 == nil {
				switch v.(type) {
					case string: {
						vs := v.(string)
						if len(opts.Verbose) > 0 {
							fmt.Printf("string value: %s\n", vs)
						}
						// push to channel
						event_channel <- vs
						break
					}
				}
			}
		}



	}()



	if len(opts.Verbose) > 0 {
		fmt.Printf("Starting Web Server...\n")
	}

	curRelay := int32(0)

	http.Handle("/", http.FileServer(http.Dir("../")))
	http.Handle("/serial-relay", websocket.Handler(func (ws *websocket.Conn) {

		thisRelay := rand.Int31n(999999999)+1 // make sure we don't get a zero
		curRelay = thisRelay

		// our own timeout channel that times out after one second
		timeout := make(chan bool, 1)
		go func() {
		    time.Sleep(1 * time.Second)
		    timeout <- true
		}()


		var outstr string
		for thisRelay == curRelay {
			select {
				// read next event
				case outstr = <- event_channel:
					// write it out to websocket
					_, err := ws.Write([]byte(outstr))
					if err != nil {
						// break out of for loop
						thisRelay = 0
					}
					break
				case <- timeout:
					break
			}
		}
	}))

	if len(opts.Verbose) > 0 {
		fmt.Printf("Running\n")
		myHost := "localhost"
		if len(opts.Interface) > 0 {
			myHost = opts.Interface
		}
		fmt.Printf("Browse to http://%s:%d to view calculator\n", myHost, opts.Port)
	}

	herr := http.ListenAndServe(opts.Interface + ":" + strconv.Itoa(int(opts.Port)), nil)
	if herr != nil {
		panic("ListenAndServe: " + herr.Error())
	}

}


