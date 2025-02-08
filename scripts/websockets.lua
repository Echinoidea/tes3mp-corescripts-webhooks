local json = require("dkjson")

function processCommand(line)
	tes3mp.LogMessage(2, "[WebSocket] Processing command: " .. line)

	local command, _, err = json.decode(line, 1, nil)
	if err then
		tes3mp.LogMessage(3, "[WebSocket] JSON error: " .. err)
		return
	end

	if command.command == "chat" then
		if command.message then
			local msg = "[WebSocket] " .. command.message .. "\n"
			tes3mp.LogMessage(2, "[WebSocket] Chat: " .. command.message)

			-- Send message to all players
			for pid, player in pairs(Players) do
				if player:IsLoggedIn() then
					tes3mp.SendMessage(pid, msg, false)
				end
			end
		end
	end
end

function checkWebSocketPipe()
	local pipe = io.open("/tmp/tes3mp_api", "r")
	if not pipe then
		tes3mp.LogMessage(3, "[WebSocket] ERROR: Pipe not found.")
		return
	end

	-- ✅ Fix: Read entire pipe and clear contents
	local content = pipe:read("*a") -- Read everything
	pipe:close()

	if content and content ~= "" then
		for line in content:gmatch("[^\r\n]+") do
			processCommand(line)
		end
	end

	-- ✅ Fix: Clear the pipe by reopening in "w" mode
	local clearPipe = io.open("/tmp/tes3mp_api", "w")
	if clearPipe then
		clearPipe:close()
	end
end

-- ✅ Proper Timer Function
function websocketTimerCallback()
	checkWebSocketPipe()
	tes3mp.RestartTimer(websocketTimer, 1000)
end

customEventHooks.registerHandler("OnServerPostInit", function()
	tes3mp.LogMessage(2, "[WebSocket] Initialized.")

	-- Only create named pipe if it doesn’t already exist
	local file = io.open("/tmp/tes3mp_api", "r")
	if not file then
		os.execute("mkfifo /tmp/tes3mp_api")
		tes3mp.LogMessage(2, "[WebSocket] Created named pipe.")
	else
		file:close()
	end

	-- ✅ Fix: Use Correct Timer API
	websocketTimer = tes3mp.CreateTimer("websocketTimerCallback", 1000)
	tes3mp.StartTimer(websocketTimer)
	tes3mp.LogMessage(2, "[WebSocket] WebSocket timer started.")
end)
