-- Contract HUD for FS22
--
-- This mod displays completion of active contracts for a player farm.
-- If 0 active contracts then hud is hidden.
--
-- Author: StingerTopGun, the.geremy

ContractHUD = {}
ContractHUD.eventName = {}
ContractHUD.ModName = g_currentModName
ContractHUD.ModDirectory = g_currentModDirectory
ContractHUD.Version = "1.2.1.0"

ContractHUD.Colors = {}
ContractHUD.Colors[1] = {'col_white', {1, 1, 1, 1}}
ContractHUD.Colors[2] = {'col_black', {0, 0, 0, 0.7}}
ContractHUD.Colors[3] = {'col_grey', {0.7411, 0.7450, 0.7411, 1}}
ContractHUD.Colors[4] = {'col_blue', {0.0044, 0.15, 0.6376, 1}}
ContractHUD.Colors[5] = {'col_red', {0.7835, 0.0034, 0.0030, 1}}
ContractHUD.Colors[6] = {'col_green', {0.0395, 0.2015, 0.0242, 1}}
ContractHUD.Colors[7] = {'col_cyan', {0.0003, 0.5647, 0.9822, 1}}
ContractHUD.Colors[8] = {'col_orange', {1.0000, 0.1413, 0.0000, 1}}
ContractHUD.Colors[9] = {'col_dgreen', {0.1062, 0.5234, 0.1450, 1}}
ContractHUD.Colors[10] = {'col_sorange', {1.0000, 0.1830, 0.0210, 1}}
ContractHUD.Colors[11] = {'col_green2', {0.5059, 0.7647, 0.1961, 1}}
ContractHUD.Colors[12] = {'col_green3', {0.391, 0.521, 0.366, 1}}
ContractHUD.Colors[13] = {'col_cyan2', {0.0, 0.7764, 0.9921, 1}}
ContractHUD.Colors[14] = {'alert_color', {0.6662, 0.3839, 0.5481, 1}}
ContractHUD.Colors[15] = {'under_minute_color', {0.9411, 0.1960, 0.2456, 1}}

ContractHUD.background = 'dataS/menu/hud/ui_elements.png'
ContractHUD.overlay = nil
ContractHUD.overlayIsRendered = false
ContractHUD.maxTextWidth = 0
ContractHUD.displayModeChanged = false
ContractHUD.activeMissons = 0
ContractHUD.baseXchanged = false
ContractHUD.baseX = 0

-- settings secton --
ContractHUD.HeadlineColor = 7 -- put here color index from above
ContractHUD.MissionTextColor = 1 -- default active mission color, put here color index from above
ContractHUD.MissionAlertColor = 14
ContractHUD.MissionUnderMinuteColor = 15
ContractHUD.FieldDisplay = false -- false => Field, true => Field No.
ContractHUD.TransportDisplay = false -- false => Supply, true => Transporting
ContractHUD.displayDecimals = true -- display or not display decimal in percentage => 8 % or 8.2 %
ContractHUD.shortTime = true -- true => 15:40, false => 15:40:26
ContractHUD.alertTime = 60 -- alert time in minutes, when remianing time less than specified minutes, change color of contract to alert_color
-- !!! To change these, may have unexpected effects !!!
ContractHUD.seperationWidth = 20 -- value in pixels, is scaled to match screen size
ContractHUD.defaultOverlayWidth = 0.06
ContractHUD.horizontalMargin = 0.0032
ContractHUD.verticalMargin = 0.0008
-- ContractHUD.ColorSuccess = 9 -- not used at the moment
-- ContractHUD.ColorFail = 5 -- not used at the moment
-- end of settings section --

-- displayMode
-- 0 - field mission - display field number and field work type and also crop type if available, if progress display bar (default)
--   - transport mission - display mission type and crop type, if progress display bar instead of remaining time (default)
-- 1 - field mission - display field number and field work type and also crop type if available, if progress display bar
--   - transport mission - display mission type and crop type, if progress display % number instead of required amount
-- 2 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
--   - transport mission - display mission type and crop type, if progress display % number and bar instead of required amount
-- 3 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
--   - transport mission - display crop type, if progress display % number instead of required amount also display destination
-- 4 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
--   - transport mission - display crop type, if progress display % number instead of required amount also display destination and remianing time
-- 5 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
--   - transport mission - display crop type, if progress display remianing amount instead of required amount also display destination and remianing time
-- 6 = hide HUD
ContractHUD.displayMode = 5 -- default display mode


