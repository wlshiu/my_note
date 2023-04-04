## SITL on Ubuntu 14.10
-----

- Install
    + Download ardupilot

	```
	    $ git clone git://github.com/diydrones/ardupilot.git

	    # JSBSim flight simulator
	    $ git clone git://github.com/tridge/jsbsim.git
	    $ sudo apt-get install libtool automake autoconf libexpat1-dev
	    $ cd jsbsim
	    $ git pull
	    $ ./autogen.sh --enable-libraries
	    $ make

    	# Install some required packages
	    $ sudo apt-get install python-matplotlib python-serial python-wxgtk2.8 python-lxml
	    $ sudo apt-get install python-scipy python-opencv ccache gawk git python-pip python-pexpect
	    $ sudo pip install pymavlink MAVProxy

    	# Add path
	    $ vim ~/.bashrc

    	    ...
	        export PATH=$PATH:$HOME/jsbsim/src
	        export PATH=$PATH:$HOME/ardupilot/Tools/autotest
	        export PATH=/usr/lib/ccache:$PATH
	```

- Setup

	```
	    # ~/ardupilot/ArduPlane/
	    $ cd ardupilot/ArduPlane/

	    If the first time rune, initial to default
	        $ sim_vehicle.sh -w
	    or
	        $ sim_vehicle.sh --console --map --aircraft test
	```
	+ sim_vehicle.sh (*flow*)
		* set vehicle type (plane/coper/rover)
			> default: use folder name (ArduPlane/ArduCopter/APMrover2/AntennaTracker)
		* make clean && make TARGET
            >- TARGET is the board type, e.g. sitl, px4-v2, ...etc
			>- generate *.elf (for GDB) and eeprom.bin
		* get the location information
			> default: autotest/locations.txt
		* download data to aircraft

			```
				# UDP port => 14550
				# --out IP_ADDRESS:14550 => GS listen ip_addr
                $ mavproxy.py –master="com14" –baudrate 57600 –out 127.0.0.1:14550

                # parameters for SITL simulator
				$ mavproxy.py --master tcp:127.0.0.1:5760 --sitl 127.0.0.1:5501 --out 127.0.0.1:14550 --out 127.0.0.1:14551
			```
- Load a mission

	```
	    wp load ../Tools/autotest/Plane-Missions/CMAC-toff-loop.txt
	        msg:
	            MANUAL> xxx
	                ...
	    arm throttle
	    mode auto
	```
