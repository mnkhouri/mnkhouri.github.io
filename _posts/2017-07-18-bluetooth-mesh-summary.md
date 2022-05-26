---
categories: homepage
---

Bluetooth Mesh is a specification to allow for communication between and control of devices in a mesh network, similar to the ZigBee and Z-Wave specifications. The specification was published today by the Bluetooth Special Interest Group (SIG), and is ready for developers and manufacturers to work with. This is a short summary of the architecture and features of Bluetooth Mesh.

### The most imporant points

- Bluetooth Mesh will use (generally) the same hardware as BLE, but will require new software support at the stack layer -- not generally feasible to roll your own.
- Similar to ZigBee / Z-Wave in terms of capabilities.
- No hub required, though a hub-like device may still be desired for remote access/monitoring.
- BLE devices (e.g. phones) will be able to interact with the mesh (only if the user has one of a special class of device called a "proxy").

### A bit more in depth

#### Provisioning

Like those similar specification, BT Mesh will require "provisioning" devices to have them join the mesh. Devices that are part of a mesh network are called nodes and those that are not are called “unprovisioned devices”. Provisioning will require a user to make use of an application on a device, such as a tablet or phone, and input some information from the joining device. It may also require user interaction such as pushing a button on the joining device.

#### Control

Bluetooth Mesh introduces some application-layer "Models", which will allow for interoperability between devices by defining a collection of functions and behaviors. An example of a Model is a Generic Level device (e.g. light bulb) or a Generic OnOff client (e.g. wall switch). These Models make use of "states" (e.g. Generic OnOff, or 8 Bit Temperature). States can be extended through the use of "properties", which use the same data type as states, but deliver more information about the context of the data (e.g. Present Indoor Ambient Temperature and Present Outdoor Ambient Temperature instead of 8 Bit Temperature).

There is also support for "Scenes". A scene is a set of states stored on devices ahead of time, which can be triggered at once to move all those devices to their respective state in one coordinated action.

#### Communication

Bluetooth Mesh uses a publish/subscribe communication model. Devices may be assigned certain addresses to publish messages to, or to listen to. For example, a light switch may be assigned to publish to the address "Living Room". Several light bulbs may be assigned to subscribe to that address. To add a new light to the living room, only that light would need to be told to subscribe to the "Living Room" address, and no other nodes would need to know about this change. Some addresses may come preconfigured.

The specification has an interesting mechanism for low-power devices. When a devices is designed as "Low Power Node" (LPN), it may work in tandem with a "Friend", who will store all messages addressed to the LPN until queried by the LPN.

All communication is done via "managed flooding", where all messages are always broadcast, never unicast. A receiving node will re-broadcast a message as long as it has not previously broadcasted that exact message, and as long as the message has not travelled more than a certain number of hops (configurable by the sending device).

#### Security

All devices that are provisioned on the network are given a shared Network Key (NetKey), which prevents non-network devices from communicating with the network. Devices can further be grouped into application-specific groupings that share an Application Key (AppKey). This allows the smallest possible set of devices to have access to the relevant functions. For example, only lights and light switches would be given the lighting AppKey, preventing the thermostat from ever gaining knowledge of the commands the switches send to the lights.

#### Compatibility

Bluetooth Mesh is a giant layer cake that builds on top of Bluetooth Low Energy (BLE). The Bluetooth stack in use must support BT Mesh, which means that BLE devices would need an update (from the stack vendor) in order to support mesh. Most hardware that supports BLE should support Mesh, though.

BT Mesh introduces a concept of a "proxy node", which is a BT Mesh node that provides access to the BT Mesh for BLE devices.

#### Differentiating Factors

Most of the features above have some equivalent in ZigBee and Z-Wave networks. However, there are a few key differentiating factors:

- No hub required: Bluetooth Mesh networks do not have a centralized hub to coordinate communication. All nodes may send data to all other nodes. However, there is still a requirement for a "Provisioner", which is the (single) device/application that controls access to the mesh for provisioning new devices. Furthermore, a hub may still be desired for enabling remote control / monitoring.
- Always broadcast: since there is no routing (only broadcast messages), the mesh is relatively simple. As long as any mains-powered device can hear a message, it will re-broadcast it, making the mesh fairly resilient.
- Proxy Nodes: Proxy Nodes will allow for Bluetooth LE devices to access the mesh via the existing Bluetooth GATT specification, meaning that users with a smartphone supporting BLE will be able to interact with their BT Mesh devices.

#### More Information

- [Bluetooth SIG Mesh Landing Page](https://www.bluetooth.com/what-is-bluetooth-technology/how-it-works/le-mesh)
- [Bluetooth Mesh Tech Overview](https://www.bluetooth.com/~/media/files/marketing/bluetooth%20mesh%20overview.ashx)
- [Bluetooth SIG Mesh FAQ](https://www.bluetooth.com/what-is-bluetooth-technology/how-it-works/le-mesh/mesh-faq)
- [Bluetooth Mesh Specification](https://www.bluetooth.com/specifications/mesh-specifications)
