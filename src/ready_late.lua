---@meta _


import 'extra_gods.lua'
import 'hex_reroll.lua'

extra_gods_close_doors()

extra_gods_hide_hades_rarity()


modutil.mod.Path.Wrap("CreateSpellButtons", function(base, screen)
	base(screen)
	hex_reroll_close(screen)
end)
