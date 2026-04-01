GameVar("gv_LCFYA_LastAttackTimestamps", {})

-- Mapping of Daily Percentage Strings to Hourly Thresholds (out of 10,000)
local hourly_chance_map = {
    ["Off"] = 0,
    ["3"]   = 13,
    ["5"]   = 21,
    ["7"]   = 30,
    ["10"]  = 44,
    ["15"]  = 67,
    ["20"]  = 93,
    ["25"]  = 119,
    ["33"]  = 168,
    ["50"]  = 285,
    ["66"]  = 447,
    ["75"]  = 561,
    ["100"] = 10000,
}

-- Global threshold updated via mod options
local hourly_threshold = 93
local cooldown = 1
local hourly_threshold_wild = 44
local cooldown_wild = 2
local rng_seed = "[LCFYA] "

-- Define possible attacks
local attack_configurations = {
    {
        -- Camp Savane
        name = "Camp Savane",
        source = "F7",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    },
    {
        -- Camp Grand Prix
        name = "Camp Grand Prix",
        source = "D10",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    },
    {
        -- Camp La Barriere
        name = "Camp La Barriere",
        source = "G10",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8", "J11", "J12", "J13" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    },
    {
        -- Camp Du Crocodile
        name = "Camp Du Crocodile",
        source = "H14",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8", "J11", "J12", "J13" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    },
    {
        -- Camp Bien Chien
        name = "Camp Bien Chien",
        source = "F19",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    },
    {
        -- Camp Chien Sauvage
        name = "Camp Chien Sauvage",
        source = "E16",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    },
    -- {
    --     -- The Eagle's Nest
    --     name = "The Eagle's Nest",
    --     source = "A20",
    --     targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
    --     squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
    --     squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
    --     endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
    --     endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    -- },
    -- {
    --     -- Fort Brigand
    --     name = "Fort Brigand",
    --     source = "K16",
    --     targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8", "J11", "J12", "J13" },
    --     squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
    --     squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
    --     endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
    --     endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    -- },
    -- {
    --     -- Fort L'Eau Bleu
    --     name = "Fort L'Eau Bleu",
    --     source = "H4",
    --     targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
    --     squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
    --     squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
    --     endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
    --     endgame_squads_strong = { "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_SpecOps_Hard", },
    -- },
    {
        -- Savanna North and South Wilderness
        name = "Savanna",
        targets = { "B3", "B4", "B5", "C4", "C6", "D4", "D5", "E4", "E6", "E7", "E8", "F6", "F8", "G6", "G7", "H6", "I7", "I8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Balanced_Easy", "Hyenas", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_SpecOps_Easy", "Hyenas", },
    },
    {
        -- Savanna North and South Wilderness
        name = "Great Forest",
        targets = { "B3", "B4", "B5", "C4", "C6", "D4", "D5", "E4", "E6", "E7", "E8", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "I11", "I12" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Balanced_Easy", "Hyenas", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_SpecOps_Easy", "Hyenas", },
    },
}

--- Converts a floor-calculated day number into a formatted date string.
function GetDateStringFromDay(day)
    if day < 0 then
        return "<none>"
    end

    -- Convert the day count back into a timestamp (seconds)
    local timestamp = (day * const.Scale.day)

    -- Use the engine's helper to get the date table
    local t = GetTimeAsTable(timestamp)

    if not t then
        return "<none>"
    end

    local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
    local day = t.day
    local month_str = months[t.month]
    local year = t.year

    -- Return the formatted string
    return string.format("%d %s %d", day, month_str, year)
end

-- Utility: Get Current Day
local function GetCurrentCampaignDay()
    if Game and Game.CampaignTime then
        return math.floor(Game.CampaignTime / const.Scale.day)
    end
    return -1
end

local function ResetTimestamps()
    print("[LCFYA]   » Resetting last attack timestamps")
    gv_LCFYA_LastAttackTimestamps = {}
end

-- Pick target sector list based on betray quest status
local function PickTargets(config)
    local quest = QuestGetState("04_Betrayal")
    local betray_happened = quest and quest.TCE_SpawnCaptureSquads == "done"

    if betray_happened and config.endgame_targets then
        return config.endgame_targets
    else
        return config.targets
    end
end

-- Pick squad based on betray quest status and number of player mines
local function PickAttackSquad(config)
    print(string.format("[LCFYA]   » Picking attack squad for %s", config.name))

    local quest = QuestGetState("04_Betrayal")
    local betray_happened = quest and quest.TCE_SpawnCaptureSquads == "done"

    print(string.format("[LCFYA]     - Quest check - Betrayal occurred: %s", tostring(betray_happened)))

    local num_player_mines = gv_PlayerSectorCounts.Mine or 0
    local use_hard_enemies = num_player_mines > 2

    print(string.format("[LCFYA]     - Player has %d mines - Using hard enemies: %s", num_player_mines, tostring(use_hard_enemies)))

    local chosen_squad = false

    if betray_happened and config.endgame_squads then
        if use_hard_enemies and config.endgame_squads_strong then
            chosen_squad = config.endgame_squads_strong[1]
        else
            chosen_squad = config.endgame_squads[1]
        end
    else
        if use_hard_enemies and config.squads_strong then
            chosen_squad = config.squads_strong[1]
        else
            chosen_squad = config.squads[1]
        end
    end

    -- Sanity check
    if not chosen_squad then
        print("[LCFYA]     - [Warning] No valid squad chosen")
    end

    print(string.format("[LCFYA]     - Picked squad '%s'", chosen_squad))

    return chosen_squad
end

-- Get hourly threshold for outpost or wilderness attack
function GetHourlyThreshold(config)
    if config.source then
        return hourly_threshold
    else
        return hourly_threshold_wild
    end
end

-- Get cooldown for outpost or wilderness attack
function GetCooldown(config)
    if config.source then
        return cooldown
    else
        return cooldown_wild
    end
end

-- Check if attack type is active
function IsActive(config)
    if config.source then
        return hourly_threshold ~= 0
    else
        return hourly_threshold_wild ~= 0
    end
end

-- Remove militia for debuggung
function RemoveMilitiaDebug(sector_id)
    local sector = gv_Sectors[sector_id]
    local militia_squads = GetMilitiaSquads(sector)

    for _, squad in ipairs(militia_squads) do
        RemoveSquad(squad)
    end
end

-- The Hourly Logic Hook
function OnMsg.NewHour()
    local today = GetCurrentCampaignDay()

    print(string.format("[LCFYA] Hourly check for attacks: %s - %02d:00", GetDateStringFromDay(today), ((Game.CampaignTime % const.Scale.day) / const.Scale.h)))

    for _, config in ipairs(attack_configurations) do
        if IsActive(config) then
            print(string.format("[LCFYA] Checking configuration for %s", config.name))

            local can_attack = true

            if config.source then
                local source_sector = gv_Sectors[config.source]
                can_attack = source_sector and source_sector.Side ~= "player1"

                if not can_attack then
                    RemoveMilitiaDebug(config.source)
                    can_attack = true
                end
            end

            print(string.format("[LCFYA]   » Can attack %s: %s", config.name, tostring(can_attack)))

            if can_attack then
                local valid_target = false
                local targets = PickTargets(config)

                -- Check if an attack is even possible (Player present?)
                for _, target_sector in ipairs(targets) do
                    local playerSquads = GetSquadsInSector(target_sector, true, false, true, true)
                    if #playerSquads > 0 then
                        valid_target = target_sector
                        break
                    end
                end

                if valid_target then
                    print(string.format("[LCFYA]   » Valid target sector found: %s", valid_target))

                    -- Read the last timestamp from the persistent GameVar
                    local last_attack_timestamp = gv_LCFYA_LastAttackTimestamps[config.name] or -1

                    -- Sanity check for timestamp in case a previous savegame leaked through
                    if last_attack_timestamp > today then
                        print(string.format("[LCFYA]   » [Warning] Invalid timestamp detected: %s (Today %s). Resetting.", GetDateStringFromDay(last_attack_timestamp), GetDateStringFromDay(today)))
                        gv_LCFYA_LastAttackTimestamps[config.name] = -1
                        last_attack_timestamp = -1
                    end

                    -- The Core Check:
                    -- a) Cooldown check (Has enough time passed since the last attack?)
                    local current_cooldown = GetCooldown(config)
                    print(string.format("[LCFYA]   » Last attack: %s - Today: %s - Cooldown: %d day(s)", GetDateStringFromDay(last_attack_timestamp), GetDateStringFromDay(today), current_cooldown))
                    local time_passed = (last_attack_timestamp < 0) or (today >= last_attack_timestamp + current_cooldown)

                    if time_passed then
                        print("[LCFYA]   » Time check passed")
                        local config_rng_seed = rng_seed .. config.name

                        -- b) Probability check (Weighted hourly roll for daily probability)
                        local success = InteractionRand(10000, config_rng_seed) < GetHourlyThreshold(config)

                        if success then
                            print("[LCFYA]   » Hourly threshold RNG check passed")
                            local attack_squad = PickAttackSquad(config)
                            print(string.format("[LCFYA]   » Launching attack with '%s' from %s to %s", attack_squad, config.name, valid_target))

                            -- Trigger the attack programmatically
                            local effect = TriggerSquadAttack:new({
                                Squad = attack_squad,
                                effect_target_sector_ids = { valid_target },
                                source_sector_id = config.source or valid_target,
                            })
                            effect:__exec()

                            -- Update timestamp and shuffle for variety
                            print(string.format("[LCFYA]   » Setting last attack for %s to %s", config.name, GetDateStringFromDay(today)))
                            gv_LCFYA_LastAttackTimestamps[config.name] = today

                            print(string.format("[LCFYA]   » Shuffling sector and squad tables for %s", config.name))

                            table.shuffle(config.targets, config_rng_seed)
                            table.shuffle(config.endgame_targets, config_rng_seed)

                            table.shuffle(config.squads, config_rng_seed)
                            table.shuffle(config.squads_strong, config_rng_seed)

                            table.shuffle(config.endgame_squads, config_rng_seed)
                            table.shuffle(config.endgame_squads_strong, config_rng_seed)
                        end
                    end
                end
            end
        end
    end
end

-- Synchronize Mod Options
function OnMsg.ApplyModOptions(id)
    if id ~= CurrentModId then return end

    print("[LCFYA] Applying mod options")

    -- Reset the cooldowns
    ResetTimestamps()

    -- Get the probability threshold from mod options (defaulting to 20%)
    local daily_chance = CurrentModOptions and CurrentModOptions['options_chance_lcfya'] or "20"
    hourly_threshold = hourly_chance_map[daily_chance]

    -- Sanity check
    if not hourly_threshold then
        print("[LCFYA]   » [Warning] hourly_threshold was not set - using fallback")
        hourly_threshold = 93
    end

    if daily_chance == "Off" then
        print("[LCFYA]   » Outpost attacks: Disabled")
    else
        print(string.format("[LCFYA]   » Outpost Attacks: %s%% Daily Chance", daily_chance))
    end

    -- Get the probability threshold from mod options (defaulting to 20%)
    local daily_chance_wild = CurrentModOptions and CurrentModOptions['options_chance_wild_lcfya'] or "10"
    hourly_threshold_wild = hourly_chance_map[daily_chance_wild]

    -- Sanity check
    if not hourly_threshold_wild then
        print("[LCFYA]   » [Warning] hourly_threshold_wild was not set - using fallback")
        hourly_threshold_wild = 44
    end

    if daily_chance_wild == "Off" then
        print("[LCFYA]   » Wilderness attacks: Disabled")
    else
        print(string.format("[LCFYA]   » Wilderness Attacks: %s%% Daily Chance", daily_chance_wild))
    end

    -- Cooldowns
    if CurrentModOptions then
        local opt = CurrentModOptions['options_cooldown_lcfya']
        cooldown = tonumber(opt) or 1

        local opt_wild = CurrentModOptions['options_cooldown_wild_lcfya']
        cooldown_wild = tonumber(opt_wild) or 2

        print(string.format("[LCFYA]   » Minimum Cooldown: %d days (Outposts) / %d days (Wilderness)", cooldown, cooldown_wild))
    end
end

function OnMsg.InitSessionCampaignObjects()
    print("[LCFYA] New campaign started")
    ResetTimestamps()
end

function OnMsg.LoadSessionData()
    print("[LCFYA] Save game loaded")
    local today = GetCurrentCampaignDay()

    print("[LCFYA]   » Performing sanity check on timestamps")

    for _, config in ipairs(attack_configurations) do
        -- Sanity check for timestamp in case a previous savegame leaked through
        local last_attack_timestamp = gv_LCFYA_LastAttackTimestamps[config.name] or -1

        if last_attack_timestamp > today then
            print(string.format("[LCFYA]   » [Warning] Invalid timestamp detected: %d (Today %d). Resetting.", last_attack_timestamp, today))
            gv_LCFYA_LastAttackTimestamps[config.name] = -1
        end
    end
end

-- Hyenas
PlaceObj('EnemySquads', {
	Units = {
		PlaceObj('EnemySquadUnit', {
			'weightedList', {
				PlaceObj('UnitTypeListWithWeights', {
					'unitType', "Beast_Hyena",
					'spawnWeight', 10,
				}),
			},
			'UnitCountMin', 6,
			'UnitCountMax', 6,
		}),
	},
	group = "Mod_LCFYA Custom Squads",
	id = "Hyenas",
})