Title: Simple Wireless NS3 Module Description
Author: Junseok Kim
Email: junseok@email.arizona.edu
Website: ece.arizona.edu/~junseok
Date: Oct 17, 2011
----------------------------------------------

NS3 provides 802.11 and 802.16 modules. These modules have most of functions and nicely follow flows specified in the standards.
The bad thing is that many c++ classes are entangled and it's difficult to add/delete some new functions.
I developed this simple wireless NS3 module for people -- including me :) -- who want to implement their ideas 
such as power control, sleep/wake, topology control, and etc on a very basic wireless MAC/PHY.

I builded this module from the scratch but based on NS2's 802.11 module.
MAC layer supports general operations of CSMA/CA with/without RTS/CTS. PHY layer supports the physical model.
The channel object is shared by all nodes and it maintains all concurrent transmissions in a table.
So, from this table, SINR is calculated and used for reception decision.

This module is independent of upper layer. Two examples are provided in the examples folder. 
One of two uses AODV as a routing protocol.

You can specify parameters of MAC/PHY on an example (or scenario) file.
Here are the adjustable parameters:
1. transmission rate,
2. transmission power,
3. SINR threshold,
4. carrier sensing threshold,
5. many durations (e.g., DIFS, SIFS, preamble, etc)
6. minimum and maximum contention window size,
7. transmission limit, and
8. queue limit.

This module is tested with NS3 version 3.12.1.

Feel free to email me, if you have any question or find errors or mistakes.
Like other phd students plus family guy, I'm super busy :) but I'll try to respond your comment.
Thank you for using (or interest in) my codes. I hope, these codes could help your research.

