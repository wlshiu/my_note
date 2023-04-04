Drone tool on Windows
------
- Install WinPython with 2.7.x
- download source
	* [mavlink](https://github.com/mavlink/mavlink)
	* [mavproxy](https://github.com/Dronecode/MAVProxy)
	* [dronekit](https://github.com/dronekit/dronekit-python)
- build source
	* Run **WinPython Command Prompt.exe** in WinPython folder
	* mavlink
	    + change folder
			
			```
			cd your_mavlink_folder
			cd pymavlink
			```

		+ build and install

			```
			python setup.py build
			python setup.py install
			```
	* mavproxy
		+ change folder

			```
			cd your_mavproxy_folder
			```
		+ build and install

			```
			python setup.py build
			python setup.py install
			```
	* dronekit
		+ change folder

			```
			cd your_dronekit-python_folder
			```
		+ build and install

			```
			python setup.py build
			python setup.py install
			```
- pip install
	* Run **WinPython Command Prompt.exe** in WinPython folder
	
		```
		pip install droneapi
		```
	* install dronekit sitl

		```	
		pip2 install dronekit-sitl -UI
		```

- run dronekit-sitl

	```
	dronekit-sitl copter-3.3 -I0 -S --model quad --home=24.7739516,121.017747,580,270
	```

- run mavproxy

	```
	python .\WinPython-64bit-2.7.10.2\python-2.7.10.amd64\Lib\site-packages\MAVProxy\mavproxy.py --master tcp:127.0.0.1:5760 --sitl 127.0.0.1:5501 --out 127.0.0.1:14550
	```



