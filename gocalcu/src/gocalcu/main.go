
package main

import "code.google.com/p/go.net/websocket"
import "github.com/jessevdk/go-flags"
import "github.com/tarm/goserial"
import "net/http"
import "io"
import "fmt"
import "strconv"
import "bytes"


var opts struct {

	Verbose []bool `short:"v" long:"verbose" description:"Show verbose information"`

	Port uint `short:"p" long:"port" description:"Port number for server to listen on"`

	Interface string `short:"I" long:"interface" description:"Interface IP to listen on"`

	BaseDir string `short:"d" long:"basedir" description:"Base directory to serve files out of"`

}

func main() {


	c := &serial.Config{Name: "/dev/tty.usbserial-A900YUBL", Baud: 115200}
	s, err := serial.OpenPort(c)
	if err != nil {
		panic(err.Error())
	}

 	var buffer bytes.Buffer

	buf := make([]byte, 128)
	for true {
    	n, err := s.Read(buf)
    	if err != nil {
    		panic(err.Error())
    	}
    	buffer.Write(buf[0:n])
    	fmt.Printf("Got data: ", buffer.String())
    }

    // c.Close() // hm, this only exists on windows...


	/////////////////////////////////
	// defaults
	opts.Port = 5565
	opts.Interface = ""
	opts.BaseDir = "../"


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