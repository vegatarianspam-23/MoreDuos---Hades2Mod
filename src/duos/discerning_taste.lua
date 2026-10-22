---@meta _


register_duo({
	key = 'DiscerningTaste',

	StatLines = { 'SWuDiscerningTasteStatDisplay' },
	ExtractValues = {
		{ Key = 'SWuRerolls', ExtractAs = 'TooltipRerolls' },
	},

	ExtraFields = {
		SWuRerolls = mod.tuning.DiscerningTaste.Rerolls,

		AcquireFunctionName = _PLUGIN.guid .. '.DiscerningTasteAcquire',

		GameStateRequirements = {
			{
				Path = { 'GameState', 'FatedStatus' },
				IsNone = { 'Fated' },
			},
		},
	},
})


function discerning_taste_held()
	if not duo_on('DiscerningTaste') then return false end
	local name = duo_traits.DiscerningTaste
	if not name or not in_run() then return false end
	return game.HeroHasTrait(name) == true
end


function discerning_taste_sync()

	game.RerollCosts.Hammer = discerning_taste_held() and 1 or -1
end


---@diagnostic disable-next-line: unused-local
function discerning_taste_settle_cost(_screen, button)
	if not button or not discerning_taste_held() then return end
	if button.RerollFunctionName == nil or button.RerollId == nil then return end
	if type(button.Cost) ~= 'number' or button.Cost < 0 then return end

	local spent = (game.CurrentRun and game.CurrentRun.CurrentRoom or {}).SpentRerolls
	button.Cost = (spent and spent[button.RerollId]) or 0
end


function discerning_taste_discount(button, rerollId)
	if not button or not discerning_taste_held() then return end
	if button.Cost == nil or button.Cost < 0 then return end

	local spent = (game.CurrentRun and game.CurrentRun.CurrentRoom or {}).SpentRerolls
	local cost = (spent and rerollId and spent[rerollId]) or 0

	button.Cost = cost
	game.ModifyTextBox({
		Id = button.Id,
		Text = 'Boon_Reroll',
		LuaKey = 'TempTextData',
		LuaValue = { Amount = cost },
	})
end


function discerning_taste_free_target(target)
	if not discerning_taste_held() then return false end

	local room = game.CurrentRun and game.CurrentRun.CurrentRoom
	local rerollId = target and target.ObjectId
	if not room or not rerollId then return false end

	return not (room.SpentRerolls and room.SpentRerolls[rerollId])
end


function discerning_taste_free_prompt(base, target, ...)
	local run = game.CurrentRun
	if not run or (run.NumRerolls or 0) > 0 then return base(target, ...) end
	if not discerning_taste_free_target(target) then return base(target, ...) end

	run.NumRerolls = 1

	local ok, result = pcall(base, target, ...)

	run.NumRerolls = 0

	if not ok then error(result) end
	return result
end


function discerning_taste_free_boons(base, screen, lootData, reroll, args)
	local run = game.CurrentRun
	if not run or (run.NumRerolls or 0) > 0 or not discerning_taste_held() then
		return base(screen, lootData, reroll, args)
	end

	local rerollId = lootData and lootData.ObjectId
	local room = run.CurrentRoom
	if not rerollId then return base(screen, lootData, reroll, args) end
	if room and room.SpentRerolls and room.SpentRerolls[rerollId] then
		return base(screen, lootData, reroll, args)
	end

	run.NumRerolls = 1

	local ok, result = pcall(base, screen, lootData, reroll, args)

	run.NumRerolls = 0

	if not ok then error(result) end
	return result
end


function discerning_taste_free_store(base, screen, options, rerollFunctionName)
	local run = game.CurrentRun
	if not run or (run.NumRerolls or 0) > 0 or not discerning_taste_held() then
		return base(screen, options, rerollFunctionName)
	end

	local rerollId = screen and screen.Name
	local room = run.CurrentRoom
	if not rerollId then return base(screen, options, rerollFunctionName) end
	if room and room.SpentRerolls and room.SpentRerolls[rerollId] then
		return base(screen, options, rerollFunctionName)
	end

	run.NumRerolls = 1

	local ok, result = pcall(base, screen, options, rerollFunctionName)

	run.NumRerolls = 0

	if not ok then error(result) end
	return result
end


function discerning_taste_free_control(useTarget)
	local run = game.CurrentRun
	if not run or (run.NumRerolls or 0) > 0 then return end
	if not useTarget or not useTarget.CanBeRerolled then return end
	if useTarget.RerollFunctionName == nil then return end
	if not discerning_taste_free_target(useTarget) then return end
	if game.GetConfigOptionValue({ Name = 'UseMouse' }) then return end

	game.AddControlBlock('Shout', 'ActiveUseTarget')
end


function discerning_taste_door_reroll(base, run, target)
	local rerollId = target and target.ObjectId
	local room = run and run.CurrentRoom
	if not rerollId or not room or not discerning_taste_held() then return base(run, target) end

	if room.SpentRerolls and room.SpentRerolls[rerollId] then return base(run, target) end

	local held = run.NumRerolls or 0
	run.NumRerolls = held + 1
	mod.DiscerningTasteFreeReroll = true

	local ok, err = pcall(base, run, target)

	mod.DiscerningTasteFreeReroll = nil

	if run.NumRerolls == held + 1 then
		run.NumRerolls = held
		game.UpdateRerollUI(run.NumRerolls)
	else
		room.SpentRerolls = room.SpentRerolls or {}
		room.SpentRerolls[rerollId] = game.RerollCosts.ReuseIncrement
	end

	if not ok then error(err) end
end


function discerning_taste_panel_reroll(base, screen, button)
	local run = game.CurrentRun
	if not run or not discerning_taste_held() then return base(screen, button) end
	if not button or button.RerollId ~= nil then return base(screen, button) end
	if type(button.Cost) ~= 'number' or button.Cost < 0 then return base(screen, button) end

	local rerollId = screen and screen.Name
	local room = run.CurrentRoom
	if not rerollId then return base(screen, button) end
	if room and room.SpentRerolls and room.SpentRerolls[rerollId] then
		return base(screen, button)
	end

	button.Cost = 0
	mod.DiscerningTasteFreeReroll = true

	local ok, err = pcall(base, screen, button)

	mod.DiscerningTasteFreeReroll = nil

	if ok and room then
		room.SpentRerolls = room.SpentRerolls or {}
		room.SpentRerolls[rerollId] = game.RerollCosts.ReuseIncrement
	end

	if not ok then error(err) end
end


function discerning_taste_swallow_spend()
	return mod.DiscerningTasteFreeReroll == true
end


function discerning_taste_unblock_reroll(source)
	if source and source.BlockReroll and discerning_taste_held() then
		source.BlockReroll = nil
	end
end


function discerning_taste_discount_hex(screen)
	local button = screen and screen.Components and screen.Components.RerollButton
	local lootData = screen and screen.Source
	discerning_taste_discount(button, lootData and lootData.ObjectId)
end


function discerning_taste_discount_boons(screen, lootData)
	local button = screen and screen.Components and screen.Components.RerollButton
	discerning_taste_discount(button, lootData and lootData.ObjectId)
end


function discerning_taste_discount_store(screen)
	local button = screen and screen.Components and screen.Components.RerollButton
	discerning_taste_discount(button, screen and screen.Name)
end


---@diagnostic disable-next-line: unused-local
function mod.DiscerningTasteAcquire(args, traitData)
	if not duo_on('DiscerningTaste') then return end
	game.AddRerolls('SWuDiscerningTaste', { Amount = mod.tuning.DiscerningTaste.Rerolls })
	discerning_taste_sync()
end
