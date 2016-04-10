---
categories: projects
title: ISS Notifier Using ATTiny
---
My sister loves astronauts and the International Space State, so, with Christmas coming up, I knew I had found my gift to her when I saw Nathan Bergey's [ISS Notify](http://mechanicalintegrator.com/2011/iss-notify/).

The idea is simple: light up a lamp when the Space Station is overhead. Nathan's implementation uses an Arduino-compatible Teensy 2.0 to light the LEDs and to communicate to a host computer, where a python program parses data about the ISS orbit and returns a simple "yes" or "no" to the microcontroller.

My goal is to create a self-contained device which won't require a host computer. That means parsing all data on the microcontroller.

## Hardware selection

- The lamp will be a plexiglass [edge-lit display](http://grathio.com/2010/06/how_to_edge_lighting_displays/)
- The microcontroller will be an ATTiny 84. My reason for selecting the ATTiny is to gain experience with AVR microcontrollers outside of the Arduino world, and because I have already played with PICs (in my EE200 class) and ARMs (with the Cypress PSoC4).
- For communication, an [ethernet SPI](http://www.elecfreaks.com/wiki/index.php?title=ENC28J60_Mini_Ethernet_Module_%283.3V/5V%29) module (based on the ENC28J60 chip)

## Software design

- The uC will communicate over SPI to the ethernet module (requirement: SPI library)
- JSON will be used for web queries and replies (requirement: [JSON parsing](http://zserge.com/jsmn.html) library)

On power up:

- First, an [ip to geolocation](http://freegeoip.net/) service will be queried to find current LAT/LONG
- Then, this LAT/LONG and UTC time will be used to find the current time

Periodically:

- The [ISS Pass Times API](http://open-notify.org/Open-Notify-API/ISS-Pass-Times/) from Open-Notify (another one of Nathan Bergey's projects) will be queried to find the next pass time
- The current UTC time will be queried again, the time zone offset will be subtracted, and the result will be compared with the next pass time.
- Rinse and repeat