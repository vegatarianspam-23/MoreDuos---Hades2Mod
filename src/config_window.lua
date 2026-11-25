---@meta _
---@diagnostic disable: lowercase-global


local CONFIG_SMALL_WORDS = { Of = 'of', For = 'for', The = 'the', And = 'and', To = 'to' }

local CONFIG_LABELS = {
	OneDuoPerPair = 'Only one duo per god pairing each run',
	TectonicCycleResetsCooldowns ='Tectonic Cycle also resets timed cooldowns',
	WrathOfOlympus = 'Wrath of Olympus support',
	ZagreusJourney = "Zagreus' Journey support",
	HermesDuos = 'HermesDuos support',
}

local CONFIG_MOD_SUPPORT = { WrathOfOlympus = true, ZagreusJourney = true, HermesDuos = true }

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


local function config_node()
	return { Cells = {}, Sections = {} }
end


local function config_read()
	local root = config_node()
	for definition, entry in pairs(chalk.original(config).entries) do
		local value = entry:get()
		if type(value) == 'boolean' then
			local node = root
			for name in definition.section:gmatch('[^.]+') do
				node.Sections[name] = node.Sections[name] or config_node()
				node = node.Sections[name]
			end
			node.Cells[definition.key] = { Entry = entry, Value = value }
		end
	end
	return root.Sections.config or config_node()
end


local function config_sorted_keys(section)
	local labels, keys = {}, {}
	for key in pairs(section and section.Cells or {}) do
		labels[key] = config_label(key)
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b) return labels[a] < labels[b] end)
	return keys
end


local function config_save()
	local file = chalk.original(config)
	if file and file.save then file:save() end
end


local function config_entry(cell, label, id)
	return { Cell = cell, Label = label .. '##' .. id }
end


local function config_checkbox(entry)
	local cell = entry.Cell
	local value, pressed = rom.ImGui.Checkbox(entry.Label, cell.Value)
	if pressed then
		cell.Value = value
		cell.Entry:set(value)
		duo_config_changed()
		config_save()
	end
end


local function config_header(name, id, open)
	if open then
		return rom.ImGui.CollapsingHeader(name .. '##' .. id, rom.ImGuiTreeNodeFlags.DefaultOpen)
	end
	return rom.ImGui.CollapsingHeader(name .. '##' .. id)
end


local function config_duos(section)
	local byGod, godNames, other = {}, {}, {}
	for _, key in ipairs(config_sorted_keys(section)) do
		local cell, label = section.Cells[key], config_label(key)
		local gods = config_gods(key)
		if gods then
			for i, god in ipairs(gods) do
				if not byGod[god] then
					byGod[god] = {}
					table.insert(godNames, god)
				end
				local partner = gods[3 - i]
				table.insert(byGod[god], config_entry(cell, partner and (label .. ' (with ' .. partner .. ')') or label, 'Duos.' .. god .. '.' .. key))
			end
		else
			table.insert(other, config_entry(cell, label, 'Duos.Other.' .. key))
		end
	end
	table.sort(godNames)

	local groups = {}
	for _, god in ipairs(godNames) do
		table.insert(groups, { Label = god .. '##Duos.' .. god, Entries = byGod[god] })
	end
	if #other > 0 then table.insert(groups, { Label = 'Other##Duos.Other', Entries = other }) end
	return groups
end


local function config_experimental_group(key)
	if CONFIG_MOD_SUPPORT[key] then return 'Mods' end
	if key:match('Alt%d*$') then return 'Alt' end
	if config_gods(key) then return 'Duos' end
	return 'Other'
end


local function config_experimental(section)
	local byGroup = {}
	for _, key in ipairs(config_sorted_keys(section)) do
		local label = config_label(key)
		local gods = config_gods(key)
		if gods and #gods == 2 then label = label .. ' (' .. gods[1] .. ' & ' .. gods[2] .. ')' end
		local group = config_experimental_group(key)
		byGroup[group] = byGroup[group] or {}
		table.insert(byGroup[group], config_entry(section.Cells[key], label, 'Experimental.' .. key))
	end

	local groups = {}
	for _, spec in ipairs(CONFIG_EXPERIMENTAL_GROUPS) do
		if byGroup[spec.Key] then
			table.insert(groups, { Label = spec.Name .. '##Experimental.' .. spec.Key, Entries = byGroup[spec.Key] })
		end
	end
	return groups
end


local function config_options(section)
	local entries = {}
	for _, key in ipairs(config_sorted_keys(section)) do
		table.insert(entries, config_entry(section.Cells[key], config_label(key), 'Options.' .. key))
	end
	return entries
end


local configLayout

local function config_layout()
	local layout = configLayout
	if layout and layout.Source == config and layout.Text == duo_text and layout.Requirements == duo_requirements then
		return layout
	end

	local root = config_read()
	layout = { Source = config, Text = duo_text, Requirements = duo_requirements }
	if root.Cells.enabled then layout.Enabled = config_entry(root.Cells.enabled, 'Enable MoreDuos', 'enabled') end
	layout.Duos = config_duos(root.Sections.Duos)
	layout.Experimental = config_experimental(root.Sections.Experimental)
	layout.Options = config_options(root.Sections.Options)

	configLayout = layout
	return layout
end


local function config_draw_groups(groups)
	for _, group in ipairs(groups) do
		if rom.ImGui.TreeNode(group.Label) then
			for _, entry in ipairs(group.Entries) do config_checkbox(entry) end
			rom.ImGui.TreePop()
		end
	end
end


function more_duos_draw_config()
	if not config then return end
	local layout = config_layout()

	rom.ImGui.TextWrapped('Changes are saved right away. Turning a duo on or off applies from the next room. Alternate versions and other experimental options need a restart.')
	if layout.Enabled then config_checkbox(layout.Enabled) end
	rom.ImGui.Separator()

	if config_header('Duos', 'Duos', true) then config_draw_groups(layout.Duos) end
	if config_header('Experimental', 'Experimental') then config_draw_groups(layout.Experimental) end
	if config_header('Options', 'Options') then
		for _, entry in ipairs(layout.Options) do config_checkbox(entry) end
	end
end
