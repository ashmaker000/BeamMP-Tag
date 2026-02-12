
local floor = math.floor
local mod = math.fmod

local gameState = {players = {}}
local lastState = gameState
local weightingArray = {}

gameState.everyoneTagged = false
gameState.gameRunning = false
gameState.gameEnding = false


local roundLength = 5*60 -- length of the game in seconds
local defaultGreenFadeDistance = 100 -- how close the tagger has to be for the screen to start to turn green
local defaultColorPulse = false -- if the car color should pulse between the car color and green
local defaultTaggerTint = true -- if the tagger should have a green tint
local defaultDistancecolor = 0.3 -- max intensity of the green filter (softer default)
local disableResetsWhenMoving = true
local maxResetMovingSpeed = 2

local TEAM_COLORS = {"red", "blue", "purple", "white", "green", "yellow"}
local defaultMode = "multiteam" -- classic|multiteam
local defaultTeamCount = 6
local defaultInitialTaggers = 1
local defaultWinCondition = "classic" -- classic|lastteam

local manualTeamAssignments = {} -- playerName -> color
local manualInitialTaggers = {} -- playerName -> true

local function clamp(n, lo, hi)
	if n < lo then return lo end
	if n > hi then return hi end
	return n
end

local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shuffle(arr)
	for i = #arr, 2, -1 do
		local j = math.random(1, i)
		arr[i], arr[j] = arr[j], arr[i]
	end
	return arr
end

local function resolvePlayerNameByQuery(query)
	query = trim(query)
	if query == "" then return nil end
	local players = MP.GetPlayers()
	for _, name in pairs(players) do
		if tostring(name) == query then return tostring(name) end
	end
	local q = string.lower(query)
	for _, name in pairs(players) do
		if string.lower(tostring(name)) == q then return tostring(name) end
	end
	for _, name in pairs(players) do
		if string.find(string.lower(tostring(name)), q, 1, true) then return tostring(name) end
	end
	return nil
end

