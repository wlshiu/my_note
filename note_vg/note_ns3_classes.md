NS-3 class
---

+ `Simulator` class
    - `Schedule(exec_time_stamp, event_handler, arguments...)`
        > configure the event trigger list with time-stamp

        1. the max of supporting arguments is **5**
            > It is instanced with template of C++

        1. the context (node ID) is the node of currently-executing event

    - `ScheduleNow()`
        > It allows you to schedule an event for the current simulation time
        >> they will execute _after_ the current event is finished executing
        but _before_ the simulation time is changed for the next event.

        1. the context (node ID) is the node of currently-executing event

    - `ScheduleWithContext(context, exec_time_stamp, event_handler, arguments...)`
        > It can configure the event trigger list for the context (node ID) with time-stamp
        >> To avoid this case, when simulating the transmission of a packet from a node to another,
        this behavior is undesirable since the expected context of the reception event is that of the receiving node, not the sending node.

        1. No context (global event)
            > `Simulator::NO_CONTEXT` == 0xFFFFFFFF


    - `Run()`
        > start to execute the event queue (time priority, oldest is most height)

    - `Destroy()`
        > cleanup simulation resources

    - `GetContext()`
        > The node id of the currently executing network node is in fact tracked by the Simulator class.
        So this method will return the the current context (node ID) with 32-bits integer.

