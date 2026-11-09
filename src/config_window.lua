---@meta _
---@diagnostic disable: lowercase-global


local CONFIG_SMALL_WORDS = { Of = 'of', For = 'for', The = 'the', And = 'and', To = 'to' }

local CONFIG_LABELS = {
	TectonicCycleResetsCooldowns = 'Tectonic Cycle also resets timed cooldowns',
	WrathOfOlympus = 'Wrath of Olympus support',
	ZagreusJourney = "Zagreus' Journey support",
}

local CONFIG_MOD_SUPPORT = { WrathOfOlympus = true, ZagreusJourney = true }

local CONFIG_EXPERIMENTAL_GROUPS = {
	{ Key = 'Duos', Name = 'New duos' },
	{ Key = 'Alt', Name = 'Alternate versions' },
	{ Key = 'Other', Name = 'Other boons' },
	{ Key = 'Mods', Name = 'Mod support' },
}


local function config_words(key)
	local words = {}
	for word in key:gmatch('%u[%l%d]*') do
		table.insert(words, (#words > 0 and CONFIG_SMALL_WORDS[word]) or word)
	end
	return table.concat(words, ' ')
end


local function config_label(key)
	if CONFIG_LABELS[key] then return CONFIG_LABELS[key] end
	local text = duo_text and duo_text[key]
	return (text and text.Name) or config_words(key)
end


local function config_gods(key)
	local spec = duo_requirements and duo_requirements[key]
	return spec and spec.Gods
end


local function config_sorted_keys(section)
	local keys = {}
	for key, value in pairs(section) do
		if type(key) == 'string' and type(value) == 'boolean' then table.insert(keys, key) end
	end
	table.sort(keys, function(a, b) return config_label(a) < config_label(b) end)
	return keys
end


local function config_save()
	local file = chalk.original(config)
	if file and file.save then file:save() end
end


local function config_checkbox(label, id, section, key)
	local value, pressed = rom.ImGui.Checkbox(label .. '##' .. id, section[key] == true)
	if pressed then
		section[key] = value
		config_save()
	end
end


local function config_header(name, id, open)
	if open then
		return rom.ImGui.CollapsingHeader(name .. '##' .. id, rom.ImGuiTreeNodeFlags.DefaultOpen)
	end
	return rom.ImGui.CollapsingHeader(name .. '##' .. id)
end


local function config_draw_duos()
	local section = config.Duos
	if not section then return end

	local byGod, godNames, other = {}, {}, {}
	for _, key in ipairs(config_sorted_keys(section)) do
		local gods = config_gods(key)
		if gods then
			for i, god in ipairs(gods) do
				if not byGod[god] then
					byGod[god] = {}
					table.insert(godNames, god)
				end
				table.insert(byGod[god], { Key = key, Partner = gods[3 - i] })
			end
		else
			table.insert(other, key)
		end
	end
	table.sort(godNames)

	for _, god in ipairs(godNames) do
		if rom.ImGui.TreeNode(god .. '##Duos.' .. god) then
			for _, entry in ipairs(byGod[god]) do
				local label = config_label(entry.Key)
				if entry.Partner then label = label .. ' (with ' .. entry.Partner .. ')' end
				config_checkbox(label, 'Duos.' .. god .. '.' .. entry.Key, section, entry.Key)
			end
			rom.ImGui.TreePop()
		end
	end

	if #other > 0 and rom.ImGui.TreeNode('Other##Duos.Other') then
		for _, key in ipairs(other) do
			config_checkbox(config_label(key), 'Duos.Other.' .. key, section, key)
		end
		rom.ImGui.TreePop()
	end
end


local function config_experimental_group(key)
	if CONFIG_MOD_SUPPORT[key] then return 'Mods' end
	if key:sub(-3) == 'Alt' then return 'Alt' end
	if config_gods(key) then return 'Duos' end
	return 'Other'
end


local function config_draw_experimental()
	local section = config.Experimental
	if not section then return end

	local groups = {}
	for _, key in ipairs(config_sorted_keys(section)) do
		local group = config_experimental_group(key)
		groups[group] = groups[group] or {}
		table.insert(groups[group], key)
	end

	for _, spec in ipairs(CONFIG_EXPERIMENTAL_GROUPS) do
		local keys = groups[spec.Key]
		if keys and rom.ImGui.TreeNode(spec.Name .. '##Experimental.' .. spec.Key) then
			for _, key in ipairs(keys) do
				local label = config_label(key)
				local gods = config_gods(key)
				if gods and #gods == 2 then label = label .. ' (' .. gods[1] .. ' & ' .. gods[2] .. ')' end
				config_checkbox(label, 'Experimental.' .. key, section, key)
			end
			rom.ImGui.TreePop()
		end
	end
end


local function config_draw_options()
	local section = config.Options
	if not section then return end

	for _, key in ipairs(config_sorted_keys(section)) do
		config_checkbox(config_label(key), 'Options.' .. key, section, key)
	end
end


function more_duos_draw_config()
	if not config then return end

	rom.ImGui.TextWrapped('Changes are saved right away. Turning a duo on or off applies from the next room. Alternate versions and other experimental options need a restart.')
	config_checkbox('Enable MoreDuos', 'enabled', config, 'enabled')
	rom.ImGui.Separator()

	if config_header('Duos', 'Duos', true) then config_draw_duos() end
	if config_header('Experimental', 'Experimental') then config_draw_experimental() end
	if config_header('Options', 'Options') then config_draw_options() end
end
