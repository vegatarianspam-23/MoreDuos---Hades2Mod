---@meta _


function hex_reroll_allowed()
	if mod.tuning.Systems.HexReroll == true then return true end

	return discerning_taste_held()
end


function hex_reroll_close(screen)
	if hex_reroll_allowed() then return end

	local button = screen and screen.Components and screen.Components.RerollButton
	if not button then return end

	button.OnPressedFunctionName = nil
	button.RerollFunctionName = nil

	game.SetAlpha({ Id = button.Id, Fraction = 0.0, Duration = 0 })
end
