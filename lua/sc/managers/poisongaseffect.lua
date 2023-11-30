function PoisonGasEffect:init(position, normal, projectile_tweak, grenade_unit)
	self._position = position
	self._normal = normal
	grenade_unit = alive(grenade_unit) and grenade_unit or nil

	if grenade_unit then
		self._grenade_unit = grenade_unit
	end

	self._tweak_data = projectile_tweak
	self._user_unit = grenade_unit and grenade_unit:base():thrower_unit()
	self._is_local_player = grenade_unit and grenade_unit:base():thrower_unit() == managers.player:player_unit()
	self._grenade_id = grenade_unit and grenade_unit:base():projectile_entry()
	self._range = projectile_tweak.poison_gas_range or 1500
	self._timer = projectile_tweak.poison_gas_duration or 25
	self._damage_tick_timer = projectile_tweak.poison_gas_tick_time or 0.1
	self._fade_time = projectile_tweak.poison_gas_fade_time or 2
	self._dot_data = projectile_tweak.poison_gas_dot_data_name and tweak_data.dot:get_dot_data(projectile_tweak.poison_gas_dot_data_name) or tweak_data.dot:get_dot_data("weapon_dotbulletbase")
	self._sound_source = SoundDevice:create_source("ExplosionManager")

	self._sound_source:set_position(position)
	
    self._sound_source:post_event("lung_explode")
    self._sound_source:post_event("grenade_gas_explode")
    self._sound_source:post_event("grenade_gas_stop")	

	self._unit_list = {}
	self._effect = World:effect_manager():spawn({
		effect = self._tweak_data.poison_gas_effect and Idstring(self._tweak_data.poison_gas_effect) or Idstring("effects/particles/explosions/poison_gas"),
		position = position,
		normal = normal
	})
end

function PoisonGasEffect:update(t, dt)
	if self._timer then
		self._timer = self._timer - dt

		if not self._started_fading and self._timer <= self._fade_time then
			World:effect_manager():fade_kill(self._effect)

			self._started_fading = true
		end

		if self._timer <= 0 then
			self._timer = nil

			if alive(self._grenade_unit) and Network:is_server() then
				managers.enemy:add_delayed_clbk("PoisonGasEffect", callback(PoisonGasEffect, PoisonGasEffect, "remove_grenade_unit"), TimerManager:game():time() + self._dot_data.dot_length)
			end
		end

		if self._is_local_player then
			self._damage_tick_timer = self._damage_tick_timer - dt

			if self._damage_tick_timer <= 0 then
				self._damage_tick_timer = self._tweak_data.poison_gas_tick_time or 0.1
				local nearby_units = World:find_units_quick("sphere", self._position, self._range, managers.slot:get_mask("enemies"))

				for _, unit in ipairs(nearby_units) do
					if not table.contains(self._unit_list, unit) then
						local hurt_animation = not self._dot_data.hurt_animation_chance or math.rand(1) < self._dot_data.hurt_animation_chance

						managers.dot:add_doted_enemy(unit, TimerManager:game():time(), self._grenade_unit, self._dot_data.dot_length, self._dot_data.dot_damage, hurt_animation, "poison", self._grenade_id, true)
						table.insert(self._unit_list, unit)
					end
				end
			end
		else
			self._damage_tick_timer = self._damage_tick_timer - dt

			if self._damage_tick_timer <= 0 then
				self._damage_tick_timer = self._tweak_data.poison_gas_tick_time or 0.1
				local nearby_units = World:find_units_quick("sphere", self._position, self._range, managers.slot:get_mask("enemies"))

				for _, unit in ipairs(nearby_units) do
					if not table.contains(self._unit_list, unit) then
						local hurt_animation = not self._dot_data.hurt_animation_chance or math.rand(1) < self._dot_data.hurt_animation_chance

						managers.dot:add_doted_enemy(unit, TimerManager:game():time(), self._grenade_unit, self._dot_data.dot_length, self._dot_data.dot_damage, hurt_animation, "poison", self._grenade_id, true)
						table.insert(self._unit_list, unit)
					end
				end
			end		
		end
	end
end