function ContractHUD:registerActionEvents()
	g_inputBinding:registerActionEvent('CH_toggle_displaymode', self, ContractHUD.toggleDisplayMode, false, true, false, true)
end

--function ContractHUD:onLoad(savegame)
--end

function ContractHUD:update(dt)
	-- if zero active missions, check for new active missions (the.geremy)
	if ContractHUD.activeMissons == 0 then
		local countContracts = 0

		for _, contract in ipairs(g_missionManager.missions) do
			if contract.status >= 1 and g_currentMission.player.farmId == contract.farmId then  -- only show active contracts, 0 is inactive i guess, and only from current farm
				countContracts = countContracts + 1
			end
		end

		ContractHUD.activeMissons = countContracts
	end
end

function ContractHUD:draw()
	-- added condition to display info only if any active mission (the.geremy)
	if g_client ~= nil and g_currentMission.hud.isVisible and ContractHUD.displayMode ~= 6 and ContractHUD.activeMissons ~= 0 and not g_noHudModeEnabled and not g_sleepManager:getIsSleeping() then
		local gameInfoDisplay = g_currentMission.hud.gameInfoDisplay

		local posX = gameInfoDisplay.backgroundOverlay.overlay.x
		local posY = gameInfoDisplay.backgroundOverlay.overlay.y
		local textSize = g_currentMission.inGameMenu.hud.inputHelp.helpTextSize * 1.1 -- add 10%
		posY = posY + gameInfoDisplay.backgroundOverlay.overlay.height - textSize
		posX = posX - ( g_currentMission.inGameMenu.hud.inputHelp.helpTextOffsetY * 2 )

		if g_modIsLoaded.FS22_limitedDailyIncome then
			posY = posY - gameInfoDisplay:getHeight() - gameInfoDisplay:scalePixelToScreenHeight(ContractHUD.seperationWidth)
		end

		local outputText = ContractHUD:translate("headline") .. ": " .. ContractHUD.activeMissons
		local lineHeight = getTextHeight(textSize, outputText)
		local completion = 0
		local countContracts = 0

		local field_text = ""
		local field_work = ""
		local textColor

		-- for boxOverlay
		local baseX = posX
		local baseY = gameInfoDisplay.backgroundOverlay.overlay.y + gameInfoDisplay.backgroundOverlay.overlay.height
		local maxTextWidth = 0.0

		if ContractHUD.baseX ~= baseX then
			ContractHUD.baseXchanged = true
			ContractHUD.baseX = baseX
		end

		-- print haadline
		ContractHUD:renderText(posX, posY, textSize, outputText, false, ContractHUD.HeadlineColor)--FSBaseMission.INGAME_NOTIFICATION_INFO) --ContractHUD.HeadlineColor)
		maxTextWidth = getTextWidth(textSize, outputText)
		posY = posY - textSize  -- shift one line down because of headline

		for _, contract in ipairs(g_missionManager.missions) do
			if contract.status >= 1 and g_currentMission.player.farmId == contract.farmId then  -- only show active contracts, 0 is inactive i guess, and only from current farm

				-- handle color and completion
				if contract.status == 2 and contract.success == true then  -- contract finished, set completion to 100% and text green
					completion = 1
					textColor = FSBaseMission.INGAME_NOTIFICATION_OK --ContractHUD.ColorSuccess  -- green
				elseif contract.status == 2 and contract.success == false then  -- contract failed
					completion = contract.completion
					textColor = FSBaseMission.INGAME_NOTIFICATION_CRITICAL --ContractHUD.ColorFail  -- red
				else  -- contract active, get current completion and set text color
					completion = contract.completion
					if contract.type.name == "supplyTransport" then
						if ContractHUD:getRemainingTime(contract, false) == 0 then -- when less than minute it will return 0
							textColor = ContractHUD.MissionUnderMinuteColor
						elseif ContractHUD:getRemainingTime(contract, false) <= ContractHUD.alertTime then
							textColor =  ContractHUD.MissionAlertColor
						else
							textColor = ContractHUD.MissionTextColor
						end
					else
						textColor = ContractHUD.MissionTextColor
					end
				end

				-- handle field_text also for supplyTransport contract
				if contract.type.name == "supplyTransport" then -- check if supplyTransport contract
					field_text = ContractHUD:translate("transport") --g_i18n:getText("CH_supply")
				else
					field_text = ContractHUD:translate("field_no") .. " " .. contract.field.fieldId
				end

				-- add info about field work or fill type if supplyTransport contract
				if contract.type.name == "supplyTransport" then -- check if supplyTransport contract
					field_work = ContractHUD:getFillTypeTitle(contract.fillType) -- fillType has only index, we need to change it to field type name, already translated
					-- contracted liters contract.contractLiters
				elseif contract.type.name ~= nil then
					field_work = ContractHUD:firstToUpper(ContractHUD:translate(contract.type.name)) -- make first letter Upper case and translate, other type missions like sow, fertilize, harvest....
				else
					field_work = "N/A"
				end

				if ContractHUD.displayMode == 0 then
					if contract.type.name == "supplyTransport" then
						if completion == 0 then -- when 0%, display remaining time
							outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getRemainingTime(contract)
						else -- else progress bar
							outputText = field_text .. " - " .. field_work .. " " .. ContractHUD:buildProgressBar(completion)
						end
					else -- other then supplyTransport contracts
						if completion == 0 then -- when 0%, display fruit type title
							if contract.type.name == "sow" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFruitTypeName(contract.fruitType)
							elseif contract.type.name == "harvest" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFillTypeTitle(contract.fillType)
							else
								outputText = field_text .. " - " .. field_work
							end
						else -- else progress bar
							outputText = field_text .. " " .. ContractHUD:buildProgressBar(completion)
						end
					end
				elseif ContractHUD.displayMode == 1 then
					if contract.type.name == "supplyTransport" then
						if completion == 0 then -- when 0%, display contracted liters
							outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(contract.contractLiters, true, false)
						else -- else display percentage
							outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(completion, false, true)
						end
					else -- other then supplyTransport contracts
						if completion == 0 then -- when 0%, display fruit type title
							if contract.type.name == "sow" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFruitTypeName(contract.fruitType)
							elseif contract.type.name == "harvest" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFillTypeTitle(contract.fillType)
							else
								outputText = field_text .. " - " .. field_work
							end
						else -- else display percentage
							outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true)
						end
					end
				elseif ContractHUD.displayMode == 2 then
					if contract.type.name == "supplyTransport" then
						if completion == 0 then -- when 0%, display contracted liters
							outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(contract.contractLiters, true, false)
						else -- else display percentage and bar
							outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " " .. ContractHUD:buildProgressBar(completion)
						end
					else -- other then supplyTransport contracts
						if completion == 0 then -- when 0%, display fruit type title
							if contract.type.name == "sow" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFruitTypeName(contract.fruitType)
							elseif contract.type.name == "harvest" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFillTypeTitle(contract.fillType)
							else
								outputText = field_text .. " - " .. field_work
							end
						else -- else display percentage and bar
							outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " " .. ContractHUD:buildProgressBar(completion)
						end
					end
				elseif ContractHUD.displayMode == 3 then
					if contract.type.name == "supplyTransport" then
						if completion == 0 then -- when 0%, display required amount
							outputText = field_work .. " (" .. ContractHUD:formatNumber(contract.contractLiters, true, false) .. ") => " .. contract.sellingStation.uiName
						else -- else display percentage and destination
							outputText = field_work .. " (" .. ContractHUD:formatNumber(completion, false, true) .. ") => " .. contract.sellingStation.uiName
						end
					else -- other then supplyTransport contracts
						if completion == 0 then -- when 0%, display fruit type title
							if contract.type.name == "sow" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFruitTypeName(contract.fruitType)
							elseif contract.type.name == "harvest" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFillTypeTitle(contract.fillType)
							else
								outputText = field_text .. " - " .. field_work
							end
						else -- else display percentage and bar
							outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " " .. ContractHUD:buildProgressBar(completion)
						end
					end
				elseif ContractHUD.displayMode == 4 then --contract.deliveredLiters
					if contract.type.name == "supplyTransport" then
						if completion == 0 then -- when 0%, display required amount
							outputText = field_work .. " (" .. ContractHUD:formatNumber(contract.contractLiters, true, false) .. ") => " .. contract.sellingStation.uiName  .. " (" .. ContractHUD:getRemainingTime(contract) .. ")"
						else -- else display percentage and destination and remianing time
							outputText = field_work .. " (" .. ContractHUD:formatNumber(completion, false, true) .. ") => " .. contract.sellingStation.uiName .. " (" .. ContractHUD:getRemainingTime(contract) .. ")"
						end
					else -- other then supplyTransport contracts
						if completion == 0 then -- when 0%, display fruit type title
							if contract.type.name == "sow" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFruitTypeName(contract.fruitType)
							elseif contract.type.name == "harvest" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFillTypeTitle(contract.fillType)
							else
								outputText = field_text .. " - " .. field_work
							end
						else -- else display percentage and bar
							outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " " .. ContractHUD:buildProgressBar(completion)
						end
					end
				elseif ContractHUD.displayMode == 5 then
					if contract.type.name == "supplyTransport" then
						if contract.status == 2 and contract.success == true then
							outputText = field_text .. " (" .. field_work .. ") => " .. contract.sellingStation.uiName .. " (" .. g_currentMission.hud.l10n.texts.fieldJob_finished .. ")"
						elseif contract.status == 2 and contract.success == false then
							outputText = field_text .. " (" .. field_work .. ") => " .. contract.sellingStation.uiName .. " (" .. g_currentMission.hud.l10n.texts.fieldJob_failed .. ")"
						elseif completion == 0 then -- when 0%, display required amount
							outputText = field_work .. " (" .. ContractHUD:formatNumber(contract.contractLiters, true, false) .. ") => " .. contract.sellingStation.uiName  .. " (" .. ContractHUD:getRemainingTime(contract) .. ")"
						else -- else display remianing amount, destination and remianing time
							outputText = field_work .. " (" .. ContractHUD:formatNumber((contract.contractLiters - contract.deliveredLiters), true, false) .. ") => " .. contract.sellingStation.uiName .. " (" .. ContractHUD:getRemainingTime(contract) .. ")"
						end
					else -- other then supplyTransport contracts
						if contract.status == 2 and contract.success == true then
							outputText = field_text .. " - " .. field_work .. " (" .. g_currentMission.hud.l10n.texts.fieldJob_finished .. ")"
						elseif contract.status == 2 and contract.success == false then
							outputText = field_text .. " - " .. field_work .. " (" .. g_currentMission.hud.l10n.texts.fieldJob_failed .. ")"
						elseif completion == 0 then -- when 0%, display fruit type title
							if contract.type.name == "sow" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFruitTypeName(contract.fruitType)
							elseif contract.type.name == "harvest" then
								outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getFillTypeTitle(contract.fillType)
							else
								outputText = field_text .. " - " .. field_work
							end
						else -- else display percentage and bar
							outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " " .. ContractHUD:buildProgressBar(completion)
						end
					end
				end

				ContractHUD:renderText(posX, posY, textSize, outputText, false, textColor)

				posY = posY - textSize  -- shift one line down

				-- handle counting
				countContracts = countContracts + 1

				-- get max width of the text
				if maxTextWidth < getTextWidth(textSize, outputText)  then
					maxTextWidth = getTextWidth(textSize, outputText)
				end
			end
		end

		local overlayX = 0
		local overlayY = 0
		local overlayWidth = math.max(maxTextWidth + ContractHUD.horizontalMargin * 2, ContractHUD.defaultOverlayWidth)
		local overlayHeight = math.max(textSize * (countContracts + 1) + ContractHUD.verticalMargin + g_currentMission.inGameMenu.hud.inputHelp.helpTextOffsetY, gameInfoDisplay.backgroundOverlay.overlay.height)

		overlayX = baseX - overlayWidth + ContractHUD.horizontalMargin
		overlayY = baseY - overlayHeight

		if g_modIsLoaded.FS22_limitedDailyIncome then
			overlayY = overlayY - gameInfoDisplay:getHeight() - gameInfoDisplay:scalePixelToScreenHeight(ContractHUD.seperationWidth)
		end

		-- draw overlay if not exists
		if not ContractHUD.overlayIsRendered then
			ContractHUD.overlay = ContractHUD.createImageOverlay(ContractHUD.background, overlayX, overlayY, overlayWidth, overlayHeight)
			ContractHUD.overlay:setUVs(g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.uvs)
			ContractHUD.overlay:setColor(unpack(self.Colors[2][2]))
			gameInfoDisplay:addChild(ContractHUD.overlay)
			ContractHUD.overlayIsRendered = true

		elseif math.abs(ContractHUD.maxTextWidth - maxTextWidth) > ContractHUD.horizontalMargin/2 -- when maxTextWidth change more than half of the horizontal margin
			  or ContractHUD.activeMissons ~= countContracts -- when active contract count changed
			  or ContractHUD.displayModeChanged -- when display mode changed
			  or ContractHUD.baseXchanged -- when weather is about to change
			then -- move or adjust size of overlay

			ContractHUD.overlay:setPosition(overlayX, overlayY)
			ContractHUD.overlay:setDimension(overlayWidth, overlayHeight)

			ContractHUD.displayModeChanged = false
			ContractHUD.baseXchanged = false
		end

		ContractHUD.activeMissons = countContracts
		ContractHUD.maxTextWidth = maxTextWidth
	else
		if ContractHUD.overlayIsRendered then
			ContractHUD.overlay:delete()
			ContractHUD.overlayIsRendered = false
		end

	end