local function getEnabledTeamColors()
	local count = clamp(tonumber(defaultTeamCount) or 2, 2, #TEAM_COLORS)
	local out = {}
	for i=1,count do out[#out+1] = TEAM_COLORS[i] end
	return out
end

local function getSurvivorTeamCounts()
	local counts = {}
	for _, c in ipairs(TEAM_COLORS) do counts[c] = 0 end
	for _, player in pairs(gameState.players or {}) do
		if type(player) == "table" and not player.tagged then
			local t = tostring(player.team or "blue"):lower()
			if counts[t] ~= nil then counts[t] = counts[t] + 1 end
		end
	end
	return counts
end

local function aliveSurvivorTeams()
	local counts = getSurvivorTeamCounts()
	local alive = 0
	local lastTeam = nil
	for _, c in ipairs(TEAM_COLORS) do
		if (counts[c] or 0) > 0 then
			alive = alive + 1
			lastTeam = c
		end
	end
	return alive, lastTeam, counts
end

MP.RegisterEvent("tag_clientReady","clientReady")
MP.RegisterEvent("tag_onContactRecieve","onContact")
MP.RegisterEvent("tag_onContactReceive","onContact")
MP.RegisterEvent("tag_requestGameState","requestGameState")
MP.TriggerClientEvent(-1, "tag_resetTagged", "data")

local function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
	local time_days		= floor(total_seconds / 86400)
	local time_hours	= floor(mod(total_seconds, 86400) / 3600)
	local time_minutes	= floor(mod(total_seconds, 3600) / 60)
	local time_seconds	= floor(mod(total_seconds, 60))

	if time_days == 0 then
		time_days = nil
	end
	if time_hours == 0 then
		time_hours = nil
	end
	if time_minutes == 0 then
		time_minutes = nil
	end
	if time_seconds == 0 then
		time_seconds = nil
	end
	return time_days ,time_hours , time_minutes , time_seconds
end
 
local function compareTable(gameState,tempTable,lastState)
	for varableName,varable in pairs(gameState) do
		if type(varable) == "table" then
			if not lastState[varableName] then
				lastState[varableName] = {}
			end
			if not tempTable[varableName] then
				tempTable[varableName] = {}
			end
			compareTable(gameState[varableName],tempTable[varableName],lastState[varableName])
			if type(tempTable[varableName]) == "table" and next(tempTable[varableName]) == nil then
				tempTable[varableName] = nil
			end
		elseif varable == "remove" then
			tempTable[varableName] = gameState[varableName]
			lastState[varableName] = nil
			gameState[varableName] = nil
		elseif lastState[varableName] ~= varable then
			tempTable[varableName] = gameState[varableName]
			lastState[varableName] = gameState[varableName]
		end
	end
end

local function updateClients()
	local tempTable = {}

	compareTable(gameState,tempTable,lastState)

	if tempTable and next(tempTable) ~= nil then
		MP.TriggerClientEventJson(-1, "tag_updateGameState", tempTable)
	end
end

function clientReady(localPlayerID, data)
	local playerName = MP.GetPlayerName(localPlayerID)
	if playerName then
		local player = gameState.players[playerName]
		if player then
			gameState.players[playerName].responded = true
		end
	end
end

function requestGameState(localPlayerID)
	MP.TriggerClientEventJson(localPlayerID, "tag_recieveGameState", gameState)
end

local function infectPlayer(playerName,force)
	local player = gameState.players[playerName]
	if player.localContact and player.remoteContact and not player.tagged or force and not player.tagged then
		player.tagged = true
		if not force then
			local taggerPlayerName = player.infecter
			gameState.players[taggerPlayerName].stats.tagged = gameState.players[taggerPlayerName].stats.tagged + 1
			gameState.TaggedPlayers = gameState.TaggedPlayers + 1
			gameState.nonTaggedPlayers = gameState.nonTaggedPlayers - 1
			gameState.oneTagged = true

			MP.SendChatMessage(-1,""..taggerPlayerName.." has tagged "..playerName.."!")
		else
			MP.SendChatMessage(-1,"server has tagged "..playerName.."!")
		end

		MP.TriggerClientEvent(-1, "tag_recieveTagged", playerName)

		updateClients()
		--MP.TriggerClientEventJson(-1, "tag_recieveGameState", gameState)
	end
end

function onContact(localPlayerID, data)
	local remotePlayerName = MP.GetPlayerName(tonumber(data))
	local localPlayerName = MP.GetPlayerName(localPlayerID)
	if gameState.gameRunning and not gameState.gameEnding then
		local localPlayer = gameState.players[localPlayerName]
		local remotePlayer = gameState.players[remotePlayerName]
		if localPlayer and remotePlayer then
			if localPlayer.tagged and not remotePlayer.tagged then
				gameState.players[remotePlayerName].remoteContact = true
				gameState.players[remotePlayerName].infecter = localPlayerName
				infectPlayer(remotePlayerName)
			end
			if remotePlayer.tagged and not localPlayer.tagged then
				gameState.players[localPlayerName].localContact = true
				gameState.players[localPlayerName].infecter = remotePlayerName
				infectPlayer(localPlayerName)
			end
			if gameState.nonTaggedPlayers == 0 then 
				gameState.everyoneTagged = true
				updateClients()
			end
		end
	end
end

local function assignTeamsForRound()
	local enabled = getEnabledTeamColors()
	local playerNames = {}
	for name, pdata in pairs(gameState.players or {}) do
		if type(pdata) == "table" then playerNames[#playerNames+1] = name end
	end
	if #playerNames == 0 then return end
	shuffle(playerNames)

	local buckets = {}
	for _, c in ipairs(enabled) do buckets[c] = 0 end

	-- manual assignments first
	for _, name in ipairs(playerNames) do
		local forced = manualTeamAssignments[name]
		if forced and buckets[forced] ~= nil then
			gameState.players[name].team = forced
			buckets[forced] = buckets[forced] + 1
		end
	end

	-- fill remaining as balanced as possible
	for _, name in ipairs(playerNames) do
		if not gameState.players[name].team then
			local bestCount = nil
			local candidates = {}
			for _, c in ipairs(enabled) do
				local n = buckets[c] or 0
				if bestCount == nil or n < bestCount then
					bestCount = n
					candidates = {c}
				elseif n == bestCount then
					candidates[#candidates+1] = c
				end
			end
			local pick = candidates[math.random(1, #candidates)]
			gameState.players[name].team = pick
			buckets[pick] = (buckets[pick] or 0) + 1
		end
	end

	gameState.teamCounts = buckets
	gameState.enabledTeams = enabled
end

local function applyInitialTaggers()
	local target = clamp(tonumber(defaultInitialTaggers) or 1, 1, 64)
	local candidates = {}
	for name, pdata in pairs(gameState.players or {}) do
		if type(pdata) == "table" then candidates[#candidates+1] = name end
	end
	if #candidates == 0 then return end

	local selected = {}
	for name,_ in pairs(manualInitialTaggers) do
		if gameState.players[name] and not selected[name] then
			selected[name] = true
		end
	end

	shuffle(candidates)
	for _, name in ipairs(candidates) do
		local count = 0; for _ in pairs(selected) do count = count + 1 end
		if count >= target then break end
		selected[name] = true
	end

	local names = {}
	local taggedCount = 0
	for name,_ in pairs(selected) do
		local p = gameState.players[name]
		if p and not p.tagged then
			p.tagged = true
			p.firstTagged = true
			p.localContact = true
			p.remoteContact = true
			names[#names+1] = name
			taggedCount = taggedCount + 1
			MP.TriggerClientEvent(-1, "tag_recieveTagged", name)
		end
	end

	if taggedCount > 0 then
		gameState.TaggedPlayers = taggedCount
		gameState.nonTaggedPlayers = math.max(0, (gameState.playerCount or 0) - taggedCount)
		gameState.oneTagged = true
		MP.SendChatMessage(-1, "Initial tagger(s): " .. table.concat(names, ", "))
	end
end

local function gameSetup(time)
	gameState = {}
	gameState.players = {}
	gameState.settings = {
		greenFadeDistance = defaultGreenFadeDistance,
		ColorPulse = defaultColorPulse,
		taggerTint = defaultTaggerTint,
		distancecolor = defaultDistancecolor,
		disableResetsWhenMoving = disableResetsWhenMoving,
		maxResetMovingSpeed = maxResetMovingSpeed,
		mode = defaultMode,
		teamCount = defaultTeamCount,
		initialTaggers = defaultInitialTaggers,
		winCondition = defaultWinCondition,
		enabledTeams = getEnabledTeamColors()
		}
	local playerCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
			if not weightingArray[Player] then
				weightingArray[Player] = {}
				weightingArray[Player].games = 1
				weightingArray[Player].tags = 1
			else
				weightingArray[Player].games = weightingArray[Player].games + 1
			end

			local player = {}
			player.stats = {}
			player.stats.tagged = 0
			player.ID = ID
			player.tagged = false
			player.localContact = false
			player.remoteContact = false
			gameState.players[Player] = player
			playerCount = playerCount + 1
			--MP.TriggerClientEvent(-1, "tag_addPlayers", tostring(k))
			MP.TriggerClientEvent(-1, "tag_addPlayers", Player)
		end
	end

	if playerCount == 0 then
		MP.SendChatMessage(-1,"Failed to start, found no vehicles")
		return
	end

	gameState.playerCount = playerCount
	gameState.TaggedPlayers = 0
	gameState.nonTaggedPlayers = playerCount
	gameState.time = -5
	gameState.roundLength = time or roundLength
	gameState.endtime = -1
	gameState.oneTagged = false
	gameState.everyoneTagged = false
	gameState.gameRunning = true
	gameState.gameEnding = false
	gameState.gameEnded = false

	if defaultMode == "multiteam" then
		assignTeamsForRound()
	end
	-- Delay initial tagger reveal until round actually begins.
	gameState.pendingInitialTaggers = true

	MP.TriggerClientEventJson(-1, "tag_recieveGameState", gameState)
end

local function gameEnd(reason)
	gameState.gameEnding = true
	local taggedCount = 0
	local nonTaggedCount = 0
	local players = gameState.players
	for k,player in pairs(players) do
		if player.tagged then
			taggedCount = taggedCount + 1
		else
			nonTaggedCount = nonTaggedCount + 1
		end
	end
	if reason == "time" then
		MP.SendChatMessage(-1,"Game over,"..nonTaggedCount.." survived and "..taggedCount.." got tagged")
	elseif reason == "tagged" then
		MP.SendChatMessage(-1,"Game over, no survivors")
	elseif reason == "lastteam" then
		local wt = tostring(gameState.winningTeam or "unknown")
		MP.SendChatMessage(-1,"Game over, team "..wt.." wins!")
	elseif reason == "manual" then
		--MP.SendChatMessage(-1,"Game stopped,"..nonTaggedCount.." survived and "..taggedCount.." got tagged")
		MP.SendChatMessage(-1,"Game stopped, Everyone Looses")
		gameState.endtime = gameState.time + 10
	else
		MP.SendChatMessage(-1,"Game stopped for unknown reason,"..nonTaggedCount.." survived and "..taggedCount.." got tagged")
	end
end

local function infectRandomPlayer()
	gameState.oneTagged = false
	local players = gameState.players
	local weightRatio = 0
	for playername,player in pairs(players) do

		local tags = weightingArray[playername].tags
		local games = weightingArray[playername].games
		local playerCount = gameState.playerCount

		local weight = math.max(1,(1/((games/tags)/playerCount))*100)
		weightingArray[playername].startNumber = weightRatio
		weightRatio = weightRatio + weight
		weightingArray[playername].endNumber = weightRatio
		weightingArray[playername].weightRatio = weightRatio
		--print(playername,weightingArray[playername].endNumber - weightingArray[playername].startNumber,weightingArray[playername].startNumber , weightingArray[playername].endNumber,weightingArray[playername].tags,weightingArray[playername].games,gameState.playerCount)
	end

	local randomID = math.random(1, math.floor(weightRatio))

	for playername,player in pairs(players) do
		if randomID >= weightingArray[playername].startNumber and randomID <= weightingArray[playername].endNumber then--if count == randomID then
			if not gameState.oneTagged then
				gameState.players[playername].remoteContact = true
				gameState.players[playername].localContact = true
				gameState.players[playername].tagged = true
				gameState.players[playername].firstTagged = true

				if gameState.time == 5 then
					MP.SendChatMessage(-1,""..playername.." is first tagged!")
				else
					MP.SendChatMessage(-1,"no tagged players, "..playername.." has been randomly tagged!")
				end
				MP.TriggerClientEvent(-1, "tag_recieveTagged", playername)
				gameState.oneTagged = true
				gameState.TaggedPlayers = gameState.TaggedPlayers + 1
				gameState.nonTaggedPlayers = gameState.nonTaggedPlayers - 1
			end
		else
			weightingArray[playername].tags = weightingArray[playername].tags + 100
		end
	end
	if gameState.TaggedPlayers >= gameState.playerCount and gameState.nonTaggedPlayers == 0 then
		gameState.everyoneTagged = true
	end

	MP.TriggerClientEventJson(-1, "tag_recieveGameState", gameState)
end

local function gameStarting()
	local days, hours , minutes , seconds = seconds_to_days_hours_minutes_seconds(gameState.roundLength)
	local amount = 0
	if days then
		amount = amount + 1
	end
	if hours then
		amount = amount + 1
	end
	if minutes then
		amount = amount + 1
	end
	if seconds then
		amount = amount + 1
	end
	if days then
		amount = amount - 1
		if days == 1 then
			if amount > 1 then
				days = ""..days.." day, "
			elseif amount == 1 then
				days = ""..days.." day and "
			elseif amount == 0 then
				days = ""..days.." day "
			end
		else
			if amount > 1 then
				days = ""..days.." days, "
			elseif amount == 1 then
				days = ""..days.." days and "
			elseif amount == 0 then
				days = ""..days.." days "
			end
		end
	end
	if hours then
		amount = amount - 1
		if hours == 1 then
			if amount > 1 then
				hours = ""..hours.." hour, "
			elseif amount == 1 then
				hours = ""..hours.." hour and "
			elseif amount == 0 then
				hours = ""..hours.." hour "
			end
		else
			if amount > 1 then
				hours = ""..hours.." hours, "
			elseif amount == 1 then
				hours = ""..hours.." hours and "
			elseif amount == 0 then
				hours = ""..hours.." hours "
			end
		end
	end
	if minutes then
		amount = amount - 1
		if minutes == 1 then
			if amount > 1 then
				minutes = ""..minutes.." minute, "
			elseif amount == 1 then
				minutes = ""..minutes.." minute and "
			elseif amount == 0 then
				minutes = ""..minutes.." minute "
			end
		else
			if amount > 1 then
				minutes = ""..minutes.." minutes, "
			elseif amount == 1 then
				minutes = ""..minutes.." minutes and "
			elseif amount == 0 then
				minutes = ""..minutes.." minutes "
			end
		end
	end
	if seconds then
		if seconds == 1 then
			seconds = ""..seconds.." second "
		else
			seconds = ""..seconds.." seconds "
		end
	end

	MP.SendChatMessage(-1,"Tag game started, you have to survive for "..(days or "")..""..(hours or "")..""..(minutes or "")..""..(seconds or "").."")
end

local function gameRunningLoop()
	local players = gameState.players

	if gameState.time < 0 then
		MP.SendChatMessage(-1,"Tag game starting in "..math.abs(gameState.time).." second")

	elseif gameState.time == 0 then
		gameStarting()
		local unresponsiveString = ""
		for playername,_ in pairs(players) do
			if not gameState.players[playername].responded then
				gameState.players[playername] = "remove"
				if unresponsiveString == "" then
					unresponsiveString = unresponsiveString .. playername
				else
					unresponsiveString = unresponsiveString	.. "," .. playername
				end
			end
		end
		if unresponsiveString ~= "" then
			MP.SendChatMessage(-1,""..unresponsiveString.." did not respond and was removed from this round, rejoining the server should fix this issue")
		end
	end

	if not gameState.gameEnding and gameState.playerCount == 0 then
		gameState.gameEnding = true
		gameState.endtime = gameState.time + 2
	end

	if not gameState.gameEnding and gameState.time > 0 then
		local taggedCount = 0
		local nonTaggedCount = 0
		local playercount = 0
		for playername,player in pairs(players) do
			if player.localContact and player.remoteContact and not player.tagged then
				player.tagged = true
				MP.SendChatMessage(-1,""..playername.." has been tagged!")
				MP.TriggerClientEvent(-1, "tag_recieveTagged", playername)
			elseif player.stats and gameState.time > 5 and not player.tagged then
				if	not player.stats.survivedTime then
					player.stats.survivedTime = 5
				end
				player.stats.survivedTime = player.stats.survivedTime + 1
			end

			if player.tagged then
				taggedCount = taggedCount + 1
			elseif not player.tagged then
				nonTaggedCount = nonTaggedCount + 1
			end
			playercount = playercount + 1
		end
		if defaultMode == "multiteam" and defaultWinCondition == "lastteam" then
			local aliveTeams, teamName = aliveSurvivorTeams()
			if aliveTeams <= 1 and teamName then
				gameState.winningTeam = teamName
				gameEnd("lastteam")
				gameState.endtime = gameState.time + 10
			end
		end

		if taggedCount >= gameState.playerCount and nonTaggedCount == 0 then
			gameState.everyoneTagged = true
		end
		gameState.TaggedPlayers = taggedCount
		gameState.nonTaggedPlayers = nonTaggedCount
		gameState.playerCount = playercount

		if gameState.time >= 5 and gameState.pendingInitialTaggers then
			applyInitialTaggers()
			gameState.pendingInitialTaggers = false
		end

		if gameState.time >= 5 and taggedCount == 0 and not gameState.oneTagged then
			infectRandomPlayer()
		end
	end

	if not gameState.gameEnding and gameState.time == gameState.roundLength then
		gameEnd("time")
		gameState.endtime = gameState.time + 10
	elseif not gameState.gameEnding and gameState.everyoneTagged == true then
		gameEnd("tagged")
		gameState.endtime = gameState.time + 10
	elseif gameState.gameEnding and gameState.time == gameState.endtime then
		gameState.gameRunning = false
		--MP.TriggerClientEvent(-1, "tag_resetTagged", "data")

		gameState = {}
		gameState.players = {}
		gameState.everyoneTagged = false
		gameState.gameRunning = false
		gameState.gameEnding = false
		gameState.gameEnded = true

		--MP.TriggerClientEventJson(-1, "tag_recieveGameState", gameState)
	end
	if gameState.gameRunning then
		gameState.time = gameState.time + 1
	end

	updateClients()
end

autoStart = false
local autoStartTimer = 0

local autoStartWaitInSeconds = 600

function timer()
	if gameState.gameRunning then
		gameRunningLoop()
	elseif autoStart and MP.GetPlayerCount() > 1 then
		autoStartTimer = autoStartTimer + 1
		if autoStartTimer >= autoStartWaitInSeconds then
			autoStartTimer = 0
			gameSetup()
		end
	end
end

MP.RegisterEvent("onContact", "onContact")

MP.RegisterEvent("second", "timer")
MP.CancelEventTimer("counter")
MP.CancelEventTimer("second")
MP.CreateEventTimer("second",1000)



local commands = {}

local function help(sender_id, sender_name, message, variable)
	MP.SendChatMessage(sender_id,"Tag command list")
	MP.SendChatMessage(sender_id,"Normalized syntax:")
	MP.SendChatMessage(sender_id,"  /tag start [minutes]")
	MP.SendChatMessage(sender_id,"  /tag stop")
	MP.SendChatMessage(sender_id,"  /tag reset")
	MP.SendChatMessage(sender_id,"  /tag set mode classic|multiteam")
	MP.SendChatMessage(sender_id,"  /tag set teamCount <2..6>")
	MP.SendChatMessage(sender_id,"  /tag set taggers <count>")
	MP.SendChatMessage(sender_id,"  /tag set winCondition classic|lastteam")
	MP.SendChatMessage(sender_id,"  /tag set gameLength <minutes>")
	MP.SendChatMessage(sender_id,"  /tag set greenFadeDist <meters>")
	MP.SendChatMessage(sender_id,"  /tag set filterIntensity <0..1>")
	MP.SendChatMessage(sender_id,"  /tag set maxResetSpeed <speed>")
	MP.SendChatMessage(sender_id,"  /tag toggle colorPulse|taggerTint|resetAtSpeedAllowed")
	MP.SendChatMessage(sender_id,"  /tag teams random|set <username> <color>|clear <username>|list")
	MP.SendChatMessage(sender_id,"  /tag taggers add|remove <username>|clear|list")

	local keys = {}
	for k,_ in pairs(commands) do table.insert(keys, k) end
	table.sort(keys)
	for _,k in ipairs(keys) do
		local v = commands[k]
		local usage = v.usage and (v.usage..",") or ""
		MP.SendChatMessage(sender_id,"/tag "..k..", "..usage.." "..v.tooltip.."")
	end
end

local function start(sender_id, sender_name, message, value)
	if not gameState.gameRunning then
		if value then value = value*60 end
		gameSetup(value)
	else
		MP.SendChatMessage(sender_id,"gamestart failed, game already running")
	end
end

local function stop(sender_id)
	if gameState.gameRunning then
		gameEnd("manual")
	else
		MP.SendChatMessage(sender_id,"gamestop failed, game not running")
	end
end

local function gameLength(sender_id, sender_name, message, value)
	if value then
		roundLength = value*60
		MP.SendChatMessage(sender_id,"set game length to "..value.."")

	else
		MP.SendChatMessage(sender_id,"setting roundLength failed, no value")
	end
end

local function reset(sender_id, sender_name, message, variable)
	weightingArray = {}
end

local function greenFadeDist(sender_id, sender_name, message, value)
	if value then
		defaultGreenFadeDistance = value
		if gameState.settings then
			gameState.settings.greenFadeDistance = defaultGreenFadeDistance
		end
		MP.SendChatMessage(sender_id,"set greenFadeDist to "..value.."")

	else
		MP.SendChatMessage(sender_id,"setting greenFadeDist failed, no value")
	end
end

local function ColorPulse(sender_id, sender_name, message, value)
	if defaultColorPulse then
		defaultColorPulse = false
		MP.SendChatMessage(sender_id,"setting ColorPulse to false")
	else
		defaultColorPulse = true
		MP.SendChatMessage(sender_id,"setting ColorPulse to true")
	end
	if gameState.settings then
		gameState.settings.ColorPulse = defaultColorPulse
	end
end

local function taggerTint(sender_id, sender_name, message, value)
	if defaultTaggerTint then
		defaultTaggerTint = false
		MP.SendChatMessage(sender_id,"setting tagger tint to false")
	else
		defaultTaggerTint = true
		MP.SendChatMessage(sender_id,"setting tagger tint to true")
	end
	if gameState.settings then
		gameState.settings.taggerTint = defaultTaggerTint
	end
end

local function filterIntensity(sender_id, sender_name, message, value)
	if value then
		defaultDistancecolor = value
		if gameState.settings then
			gameState.settings.distancecolor = defaultDistancecolor
		end
		MP.SendChatMessage(sender_id,"set filterIntensity to "..value.."")
	else
		MP.SendChatMessage(sender_id,"setting filterIntensity failed, no value")
	end
end

local function resetToggle(sender_id, sender_name, message, value)
	disableResetsWhenMoving = not disableResetsWhenMoving
	if gameState.settings then
		gameState.settings.disableResetsWhenMoving = disableResetsWhenMoving
	end
	if disableResetsWhenMoving then
		MP.SendChatMessage(sender_id,"Resetting is now restricted")
	else
		MP.SendChatMessage(sender_id,"Resetting is now allowed")
	end
end

local function setResetSpeed(sender_id, sender_name, message, value)
	if value then
		maxResetMovingSpeed = value
		if gameState.settings then
			gameState.settings.maxResetMovingSpeed = maxResetMovingSpeed
		end
		MP.SendChatMessage(sender_id,"set Max Reset Speed to "..value.."")
	else
		MP.SendChatMessage(sender_id,"setting Max Reset Speed failed, no value")
	end
end

local function status(sender_id)
	local running = gameState.gameRunning and true or false
	local phase = "idle"
	if running then
		if gameState.gameEnding then phase = "ending"
		elseif (gameState.time or 0) < 0 then phase = "countdown"
		else phase = "round" end
	end
	MP.SendChatMessage(sender_id, "Status: running="..tostring(running).." phase="..phase)
	MP.SendChatMessage(sender_id, "Players: tagged="..tostring(gameState.TaggedPlayers or 0).." untagged="..tostring(gameState.nonTaggedPlayers or 0).." total="..tostring(gameState.playerCount or 0))
	MP.SendChatMessage(sender_id, "Config: roundLength="..tostring((roundLength or 0)/60).."min greenFadeDist="..tostring(defaultGreenFadeDistance).." filterIntensity="..tostring(defaultDistancecolor))
	MP.SendChatMessage(sender_id, "Config: colorPulse="..tostring(defaultColorPulse).." taggerTint="..tostring(defaultTaggerTint).." resetRestrict="..tostring(disableResetsWhenMoving).." maxResetSpeed="..tostring(maxResetMovingSpeed))
	MP.SendChatMessage(sender_id, "Mode: "..tostring(defaultMode).." teamCount="..tostring(defaultTeamCount).." initialTaggers="..tostring(defaultInitialTaggers).." winCondition="..tostring(defaultWinCondition))
	if defaultMode == "multiteam" then
		local counts = getSurvivorTeamCounts()
		local enabled = getEnabledTeamColors()
		local parts = {}
		for _, c in ipairs(enabled) do
			parts[#parts+1] = c .. ":" .. tostring(counts[c] or 0)
		end
		MP.SendChatMessage(sender_id, "Survivors by team: " .. table.concat(parts, " | "))
	end
end

local function cmdTeams(sender_id, args)
	local action = (args[2] or ""):lower()
	if action == "random" then
		manualTeamAssignments = {}
		defaultTeamCount = #TEAM_COLORS
		MP.SendChatMessage(sender_id, "Cleared manual team assignments. Next round will auto-balance across all team colors (teamCount="..tostring(defaultTeamCount)..").")
		return
	end
	if action == "set" then
		local user = resolvePlayerNameByQuery(args[3] or "")
		local color = (args[4] or ""):lower()
		local colorIndex = nil
		for i, c in ipairs(TEAM_COLORS) do if c == color then colorIndex = i break end end
		if not user then MP.SendChatMessage(sender_id, "teams set: username not found") return end
		if not colorIndex then MP.SendChatMessage(sender_id, "teams set: invalid color") return end
		if defaultTeamCount < colorIndex then
			defaultTeamCount = colorIndex
			MP.SendChatMessage(sender_id, "Expanded teamCount to "..tostring(defaultTeamCount).." to enable color "..color)
		end
		manualTeamAssignments[user] = color
		MP.SendChatMessage(sender_id, "Assigned "..user.." to team "..color.." (next round)")
		return
	end
	if action == "clear" then
		local user = resolvePlayerNameByQuery(args[3] or "")
		if not user then MP.SendChatMessage(sender_id, "teams clear: username not found") return end
		manualTeamAssignments[user] = nil
		MP.SendChatMessage(sender_id, "Cleared team assignment for "..user)
		return
	end
	if action == "list" then
		MP.SendChatMessage(sender_id, "Manual team assignments:")
		local any = false
		for name, color in pairs(manualTeamAssignments) do
			any = true
			MP.SendChatMessage(sender_id, "  "..name.." -> "..color)
		end
		if not any then MP.SendChatMessage(sender_id, "  (none)") end
		return
	end
	MP.SendChatMessage(sender_id, "Usage: /tag teams random|set <username> <color>|clear <username>|list")
end

local function cmdTaggers(sender_id, args)
	local action = (args[2] or ""):lower()
	if action == "add" then
		local user = resolvePlayerNameByQuery(args[3] or "")
		if not user then MP.SendChatMessage(sender_id, "taggers add: username not found") return end
		manualInitialTaggers[user] = true
		MP.SendChatMessage(sender_id, "Added manual tagger: "..user.." (next round)")
		return
	end
	if action == "remove" then
		local user = resolvePlayerNameByQuery(args[3] or "")
		if not user then MP.SendChatMessage(sender_id, "taggers remove: username not found") return end
		manualInitialTaggers[user] = nil
		MP.SendChatMessage(sender_id, "Removed manual tagger: "..user)
		return
	end
	if action == "clear" then
		manualInitialTaggers = {}
		MP.SendChatMessage(sender_id, "Cleared manual taggers")
		return
	end
	if action == "list" then
		MP.SendChatMessage(sender_id, "Manual taggers:")
		local any=false
		for name,_ in pairs(manualInitialTaggers) do any=true; MP.SendChatMessage(sender_id, "  "..name) end
		if not any then MP.SendChatMessage(sender_id, "  (none)") end
		return
	end
	MP.SendChatMessage(sender_id, "Usage: /tag taggers add|remove <username> | clear | list")
end

commands = {
	["help"] = {
		["function"] = help,
		["tooltip"] = "Displays list of available commands"
	},
	["status"] = {
		["function"] = status,
		["tooltip"] = "Shows current round state and settings"
	},
	["start"] = {
		["function"] = start,
		["tooltip"] = "starts tag game",
		["usage"] = "optional time in minutes"
	},
	["stop"] = {
		["function"] = stop,
		["tooltip"] = "stops tag game",
	},
	["reset"] = {
		["function"] = reset,
		["tooltip"] = "resets randomizer weights",
	},
	["game length set"] = {
		["function"] = gameLength,
		["tooltip"] = "sets the length of the round",
		["usage"] = "minutes"
	},
	["greenFadeDist set"] = {
		["function"] = greenFadeDist,
		["tooltip"] = "Adjusts how close in meters an tagged car needs to be for the screen to start going green",
		["usage"] = "meters"
	},
	["filterIntensity set"] = {
		["function"] = filterIntensity,
		["tooltip"] = "Sets how intense the vignetting effect is",
		["usage"] = "0 to 1"
	},
	["ColorPulse toggle"] = {
		["function"] = ColorPulse,
		["tooltip"] = "Enabling this makes the tagged cars pulse between green and the original color of the car",
	},
	["tagger tint toggle"] = {
		["function"] = taggerTint,
		["tooltip"] = "This toggles on or off the vignetting effect on tagged players",
	},
	["ResetAtSpeedAllowed toggle"] = {
		["function"] = resetToggle,
		["tooltip"] = "This toggles whether players can reset at speed",
	},
	["MaxResetSpeed set"] = {
		["function"] = setResetSpeed,
		["tooltip"] = "Sets the highest speed where resets are allowed",
	},
}

--Chat Commands
function tagChatMessageHandler(sender_id, sender_name, message)
	local msgStart = string.match(message,"[^%s]+")
	if msgStart == "/tag" then
		local raw = string.sub(message, string.len(msgStart) + 2)
		raw = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if raw == "" then
			help(sender_id)
			return 1
		end

		local args = {}
		for w in raw:gmatch("%S+") do table.insert(args, w) end
		local first = (args[1] or ""):lower()

		local commandStringFinal = nil
		local variable = nil

		-- New normalized syntax: /tag set <setting> <value>
		if first == "set" then
			local setting = (args[2] or ""):lower()
			if setting == "mode" then
				local m = (args[3] or ""):lower()
				if m ~= "classic" and m ~= "multiteam" then
					MP.SendChatMessage(sender_id, "Usage: /tag set mode classic|multiteam")
					return 1
				end
				defaultMode = m
				MP.SendChatMessage(sender_id, "Set mode to "..m)
				return 1
			elseif setting == "teamcount" then
				local n = tonumber(args[3])
				if not n then MP.SendChatMessage(sender_id, "Usage: /tag set teamCount <2-6>") return 1 end
				defaultTeamCount = clamp(math.floor(n), 2, #TEAM_COLORS)
				MP.SendChatMessage(sender_id, "Set teamCount to "..tostring(defaultTeamCount))
				return 1
			elseif setting == "taggers" then
				local n = tonumber(args[3])
				if not n then MP.SendChatMessage(sender_id, "Usage: /tag set taggers <count>") return 1 end
				defaultInitialTaggers = clamp(math.floor(n), 1, 64)
				MP.SendChatMessage(sender_id, "Set initial taggers to "..tostring(defaultInitialTaggers))
				return 1
			elseif setting == "wincondition" then
				local wc = (args[3] or ""):lower()
				if wc ~= "classic" and wc ~= "lastteam" then
					MP.SendChatMessage(sender_id, "Usage: /tag set winCondition classic|lastteam")
					return 1
				end
				defaultWinCondition = wc
				MP.SendChatMessage(sender_id, "Set winCondition to "..wc)
				return 1
			end

			variable = tonumber(args[3])
			local setMap = {
				["gamelength"] = "game length set",
				["greenfadedist"] = "greenFadeDist set",
				["filterintensity"] = "filterIntensity set",
				["maxresetspeed"] = "MaxResetSpeed set",
			}
			commandStringFinal = setMap[setting]
			if not commandStringFinal then
				MP.SendChatMessage(sender_id, "Unknown /tag set key. Try: mode, teamCount, taggers, winCondition, gameLength, greenFadeDist, filterIntensity, maxResetSpeed")
				return 1
			end
			if not variable then
				MP.SendChatMessage(sender_id, "Missing numeric value for /tag set " .. tostring(setting))
				return 1
			end
		elseif first == "teams" then
			cmdTeams(sender_id, args)
			return 1
		elseif first == "taggers" then
			cmdTaggers(sender_id, args)
			return 1
		elseif first == "toggle" then
			local setting = (args[2] or ""):lower()
			local toggleMap = {
				["colorpulse"] = "ColorPulse toggle",
				["taggertint"] = "tagger tint toggle",
				["resetatspeedallowed"] = "ResetAtSpeedAllowed toggle",
			}
			commandStringFinal = toggleMap[setting]
			if not commandStringFinal then
				MP.SendChatMessage(sender_id, "Unknown /tag toggle key. Try: colorPulse, taggerTint, resetAtSpeedAllowed")
				return 1
			end
		else
			-- Backward compatibility (old command phrases still work)
			local commandstring, num = string.match(raw, "^(.+) (%-?%d*%.?%d+)$")
			commandStringFinal = commandstring or raw
			variable = tonumber(num)
		end

		if commands[commandStringFinal] then
			commands[commandStringFinal]["function"](sender_id, sender_name, message, variable)
		else
			MP.SendChatMessage(sender_id, "command not found, type /tag help for a list of tag commands")
		end
		return 1
	elseif string.sub(message,1,5) == "/help" then
		MP.SendChatMessage(sender_id,"type /tag help for a list of tag commands")
		return 1
	end
end

local function markPlayerRemovedById(playerID)
	if not (gameState.gameRunning and gameState.players) then return end
	for name, pdata in pairs(gameState.players) do
		if type(pdata) == "table" and tonumber(pdata.ID) == tonumber(playerID) then
			gameState.players[name] = "remove"
			return
		end
	end

	local playerName = MP.GetPlayerName(playerID)
	if playerName and gameState.players[playerName] then
		gameState.players[playerName] = "remove"
	end
end

function onPlayerDisconnect(playerID)
	markPlayerRemovedById(playerID)
end

function onVehicleDeleted(playerID,vehicleID)
	if not gameState.gameRunning then return end
	local vehicles = MP.GetPlayerVehicles(playerID)
	if not vehicles or next(vehicles) == nil then
		markPlayerRemovedById(playerID)
	end
end

MP.TriggerClientEventJson(-1, "tag_recieveGameState", gameState)
MP.TriggerClientEvent(-1, "tag_resetTagged", "data")

MP.RegisterEvent("onChatMessage", "tagChatMessageHandler")
MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
MP.RegisterEvent("onPlayerJoin", "requestGameState")

