
package main

import "net/http"
// import "io"
// import "math/rand"
// import "time"
import "fmt"
// import "strings"
import "strconv"
// import "bytes"
import "bufio"
import "code.google.com/p/go.net/websocket"
import "github.com/jessevdk/go-flags"
// import "github.com/tarm/goserial"
// import "encoding/hex"
// import "encoding/json"
// import "container/list"
import "sync"
// import "container/list"


var opts struct {

	Verbose []bool `short:"v" long:"verbose" description:"Show verbose information"`

	Port uint `short:"p" long:"port" description:"Port number for server to listen on"`

	Interface string `short:"I" long:"interface" description:"Interface IP to listen on"`

	BaseDir string `short:"d" long:"basedir" description:"Base directory to serve files out of"`

	SerialDevice string `short:"s" long:"serial" description:"Specifies the serial device to communicate with. If unspecified, read from the console.  (Mac example: /dev/tty.usbserial-A900YUBL, Windows example: COM1"`

	SerialBaud uint `short:"b" long:"baud" description:"Specifies the baud rate (speed) at which to communicate with the serial port."`

}

func main() {

	// synchronize access to relayChannels
	var channelLock sync.Mutex
	// a channel for each websocket connection
	// relayChannels := list.New()

	relayChans := make([]chan string, 0)
	// fmt.Println("test", relayChans)


	/////////////////////////////////
	// defaults
	opts.Port = 5565
	opts.Interface = ""
	opts.BaseDir = "../"
	opts.SerialDevice = ""
	// opts.SerialBaud = 9600
	opts.SerialBaud = 115200


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
	// event_channel := make(chan string)


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

			// event_channel <- line

			// // copy the list before we do anything - do this each time newly
			// // in case the list of channels has changed
			// tmpList := list.New()
			// channelLock.Lock()
			// for el := relayChannels.Front(); el != nil; el = el.Next() {
			// 	tmpList.PushFront(el)
			// }
			// channelLock.Unlock()

			// // now that we have our own copy, iterate over it and push events,
			// // assuming the buffers don't overflow, this should be asynchronous
			// for el := tmpList.Front(); el != nil; el = el.Next() {
			// 	el <- line
			// }

			channelLock.Lock()
			for i := 0; i < len(relayChans); i++ {
				relayChans[i] <- line
			}
			channelLock.Unlock()





			// line = "\"" + strings.TrimSpace(line) + "\""
			// var v interface{}
			// err2 := json.Unmarshal([]byte(line), &v)
			// if err2 == nil {
			// 	switch v.(type) {
			// 		case string: {
			// 			vs := v.(string)
			// 			if len(opts.Verbose) > 0 {
			// 				fmt.Printf("string value: %s\n", vs)
			// 			}
			// 			// push to channel
			// 			event_channel <- vs
			// 			break
			// 		}
			// 	}
			// }
		}



	}()



	if len(opts.Verbose) > 0 {
		fmt.Printf("Starting Web Server...\n")
	}



	// for e := l.Front(); e != nil; e = e.Next() {
	// 	// do something with e.Value
	// }

	// curRelay := int32(0)


	http.Handle("/", http.FileServer(http.Dir("../")))
	http.Handle("/serial-relay", websocket.Handler(func (ws *websocket.Conn) {

		// each handler gets it's own buffered channel
		myChannel := make(chan string, 1024)
		channelLock.Lock()

		relayChans = append(relayChans, myChannel)

		// relayChannels.PushFront(myChannel)
		channelLock.Unlock()


		// thisRelay := rand.Int31n(999999999)+1 // make sure we don't get a zero
		// curRelay = thisRelay

		// if len(opts.Verbose) > 0 {
		// 	fmt.Printf("Serial relay start with ID %d\n", thisRelay)
		// }



		keep_going := true
		outstr := ""

		for keep_going {
			select {
				// read next event
				case outstr = <- myChannel:
					if len(opts.Verbose) > 0 {
						fmt.Printf("Sending data to websocket: %s\n", outstr)
					}
					// write it out to websocket
					_, err := ws.Write([]byte(outstr))
					if err != nil {
						fmt.Printf("Error while writing: %s\n", err)
						keep_going = false
					}
			}
		}

		// // our own timeout channel that times out after one second
		// timeout := make(chan bool, 1)
		// go func() {
		//     time.Sleep(1 * time.Second)
		//     timeout <- true
		// }()


		// var outstr string
		// for thisRelay == curRelay {
		// 	select {
		// 		// read next event
		// 		case outstr = <- event_channel:
		// 			if len(opts.Verbose) > 0 {
		// 				fmt.Printf("Sending data to websocket: %s\n", outstr)
		// 			}
		// 			// write it out to websocket
		// 			_, err := ws.Write([]byte(outstr))
		// 			if err != nil {
		// 				// break out of for loop
		// 				thisRelay = 0
		// 			}
		// 			break
		// 		case <- timeout:
		// 			break
		// 	}
		// }

		// if len(opts.Verbose) > 0 {
		// 	fmt.Printf("Serial relay changed to %d, this handler (ID:%d) is exiting...\n", curRelay, thisRelay)
		// }

		channelLock.Lock()
		// relayChannels.Remove(myChannel)
		channelLock.Unlock()


	}))

	// // in separate routine we poll for 
	// go func() {

	// 	for true {
	// 		outstr := <- event_channel:
	// 		if len(opts.Verbose) > 0 {
	// 			fmt.Printf("Sending data to websocket: %s\n", outstr)
	// 		}
	// 		// write it out to websocket
	// 		_, err := ws.Write([]byte(outstr))
	// 		if err != nil {
	// 			// break out of for loop
	// 			//thisRelay = 0
	// 		}
	// 		break
	// 	}
	// }



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


