-- Contract HUD for FS22
--
-- This mod displays the status with percentage done of every active contract on the active farm always on the HUD
--
-- Author: StingerTopGun

ContractHUD = {}
ContractHUD.eventName = {}
ContractHUD.ModName = g_currentModName
ContractHUD.ModDirectory = g_currentModDirectory
ContractHUD.Version = "1.2.0.6"

ContractHUD.Colors = {}
ContractHUD.Colors[1]  = {'col_white', {1, 1, 1, 1}}
ContractHUD.Colors[2]  = {'col_black', {0, 0, 0, 0.7}}
ContractHUD.Colors[3]  = {'col_grey', {0.7411, 0.7450, 0.7411, 1}}
ContractHUD.Colors[4]  = {'col_blue', {0.0044, 0.15, 0.6376, 1}}
ContractHUD.Colors[5]  = {'col_red', {0.7835, 0.0034, 0.0030, 1}}
ContractHUD.Colors[6]  = {'col_green', {0.0395, 0.2015, 0.0242, 1}}
ContractHUD.Colors[7]  = {'col_cyan', {0.0003, 0.5647, 0.9822, 1}}
ContractHUD.Colors[8]  = {'col_orange', {1.0000, 0.1413, 0.0000, 1}}
ContractHUD.Colors[9]  = {'col_dgreen', {0.1062, 0.5234, 0.1450, 1}}
ContractHUD.Colors[10] = {'col_sorange', {1.0000, 0.1830, 0.0210, 1}}
ContractHUD.Colors[11] = {'col_green2', {0.5059, 0.7647, 0.1961, 1}}
ContractHUD.Colors[12] = {'col_green3', {0.391, 0.521, 0.366, 1}}
ContractHUD.Colors[13]  = {'col_cyan2', {0.0, 0.7764, 0.9921, 1}}

ContractHUD.background = 'dataS/menu/hud/ui_elements.png'
ContractHUD.overlay = nil
ContractHUD.overlayIsRendered = false
ContractHUD.horizontalMargin = 0.0018
ContractHUD.verticalMargin = 0.0008
ContractHUD.maxTextWidth = 0
ContractHUD.defaultOverlayWidth = 0.062
ContractHUD.displayModeChanged = false

ContractHUD.HeadlineColor = 13 -- put here color index from above
ContractHUD.MissionTextColor = 1 -- default active mission color, put here color index from above
ContractHUD.ColorSuccess = 9
ContractHUD.ColorFail = 5

ContractHUD.FieldDisplay = false -- false => Field, true => Field No.

ContractHUD.TransportDisplay = false -- false => Supply, true => Transporting

ContractHUD.activeMissons = 0

