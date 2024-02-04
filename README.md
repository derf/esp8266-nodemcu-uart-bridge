# ESP8266 Lua/NodeMCU MQTT to UART bridge

[esp8266-nodemcu-uart-bridge](https://finalrewind.org/projects/esp8266-nodemcu-uart-bridge/)
provides an ESP8266 NodeMCU Lua application (`init.lua`) that mirrors
incoming MQTT messages to the ESP8266's UART and can also transmit messages
received by UART to an MQTT broker or to InfluxDB. This way, it can add simple
MQTT/InfluxDB connectivity to devices that do not have a WiFi / ethernet
connection.

## Dependencies

`init.lua` has been tested with Lua 5.1 on NodeMCU firmware 1.5.4.1(39cb9a32)
(commit 81ec3665cb5fe68eb8596612485cc206b65659c9, integer build). This allows
it to run on old ESP8266-01 boards with just 512kB of Flash. It requires the
following modules.

* http
* mqtt
* node
* tmr
* wifi

## Usage

### Startup

Once connected, the ESP8266 will output the following lines on its TX line:

* `WiFi:Rdy` *IP-address*
* `MQTT:Rdy` *MQTT-prefix*

The default MQTT prefix is `uart/esp8266_`*Chip-ID*, e.g.
`uart/esp8266_82B45C`.  Additionally, the ESP8266 will publish a retained
"online" message under *MQTT-prefix*/**state** and subscribe to
*MQTT-prefix*/**in**.

### MQTT to UART

The ESP8266 prints each received *message* with an "RX:" prefix on its TX line,
like so:

`RX:`*message*

### UART to MQTT

When the ESP8266 receives **publish_mqtt**(*topic*, *payload*, *retain*) on its
RX line, it will publish the specified payload under the specified topic.
The *retain* flag defaults to false. For instance, the following input will
publish "hello" under `uart/esp8266_`*Chip-ID*`/out`:

`publish_mqtt(mqtt_prefix .. "/out", "hello")`

If the message has been sent out successfully, it will reply with `MQTT:OK` or
`> MQTT:OK`. Otherwise, it will reply with `MQTT:Err` or `> MQTT:Err`

### Watchdog

If none of the following four events happen for a time span of 90 seconds, the
ESP8266 will reset itself, causing a re-connection to WiFi and MQTT server.

* The ESP8266 receives a message via MQTT
* The ESP8266 receives a **publish_mqtt** command via RX and the command
  completes successfully
* The ESP8266 receives a **publish_influx** command via RX and the command
  completes successfully
* The ESP8266 receiveds a **wdr()** command via RX.

### Error Handling

The following messages on the ESP8266 TX line indicate errors.
Note that some errors can have several reasons.

* `MQTT:Err` or `> MQTT:Err` – Failed to publish MQTT message (another message was still being
  processed)
* `MQTT:Err` or `> MQTT:Err` – Connection to MQTT broker has been lost
* `WiFi:Err` or `> WiFi:Err` – Unable to establish WiFi connection
* `WiFi:Err` or `> WiFi:Err` – WiFi connection has been lost
* `Watchdog:Err` or `> Watchdog: Err` – watchdog timeout, the device will reset (see above)

## Configuration

To use this application, you need to create a **config.lua** file with WiFI and
MQTT settings:

```lua
station_cfg = {ssid = "...", pwd = "..."}
mqtt_host = "..."
```

To use InfluxDB, configure URL and (optional) header:

```lua
influx_url = "..."
influx_header = "..."
```

## Resources

Mirrors of this repository are maintained at the following locations:

* [Chaosdorf](https://chaosdorf.de/git/derf/esp8266-nodemcu-uart-bridge)
* [git.finalrewind.org](https://git.finalrewind.org/esp8266-nodemcu-uart-bridge/)
* [GitHub](https://github.com/derf/esp8266-nodemcu-uart-bridge)
