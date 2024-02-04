publishing_mqtt = false
publishing_http = false

watchdog = tmr.create()
chip_id = string.format("%06X", node.chipid())
device_id = "esp8266_" .. chip_id
mqtt_prefix = "uart/" .. device_id
mqttclient = mqtt.Client(device_id, 120)

dofile("config.lua")

function wdr()
	watchdog:stop()
	watchdog:start()
end

function wd_err()
	print("Watchdog:Err")
	node.restart()
end

function mqtt_err(client)
	print("MQTT:Err")
end

function wifi_err()
	print("WiFi:Err " .. wifi.sta.status())
end

function setup_client()
	print("MQTT:Rdy " .. mqtt_prefix)
	publishing_mqtt = true
	mqttclient:publish(mqtt_prefix .. "/state", "online", 0, 1, function(client)
		client:subscribe(mqtt_prefix .. "/in", 0)
		publishing_mqtt = false
	end)
end

function connect_mqtt()
	print("")
	print("WiFi:Rdy " .. wifi.sta.getip())
	mqttclient:on("connect", setup_client)
	mqttclient:on("offline", mqtt_err)
	--mqttclient:on("connfail", mqtt_err)
	mqttclient:on("message", print_mqtt)
	mqttclient:lwt(mqtt_prefix .. "/state", "offline", 0, 1)
	mqttclient:connect(mqtt_host)
end

function connect_wifi()
	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, connect_mqtt)
	wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, wifi_err)
	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_err)
	wifi.setmode(wifi.STATION)
	wifi.sta.config(station_cfg)
	wifi.sta.connect()
end

function print_mqtt(client, topic, message)
	print("RX:" .. message)
	wdr()
	collectgarbage()
end

function publish_mqtt(topic, payload, retain)
	if publishing_mqtt then
		print("MQTT:Err")
	else
		publishing_mqtt = true
		mqttclient:publish(topic, payload, 0, retain or 0, function(client)
			publishing_mqtt = false
			print("MQTT:OK")
			wdr()
			collectgarbage()
		end)
	end
end

function publish_influx(payload)
	if publishing_http then
		print("Influx:Err")
	else
		publishing_http = true
		http.post(influx_url, influx_header, payload, function(code, data)
			publishing_http = false
			print("Influx:OK")
			wdr()
			collectgarbage()
		end)
	end
end

watchdog:register(90 * 1000, tmr.ALARM_SEMI, wd_err)
watchdog:start()

connect_wifi()
