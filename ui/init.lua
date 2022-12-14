awful = require("awful")
gears = require("gears")
require("awful.autofocus")
wibox = require("wibox")
beautiful = require("beautiful")
hotkeys_popup = require("awful.hotkeys_popup")
naughty = require("naughty")
keygrabber = require("awful.keygrabber")
require("config")

require("ui.base")
require("ui.bar")
require("ui.panel")
require("ui.notifications")
require("ui.runprompt")
require("ui.calender")
require("ui.layoutlist")

awful.mouse.append_global_mousebindings({
	awful.button({}, 1, function()
		calender.visible = false
		npanel.visible = false
		runprompt.visible = false
		keygrabber.stop(p.grabber)
		keygrabber.stop(searchpr.grabber)
	end),
})

timer1 = gears.timer({
	timeout = 1,
	call_now = true,
	autostart = true,
	callback = function()
		awful.spawn.easy_async_with_shell("mpstat | awk 'FNR == 4 {print $3}'", function(a)
			cpu.widget.value = tonumber(a)
		end)

		awful.spawn.easy_async_with_shell("free | awk 'FNR == 2 {print $3}'", function(r)
			ram.value = tonumber(r)
		end)

		awful.spawn.easy_async_with_shell("iwctl station wlan0 show | grep network", function(out)
			if out == "" then
				neticon.image = beautiful.disconnected
				net.text = " Disconnected"
			else
				neticon.image = beautiful.connected
				net.text = " " .. string.gsub(string.sub(out, 35), "[ \t]+%f[\r\n%z]", "")
			end
		end)

		awful.spawn.easy_async_with_shell("acpi -b | awk '{print $3$4}'", function(out)
			if string.find(out, "Charging") then
				battery.update = not battery.update or false
				if battery.update then
					battery.widget.bar_active_color = "#69EF86"
					battery.widget.handle_color = "#69EF86"
				else
					battery.widget.bar_active_color = "#69BE86"
					battery.widget.handle_color = "#69BE86"
				end
			end
			battery.widget.value = tonumber(string.sub(out, string.find(out, "[0-9]+")))
		end)

		awful.spawn.easy_async_with_shell("pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}'", function(out)
			volume.widget.value = tonumber(string.sub(out, string.find(out, "[0-9]+")))
		end)

		awful.spawn.easy_async_with_shell("brightnessctl i | grep Current | awk '{print $4}'", function(bright)
			brightness.widget.value = tonumber(string.sub(bright, string.find(bright, "[0-9]+")))
		end)
	end,
})

timer2 = gears.timer({
	timeout = 30,
	call_now = true,
	autostart = true,
	callback = function()
		awful.spawn.easy_async_with_shell("df -BM | grep sda | awk '{print $2" .. '" "' .. "$3}'", function(b)
			local words = {}

			for word in b:gmatch("[0-9]+") do
				table.insert(words, word)
			end

			fs.widget.max_value = tonumber(words[1])
			fs.widget.value = tonumber(words[2])
		end)
	end,
})

timerOn = true

awesome.connect_signal("timers", function()
	if timerOn then
		timer1:stop()
		timer2:stop()
	else
		timer1:start()
		timer2:start()
	end
	timerOn = not timerOn
end)
