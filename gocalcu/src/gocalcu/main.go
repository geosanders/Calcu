
package main

import "net/http"
import "io"
import "fmt"
import "strconv"
// import "bytes"
import "bufio"
import "code.google.com/p/go.net/websocket"
import "github.com/jessevdk/go-flags"
// import "github.com/tarm/goserial"
// import "encoding/hex"


var opts struct {

	Verbose []bool `short:"v" long:"verbose" description:"Show verbose information"`

	Port uint `short:"p" long:"port" description:"Port number for server to listen on"`

	Interface string `short:"I" long:"interface" description:"Interface IP to listen on"`

	BaseDir string `short:"d" long:"basedir" description:"Base directory to serve files out of"`

	SerialDevice string `short:"s" long:"serial" description:"Specifies the serial device to communicate with. If unspecified, read from the console.  (Mac example: /dev/tty.usbserial-A900YUBL, Windows example: COM1"`

}

func main() {



	/////////////////////////////////
	// defaults
	opts.Port = 5565
	opts.Interface = ""
	opts.BaseDir = "../"
	opts.SerialDevice = ""


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

	// if err != nil {
	// 	panic("Error parsing args: " + err.Error())
	// }
	// fmt.Printf("Type of err: ", reflect.TypeOf(err) == flags.ErrHelp)
	// return
	// help error is fine, just exit
	// if flags.Error(err).Type == flags.ErrHelp {
	// 	return
	// } else
	// if err != nil { // catch other errors and report on them
	// 	fmt.Printf("type:", flags.Error(err))
	// 	panic("Error while parsing flags: " + err.Error())
	// }

	if len(args) > 0 {
		panic("No idea what to do with extra args on the command line...")
	}

	// fmt.Printf("port: " + strconv.Itoa(int(opts.Port)) + "\n")

	// for i := 0; i < len(args); i++ {
	// 	fmt.Printf("arg: " + args[i] + "\n")
	// }



	// run IO separately
	go func() {

		// c := &serial.Config{Name: "/dev/tty.usbserial-A900YUBL", Baud: 115200}
		// c := createSerialReader("/dev/tty.usbserial-A900YUBL")
		s, err := createSerialReader(opts.SerialDevice)
		if err != nil {
			panic(err.Error())
		}


		// buf := make([]byte, 1)
		// for true {
		// 	_, err := s.Read(buf)
		// 	if err != nil {
		// 		panic(err.Error())
		// 	}
		// 	// fmt.Printf("read byte: %s\n", buf[0])
		// 	fmt.Printf("%s", hex.Dump(buf))
		// }


		scanner := bufio.NewScanner(s)

		// line := scanner.Text()
		for scanner.Scan() {
			line := scanner.Text()
			fmt.Printf("got line: %s\n", line)
		}


		// var buffer bytes.Buffer

		// buf := make([]byte, 4096)
		// for true {
		// 	n, err := s.Read(buf)
		// 	if err != nil {
		// 		panic(err.Error())
		// 	}
		// 	buffer.Write(buf[0:n])
		// 	line, err2 := buffer.ReadString('\n')
		// 	if err2 == nil || err2 == io.EOF {
		// 		buffer.Reset()
		// 	} else {
		// 		fmt.Printf("Got data: %s\n", line)
		// 		// trim the buffer down so it only contains what's left
		// 	buffer = *bytes.NewBufferString(buffer.String())
		// 	}

		// }

	    // c.Close() // hm, this only exists on windows...
	}()




	fmt.Printf("Starting Web Server...\n")

	http.Handle("/", http.FileServer(http.Dir("../")))
	http.Handle("/echo", websocket.Handler(EchoServer))

	fmt.Printf("Running\n")

	herr := http.ListenAndServe(opts.Interface + ":" + strconv.Itoa(int(opts.Port)), nil)
	if herr != nil {
		panic("ListenAndServe: " + herr.Error())
	}

}


func EchoServer(ws *websocket.Conn) {

	// c := &serial.Config{Name: "/dev/tty.usbserial-A900YUBL-11", Baud: 115200}
	// s, err := serial.OpenPort(c)
	// if err != nil {
	// 	msg := err.Error()
	// 	b, _ := json.Marshal(m)
	// 	ws.Write("{\"error\":"+b+"}")
	// 	return
	// }

	// /dev/tty.usbserial-A900YUBL
	io.Copy(ws, ws)
}