end

function ContractHUD.createImageOverlay(texturePath, baseX, baseY, baseWidth, baseHeight)
	return HUDElement.new(Overlay.new(texturePath, baseX, baseY, baseWidth, baseHeight))
end

function ContractHUD:translate(text)
	local result = ""

	if  text == "headline" then
		result = ContractHUD:firstToUpper(g_currentMission.hud.l10n.texts.fieldJob_active .. " " .. g_currentMission.hud.l10n.texts.ui_ingameMenuContracts)
		--result = g_currentMission.hud.l10n.texts.ui_pendingMissions
	elseif text == "field_no" then
		result = ContractHUD.FieldDisplay and g_currentMission.hud.l10n.texts.ui_fieldNo or g_i18n:getText("CH_field")
	elseif text == "mow_bale" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_baling
	elseif text == "plow" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_plowing
	elseif text == "cultivate" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_cultivating
	elseif text == "sow" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_sowing
	elseif text == "harvest" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_harvesting
	elseif text == "weed" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_weeding
	elseif text == "spray" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_spraying
	elseif text == "fertilize" then
		result = g_currentMission.hud.l10n.texts.fieldJob_jobType_fertilizing
	elseif text == "transport" then
		result = ContractHUD.TransportDisplay and g_currentMission.hud.l10n.texts.fieldJob_jobType_transporting or g_i18n:getText("CH_supply")
	else
		result = "N/A"
	end

	return result
