MARProxy
-------------------------

- Command-line based ground station (GS) S/W
- Forward the messages between UAV and other GS
	> e.g. <br>
	> `UAV` --> *wifi udp* --> `GS with MAVProxy` --> *by pass* --> other GS (smartphone/tablet)

- Setup
	+ Step 1: Check you can connect to your UAV with COM port.
		> `laptop` --> *COM port* --> `UAV`
	
	+ Step 2: Install MAVProxy
	
		```
			# pre-requisite lib
			$ sudo apt-get install python-opencv python-wxgtk python-pip python-dev
			ps. On some Linux systems, python-wxgtk may be instead named as python-wxgtk2.8

			$ sudo pip install pymavlink MAVProxy
		```
	+ Step 3: Ready to run

		```
			# configure basic setting
			$ mavproxy.py --master="com3" -- baudrate 57600
			...
			Logging to mav.tlog
			...

		```
		
	+ Step 4: Forwarding over network

		