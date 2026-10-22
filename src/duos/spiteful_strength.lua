---@meta _


local PRIME = 'SWuSpitefulStrength'


register_duo({
	key = 'SpitefulStrength',

	StatLines = {
		'SWuSpitefulStrengthManaStatDisplay',
		'SWuSpitefulStrengthDamageStatDisplay',
	},
	ExtractValues = {
		{ Key = 'ReportedCost', ExtractAs = 'TooltipManaCost' },
		{ Key = 'SWuDamagePerPrimed', ExtractAs = 'TooltipDamagePerPrimed', Format = 'Percent' },
	},

	ExtraFields = {
		SWuDamagePerPrimed = mod.tuning.SpitefulStrength.DamagePerPrimed,
		SWuPrimedMultiplier = 1,

		SetupFunction = {
			Name = 'TraitReserveMana',
			Args = {
				Name = PRIME,
				ManaReservationCost = mod.tuning.SpitefulStrength.PrimeMana,
				ReportValues = { ReportedCost = 'ManaReservationCost' },
			},
		},

		OnExpire = {
			FunctionName = 'TraitUnreserveMana',
			FunctionArgs = { Name = PRIME },
		},

		AddOutgoingDamageModifiers = {
			ValidWeapons = DUO_SCOPE_WEAPON.ValidWeapons,
			ValidWeaponsLookup = DUO_SCOPE_WEAPON.ValidWeaponsLookup,
			UseTraitValue = 'SWuPrimedMultiplier',
			IsMultiplier = true,
		},
	},
})


function spiteful_strength_refresh(attacker)
	if not duo_on('SpitefulStrength') then return end

	local hero = game.CurrentRun and game.CurrentRun.Hero
	if not hero or attacker ~= hero then return end

	local trait = game.GetHeroTrait(duo_traits.SpitefulStrength)
	if not trait then return end

	local primed = 0
	for _, amount in pairs(hero.ReserveManaSources or {}) do
		primed = primed + amount
	end

	local fraction = 0
	if (hero.MaxMana or 0) > 0 then
		fraction = math.min(primed / hero.MaxMana, 1)
	end

	trait.SWuPrimedMultiplier = 1 + fraction * mod.tuning.SpitefulStrength.DamagePerPrimed
end
