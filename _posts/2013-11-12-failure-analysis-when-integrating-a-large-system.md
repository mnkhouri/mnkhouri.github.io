The final lab project in EE300W was to construct a security system comprised of multiple subsystems. Each team was assigned to one subsystem, which comprised a sensor such a fingerprint scanner, camera, voice recognition module, or touchpad. The teams were to interface their sensor with an mbed microcontroller and a LabVIEW GUI. To communicate with other units, each microcontroller used a CAN transceiver that was wired to a common bus.

One group was assigned to the task of integrating the systems, but due to illness and other circumstances, the task was taken on by my team two weeks prior to the project due date. The project concluded with only four sensors integrated together, and therefore our teams failed to complete the mission. Below, I will identify three of the root causes that I believe contributed most strongly to this failure and suggest steps to mitigate them in the future.

1. Root cause: Underdefined specifications and requirements

    - Context within our project: Requirements called for a LabVIEW interface for each sensor, but also for an integrated system controlled by one master unit. When teams were developing C code and LabVIEW interfaces, there were no concrete specifications for the architecture of the integrated system. Therefore, many teams had a program structure that was incompatible with being controlled from one central unit over CAN, and instead were designed to operate with either LabVIEW OR over CAN, instead of both.

    - Steps to mitigate: Planning for integration must take place early in the project in order to avoid incompatibilities between systems. While specific details are not necessary early, a clear architecture diagram outlining the channels over which commands and feedback will flow is crucial for avoiding time-consuming redesigning of code structure.

2. Root cause: No testing time due to poorly managed or nonexistent milestones

    - Context within our project: For integration, no milestones were conveyed to individual teams, other than the final deliverable date. Because individual teams had little to no stake in the integration, little to no time within the timeline was allocated by the teams for testing of their system with the integration team. Even though the integration team met with several other teams outside of class, too little time was allocated to the final integration.

    - Steps to mitigate: Establish clear integration milestones that allow time for overall system testing.

3. Root cause: Lack of leadership structure

    - Context within our project: Teams were unable to, early on, ask questions about the architecture or design of their subsystems because no integrating team was defined at that point. Because no integrating team was defined, no party had the responsibility of ensuring that all teams were moving towards the same goal. Additionally, no one was responsible for maintaining overall project milestones and adapting to slippages.

    - Steps to mitigate: Designate a managerial structure / team which can address overall integration issues from the beginning of the project.