-- displayMode
-- 0 - field mission - display field number and field work type and also crop type if available, if progress display bar (default)
--   - transport mission - display mission type and crop type, if progress display bar instead of remaining time (default)
-- 1 - field mission - display field number and field work type and also crop type if available, if progress display bar
--   - transport mission - display mission type and crop type, if progress display % number instead of required amount
-- 2 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
--   - transport mission - display mission type and crop type, if progress display % number and bar instead of required amount
-- 3 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
--   - transport mission - display crop type, if progress display % number instead of required amount also display destination
-- 4 = hide HUD
ContractHUD.displayMode = 0


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
	if g_client ~= nil and g_currentMission.hud.isVisible and ContractHUD.displayMode ~= 4 and ContractHUD.activeMissons ~= 0 and not g_noHudModeEnabled and not g_sleepManager:getIsSleeping() then

		local posX = g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.x
        local posY = g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.y
		local size = g_currentMission.inGameMenu.hud.inputHelp.helpTextSize * 1.1 -- add 10%
        posY = posY + g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.height - size
        posX = posX - ( g_currentMission.inGameMenu.hud.inputHelp.helpTextOffsetY * 2 )

        local outputText = ContractHUD:translate("headline") .. ": " .. ContractHUD.activeMissons
        local completion = 0
        local countContracts = 0

        local field_text = ""
        local field_work = ""
        local fruitTypeName = ""

        -- for boxOverlay
        local baseX = posX
        local baseY = g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.y + g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.height
        local maxTextWidth = 0.0

        -- print haadline
        ContractHUD:renderText(posX, posY, size, outputText, false, ContractHUD.HeadlineColor)--FSBaseMission.INGAME_NOTIFICATION_INFO) --ContractHUD.HeadlineColor)
        maxTextWidth = getTextWidth(size, outputText)
        posY = posY - size  -- shift one line down because of headline

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
                    textColor = ContractHUD.MissionTextColor
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

                -- displayMode
                -- 0 - field mission - display field number and field work type and also crop type if available, if progress display bar (default)
                --   - transport mission - display mission type and crop type, if progress display bar instead of remaining time (default)
                -- 1 - field mission - display field number and field work type and also crop type if available, if progress display bar
                --   - transport mission - display mission type and crop type, if progress display % number instead of required amount
                -- 2 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
                --   - transport mission - display mission type and crop type, if progress display % number and bar instead of required amount
                -- 3 - field mission - display field number and field work type and also crop type if available, if progress display % number and bar
                --   - transport mission - display crop type, if progress display % number instead of required amount also display destination
                -- 4 = hide HUD
                if ContractHUD.displayMode == 0 then
                    if contract.type.name == "supplyTransport" then
                        if completion == 0 then -- when 0%, display remianing time
                            outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:getRemainingTime(contract)
                        else -- else progress bar
                            outputText = field_text .. " - " .. field_work .. " " .. ContractHUD:buildProgressBar(completion)
                        end
                    else -- other then supplyTransport contracts
                        if completion == 0 then -- when 0%, display fuit type title
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
                            outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(contract.contractLiters, true, false) .. " " .. (g_currentMission.hud.l10n.unit_literShort or " l")
                        else -- else display percentage
                            outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " %" -- set percentage to one dec like 95.6%
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
                            outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " %" -- set percentage to one dec like 95.6%
                        end
                    end
                elseif ContractHUD.displayMode == 2 then
                    if contract.type.name == "supplyTransport" then
                        if completion == 0 then -- when 0%, display contracted liters
                            outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(contract.contractLiters, true, false) .. " " .. (g_currentMission.hud.l10n.unit_literShort or " l")
                        else -- else display percentage and bar
                            outputText = field_text .. " - " .. field_work .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " % " .. ContractHUD:buildProgressBar(completion)
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
                            outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " % " .. ContractHUD:buildProgressBar(completion)
                        end
                    end
                elseif ContractHUD.displayMode == 3 then
                    if contract.type.name == "supplyTransport" then
                        if completion == 0 then -- when 0%, display required amount
                            outputText = field_work .. " (" .. ContractHUD:formatNumber(contract.contractLiters, true, false) .. " " .. (g_currentMission.hud.l10n.unit_literShort or " l") .. ") => " .. contract.sellingStation.uiName
                        else -- else display percentage and destination
                            outputText = field_work .. " (" .. ContractHUD:formatNumber(completion, false, true) .. " %) => " .. contract.sellingStation.uiName
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
                            outputText = field_text .. " - " .. ContractHUD:formatNumber(completion, false, true) .. " % " .. ContractHUD:buildProgressBar(completion)
                        end
                    end
                end

                ContractHUD:renderText(posX, posY, size, outputText, false, textColor)

                posY = posY - size  -- shift one line down

                -- handle counting
                countContracts = countContracts + 1

                -- get max width of the text
                if getTextWidth(size, outputText) > maxTextWidth then
                    maxTextWidth = getTextWidth(size, outputText)
                end
            end
        end   

        local overlayX = 0   
        local overlayY = 0
        local overlayWidth = 0
        local overlayHeight = 0

        -- draw overlay if not exists
        if not ContractHUD.overlayIsRendered then
            overlayWidth = maxTextWidth + ContractHUD.horizontalMargin*2
            if overlayWidth < ContractHUD.defaultOverlayWidth then
                overlayWidth = ContractHUD.defaultOverlayWidth
            end
            overlayHeight = size * (countContracts + 1) + ContractHUD.verticalMargin + g_currentMission.inGameMenu.hud.inputHelp.helpTextOffsetY
            --ContractHUD:printValue("overlayHeight", overlayHeight)
            --ContractHUD:printValue("overlayWidth", overlayWidth)
            if overlayHeight < g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.height then
               overlayHeight = g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.height
            end
            overlayX = baseX - overlayWidth + ContractHUD.horizontalMargin
            overlayY = baseY - overlayHeight

            -- debugging
            --ContractHUD:printValue("overlayX", overlayX)
            --ContractHUD:printValue("overlayY", overlayY)
            --ContractHUD:printValue("overlayWidth", overlayWidth)
            --ContractHUD:printValue("overlayHeight", overlayHeight)
            --

            ContractHUD.overlay = ContractHUD.createImageOverlay(ContractHUD.background, overlayX, overlayY, overlayWidth, overlayHeight)

            ContractHUD.overlay:setUVs(g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.uvs)

            ContractHUD.overlay:setColor(unpack(self.Colors[2][2]))
            g_currentMission.hud.gameInfoDisplay:addChild(ContractHUD.overlay)
            ContractHUD.overlayIsRendered = true
        elseif math.abs(ContractHUD.maxTextWidth - maxTextWidth) > ContractHUD.horizontalMargin or ContractHUD.activeMissons ~= countContracts or ContractHUD.displayModeChanged then
            overlayWidth = maxTextWidth + ContractHUD.horizontalMargin*2
            if overlayWidth < ContractHUD.defaultOverlayWidth then
                overlayWidth = ContractHUD.defaultOverlayWidth
            end
            overlayHeight = size * (countContracts + 1) + ContractHUD.verticalMargin + g_currentMission.inGameMenu.hud.inputHelp.helpTextOffsetY
            if overlayHeight < g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.height then
               overlayHeight = g_currentMission.hud.gameInfoDisplay.backgroundOverlay.overlay.height
            end
            overlayX = baseX - overlayWidth + ContractHUD.horizontalMargin
            overlayY = baseY - overlayHeight    
            ContractHUD.overlay:setPosition(overlayX, overlayY)
            ContractHUD.overlay:setDimension(overlayWidth, overlayHeight)

            ContractHUD.displayModeChanged = false
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

