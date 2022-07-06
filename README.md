# factorio-train-balancer
Using complicated Circuit network logic to use the railway as an anything-to-anything bus in Factorio

I love playing Factorio but I hate using conveyor belts, especially when trying to use them to balance overlapping recipe chains. I also don't particularly like the tedium of having to build large, centralised and monolithic main furnaces or factory areas.

So I decide to use the railway as a kind of "anything to anything bus". Every train station that produces say iron ore, for example, is named "Pickup Iron ore" and stations that consume it are named "Dropoff Iron ore". This is not a new strategy and is a good way to get resources to where they're needed, regardless of where they are on the map.

However, there is a problem with this strategy alone —how do you make sure all the dropoff stations are serviced enough? What if you have some dropoff stations that are really far away from the others? Trains are lazy and will always go to the closest available station. So we use the network to control which dropoff stations for a given resource type trains are allowed to go to, to effectively "load-balance" the resources among the dropoff stations such that they are kept to roughly the same percentage full as their peer stations handling the same resource type.

**Alas, the logic circuits to achieve this are non-trivial, hence this project.**

In essence, the way it works is that all dropoff stations are connected to a common circuit network that uses both the red and green wires (pickup stations need not be connected to the circuit network). It is fine (and recommended) to connect all dropoff stations to a common "railway" circuit network, even dropoff stations of different resource types, to keep things simple and un-cluttered. Circuit signal `P`, along with signals for every type of resource you want to handle with this system, are reserved. There is no reason why you couldn't use this "global" circuit network for other unrelated purposes, but I recommend keeping this usage to a specific set of the non-item signals to avoid potential interference with the train-balancing system.

The dropoff stations have 1 logic circuit each, quite an elaborate one, which is connected at one end to the "railway" circuit network and to the train station components (train stop, chests, etc...) at the other. A blueprint book containing samples for _Pickup Raw fish_ and _Dropoff Raw fish_ is provided as a template, and this can be adapted systematically for other resources as required, so long as great care is taken when modifying the circuit signals for the substituted resource type, and that the instructions included within the blueprints is followed when doing this.

When this system proves its worth and maturity more, I would like to distribute pre-made blueprints for common resource types, but I am not doing this right now in case the system needs a major redesign.

> In the root of this repository, various design-related files can be found, including simulations of the logic in both Python and prototypes of the logic circuits in SystemVerilog.

I hope you find this system at least as useful as the amount of headache it gave me when I was designing it :)
