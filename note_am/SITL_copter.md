## Copter with SITL on Ubuntu 14.10
-----

- Preconditions

    ```
        $ cd ~/ardupilot/ArduCopter
        $ sim_vehicle.sh --map --console

        param load ..\Tools\autotest\copter_params.parm
    ```

- Taking off
    > Copter should take off to an altitude of 40 metres and then hover (while it waits for the next command).
    >> Takeoff must start within 15 seconds of arming, or the motors will disarm!

    ```
		# change to guided mode for takeoff
        mode guided

		# After arming, you MUST order next command in 15 seconds
        arm throttle

		# rise 40 metres
        takeoff 40
    ```

- Flying a mission
    > After you’ve taken off, you should load your WayPoint script and change mdoe to auto

    ```
        wp load ../Tools/autotest/my_circuit.txt
        mode auto

        # loop this mission
        wp loop
    ```