function ContractHUD:formatNumber(number, whole_number, is_percentage)
	local decimal_separator = g_currentMission.hud.l10n.decimalSeparator or "."
  	local thousands_grouping = g_currentMission.hud.l10n.thousandsGroupingChar or " "

	if is_percentage then
		number = math.floor(number * 1000) / 10
	end

  	-- fhis fill format any number, example: -123456789.1234 >> -123.456.789
  	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([' .. decimal_separator .. ']?%d*)')
  	local result = ""

	-- when fraction below 0.1, then vierd number is displayed like 60. %, we want 60.0 %
	if fraction == nil or tonumber(fraction) == nil then
		fraction = "0"
	elseif tonumber(fraction) < 0.1 then
		fraction = "0"
	else
		fraction = fraction:sub(2,string.len(fraction))
	end

  	-- reverse the int-string and append a comma to all blocks of 3 digits
  	int = int:reverse():gsub("(%d%d%d)", "%1" .. thousands_grouping)

	-- but I need only positive numbers without fraction and with dot separator
	result = int:reverse():gsub("^" .. thousands_grouping, "")

	--return result:gsub(",", ".") .. " l"
	if whole_number then
    	return result
  	else
		return minus .. result  .. decimal_separator .. fraction
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

function ContractHUD:getRemainingTime(contract)
    local environment = g_currentMission.environment

    local usedDaysToMinutes = (environment.currentDay - contract.contractDay) * 24 * 60
    local usedMinutes = MathUtil.msToMinutes(environment.dayTime - contract.contractTime)

    local remainingMinutes = contract.contractDuration - (usedDaysToMinutes + usedMinutes)

    if remainingMinutes > 0 then
        local hours = math.floor(remainingMinutes / 60)
        local minutes = remainingMinutes - hours * 60
        local seconds = (remainingMinutes - math.floor(remainingMinutes)) * 60

        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end

    return string.format("%02d:%02d:%02d", 0, 0, 0) -- return formated remianing time
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
    if ContractHUD.displayMode >= 4 then  -- 2 = hidden, highest value
        ContractHUD.displayMode = 0
    else
        ContractHUD.displayMode = ContractHUD.displayMode + 1
    end

    ContractHUD.displayModeChanged = true
end

addModEventListener(ContractHUD)
FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, ContractHUD.registerActionEvents);
