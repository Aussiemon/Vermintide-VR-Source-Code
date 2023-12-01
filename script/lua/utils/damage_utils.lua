-- chunkname: @script/lua/utils/damage_utils.lua

DamageUtils = {}

DamageUtils.get_breed_armor = function (target_unit)
	local breed = target_unit and Unit.get_data(target_unit, "breed")
	local player_armor = 1
	local target_unit_armor = breed and breed.armor_category or player_armor

	return target_unit_armor
end

DamageUtils.calculate_damage = function (damage_table, target_unit, attacker_unit, hit_zone_name, headshot_multiplier, backstab_multiplier)
	local target_unit_armor = DamageUtils.get_breed_armor(target_unit)
	local has_damage_boost = false

	if attacker_unit and Unit.alive(attacker_unit) and ScriptUnit.has_extension(attacker_unit, "buff_system") then
		local buff_extension = ScriptUnit.extension(attacker_unit, "buff_system")

		has_damage_boost = buff_extension:has_buff_type("armor penetration")
	end

	if not has_damage_boost and Unit.alive(attacker_unit) and Unit.alive(target_unit) and ScriptUnit.has_extension(target_unit, "buff_system") then
		local buff_extension = ScriptUnit.extension(target_unit, "buff_system")

		if buff_extension:has_buff_type("increase_incoming_damage") then
			local buff = buff_extension:get_non_stacking_buff("increase_incoming_damage")

			if attacker_unit ~= buff.attacker_unit then
				has_damage_boost = true
			end
		end
	end

	local damage

	if has_damage_boost then
		if target_unit_armor == 1 then
			damage = damage_table[target_unit_armor] * 3
		elseif target_unit_armor == 2 then
			damage = damage_table[1]
		elseif target_unit_armor == 3 then
			damage = damage_table[target_unit_armor] * 2
		end
	elseif attacker_unit and table.contains(PLAYER_AND_BOT_UNITS, target_unit) and table.contains(PLAYER_AND_BOT_UNITS, attacker_unit) then
		if #damage_table > 3 then
			damage = damage_table[PLAYER_TARGET_ARMOR]
		else
			damage = 1
		end
	else
		damage = damage_table[target_unit_armor]
	end

	if hit_zone_name == "head" or hit_zone_name == "neck" and not headshot_multiplier == -1 then
		if headshot_multiplier and damage > 0 then
			damage = damage * headshot_multiplier
		elseif target_unit_armor == 2 and damage == 0 then
			damage = headshot_multiplier or 1
		elseif target_unit_armor == 3 then
			damage = damage * 1.5
		elseif target_unit_armor == 2 then
			damage = damage + 0.5
		else
			damage = damage + 1
		end
	end

	if backstab_multiplier then
		damage = damage * backstab_multiplier
	end

	return damage
end