end

function ContractHUD:formatNumber(number, is_whole_number, is_percentage)
	local decimal_separator = g_currentMission.hud.l10n.decimalSeparator or "."
	local thousands_grouping = g_currentMission.hud.l10n.thousandsGroupingChar or " "

	if is_whole_number then
		local s = string.format("%d", math.floor(number))
		local pos = string.len(s) % 3
		if pos == 0 then pos = 3 end
		return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos+1), "(...)", "" .. thousands_grouping .. "%1") .. " " .. (g_currentMission.hud.l10n.unit_literShort or "l")
	elseif is_percentage then
		if number == 1 then
			return "100 %"
		else
			number = ContractHUD.displayDecimals and math.floor(number * 1000) / 10 or math.floor(number * 100)
			local per, n = string.gsub(tostring(number),"[\\.]",decimal_separator)
			if not string.find(number, "[\\.]") and ContractHUD.displayDecimals then
				per = tostring(per) .. ".0 %"
			else
				per = tostring(per) .. " %"
			end
			return per
		end
	else
		return number
	end
end

function ContractHUD:buildProgressBar(completion)
	-- constract text progress bar like this: [||||||||¦:::::]
	local maxPositions = 20
	local currentLevel5 = math.floor((completion / 0.05))
	local modulo5 = (completion % 0.05)
	local currentLevel25 = math.floor((modulo5 / 0.025))
	local remain = maxPositions - currentLevel5 - currentLevel25
	local barText = "["

	-- add progress by 5 %
	for i = 1, currentLevel5 do
		barText = barText .. "|"
	end

	-- add progress 2.5%
	for i = 1, currentLevel25 do
		barText = barText .. "¦"
	end

	-- add empty
	for i = 1, remain do
		barText = barText .. ":"
	end

	barText = barText .. "]"

	return barText
