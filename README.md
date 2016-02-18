# Event-Detection-case-study
An algorithm to detect ON-OFF events in a home

Problem Statement:

Design an algorithm that can detect when the electric hot water heater is turned on and turned off in a home by simply using the Main Home wattage data
and the timestamps.

Data:

Timestamp (UTC) - Timestamps with time starting at UTC/GMT-0

Timestamp (UTC-4) - Timestamps with time starting at UTC/GMT-4 (It provides the best representation of the real time zone).

Mains - This provides all the wattage information of the home (Energy Mains). It includes the energy information of the hot water heater as well as other appliances in the home.

Real_hwh - This is the energy consumption of an electric hot water heater.

Hot water heater wattage behavior:

Electric hot water heaters have very predictable energy usage behaviors. When these hot water heaters are turned on, they usually consume approximately 2700-3000 watts. They do not have
a “middle” state; hence they are either on (2700 to 3000 watts) or off (0 to 10 watts).

Hot water heater consumption behavior:

Hot water heaters have 2 distinct consumption behaviors

Temperature Maintenance Cycle

During the period of a day, hot water heaters turn on and off at different times in order to maintain the temperature of the hot water. They do this many times a day and the cycle usually
lasts between 4-8 minutes.

Heating Cycle

A heating cycle is described as a cycle that occurs once a large amount of hot water has been
consumed inside the tank. This usually occurs after a shower, bath or even laundry. When this
hot water is consumed, cold water enters the tank and hence the hot water heater must be turned
on for a longer period of time in order to heat this cold water. The amount of time the hot water
heater is turned on is dependent on the amount of hot water that was consumed.
