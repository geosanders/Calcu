
import threading
import time

def web_socket_do_extra_handshake(request):
	pass

def web_socket_transfer_data(request):

	print "HERE1"

	try:

		while True:

			message = request.ws_stream.receive_message()

			if message == "TEST":
				print "TEST!"
			else:
				print "WHOA!"

			request.ws_stream.send_message("ACK")

	finally:
		pass