end

function ContractHUD:getFruitTypeName(fruitTypeIndex)
	if fruitTypeIndex ~= nil and type(fruitTypeIndex) == "number" then
		local fruitTypeTable = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		return fruitTypeTable ~= nil and ContractHUD:firstToUpper(fruitTypeTable.name) or ""
	end
	return "NULL"
end

-- this function is for debugging purpose
function ContractHUD:printValue(name, value)
	-- print to log.txt
	print("ContractHUD Info:  " .. name .. " >> " .. value)
end

-- this function is for debugging purpose
function ContractHUD:getTableKeys(tableObject)
	if tableObject ~= nil and type(tableObject) == "table" then
		local keyset={}
		local n=0

		for k,v in pairs(tableObject) do
			n=n+1
			keyset[n]=k
		end

		-- print to log.txt
		print(table.concat(keyset,","))
		--returns concatenated string of table keys
		return table.concat(keyset,",")
	end

	if tableObject == nil then
		return "NULL2"
	elseif  type(tableObject) == "string" then
		return tableObject
	else
		return type(tableObject)
	end
end

function ContractHUD:getFillTypeTitle(fillTypeIndex)
	if fillTypeIndex ~= nil then
		local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		return fillTypeDesc ~= nil and ContractHUD:firstToUpper(fillTypeDesc.title) or ""
	end
	return nil
