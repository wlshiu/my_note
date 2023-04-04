DroneKit pyExample on Ubuntu 14.10
-------------------------

- Install pre-requisite packages
    + dronekit-sitl

    ```
        $ sudo pip2 install dronekit-sitl -UI
    ```
    + droneapi

    ```
        $ sudo pip install droneapi
    ```
	+ check version
	
	```
		$pip list | grep -i "drone\|MAV"
		droneapi (1.5.0)
		dronekit (2.0.0rc3)
		dronekit-sitl (3.0.1)
		MAVProxy (1.4.35)
		pymavlink (1.1.62)
	```
- clone droankit api examples

    ```
        # Ctrl + Alt + t
        Console 2>
        $ cd ~/your_workspace/
        $ git clone https://github.com/dronekit/dronekit-python.git
        $ cd dronekit-python/examples
    ```

- Start simulator
    * dronekit-sitl

    ```
        # Ctrl + Alt + t
        # Console 1:
    	$ dronekit-sitl copter-3.3 -I0 -S --model quad --home=24.7739516,121.017747,580,270
		
		# --home=Latitude(x),Longitude(y),Altitude(z),Yaw(yaw angle)
    ```
    * Mavproxy

	```
        # Console 2:
        $ mavproxy.py --master tcp:127.0.0.1:5760 --sitl 127.0.0.1:5501 --map --out 127.0.0.1:14550
    ```

- Run dronekit python
    + launch

    ```
		# Console 2:
        MAV> param set ARMING_CHECK 0
        MAV> module load droneapi.module.api

        MAV> api start mission_basic/mission_basic.py

        # View the changes on the map.
    ```

- Connect to the simulator

    ```
        # Ctrl + Alt + t
        Console 3:
        $ python vehicle_state.py --connect 127.0.0.1:14550
    ```