end

function ContractHUD:firstToUpper(str)
	return (string.lower(str):gsub("^%l", string.upper))
end

function ContractHUD:getRemainingTime(contract, formated)
	if formated == false then
    formated = false
  else
    formated = true
  end
	local environment = g_currentMission.environment

	local usedDaysToMinutes = (environment.currentDay - contract.contractDay) * 24 * 60
	local usedMinutes = MathUtil.msToMinutes(environment.dayTime - contract.contractTime)

	local remainingMinutes = 0

	if contract.status == 2 then
		remainingMinutes = 0
	else
		remainingMinutes = contract.contractDuration - (usedDaysToMinutes + usedMinutes)
	end

	if formated then
		local hours = math.floor(remainingMinutes / 60)
		local minutes = remainingMinutes - hours * 60
		local seconds = (remainingMinutes - math.floor(remainingMinutes)) * 60

		if remainingMinutes == 0 then
			return ContractHUD.shortTime and string.format("%02d:%02d", 0, 0) or string.format("%02d:%02d:%02d", 0, 0, 0)
		elseif math.floor(hours) == 0 and math.floor(minutes) == 0 then
			return string.format("%02d", seconds)
		else
			return ContractHUD.shortTime and string.format("%02d:%02d", hours, minutes) or string.format("%02d:%02d:%02d", hours, minutes, seconds)
		end
	else
		return math.floor(remainingMinutes)
	end
end

function ContractHUD:renderText(x, y, size, text, bold, textColor) --colorId )
	if type(textColor) == 'table' then
		setTextColor(unpack(textColor))
	elseif textColor % 1 == 0 then
	 setTextColor(unpack(self.Colors[textColor][2]))
	else
	   setTextColor(unpack(self.Colors[1][2])) -- set default color which is white
	end
	setTextBold(bold)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	renderText(x, y, size, text)

	-- Back to defaults
	setTextBold(false)
	setTextColor(unpack(self.Colors[1][2])) --Back to default color which is white
	setTextAlignment(RenderText.ALIGN_LEFT)
end

function ContractHUD.toggleDisplayMode()
	-- keep it simple
	if ContractHUD.displayMode >= 6 then  -- 6 = hidden, highest value
		ContractHUD.displayMode = 0
	else
		ContractHUD.displayMode = ContractHUD.displayMode + 1
	end

	ContractHUD.displayModeChanged = true
end

addModEventListener(ContractHUD)
FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, ContractHUD.registerActionEvents);
