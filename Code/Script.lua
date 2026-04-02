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
    -- Outposts
    {
        -- Fort L'Eau Bleu
        name = "Fort L'Eau Bleu (H4)",
        source = "H4",
        group = "H4",
        targets = {
            "H3", "I2", "I3", -- Ernie Island
            "B2", "B3", "B4", "B5", "C3", "C4", "C5", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", -- Camp Savane
            "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13", "D9", "D11", "D12", "E10", "E11", "E12", -- Camp Grand Prix
            "F9", "F10", "F11", "F12", "G9", "G11", "G12", "H10", "H11", "I10", "I11", "J8", "J9", "J10", "J11", "K11", "L7", "L10", "L11", -- Camp La Barriere
        },
        squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        squads_strong = { "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_SpecOps_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "H4",
            }),
            PlaceObj('QuestIsTCEState', {
                Prop = "TCE_SwitchGuardpostAttackSquads",
                QuestId = "04_Betrayal",
                Value = "done",
            }),
            PlaceObj('QuestIsVariableBool', {
                QuestId = "05_TakeDownCorazon",
                Vars = set_neg("Completed"),
            }),
        },
    },
    {
        -- Camp Savane
        name = "Camp Savane (F7)",
        source = "F7",
        group = "F7",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C5", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_SpecOps_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "F7",
            }),
        },
    },
    {
        -- Camp La Barrière
        name = "Camp La Barrière (G10)",
        source = "G10",
        group = "G10",
        targets = { "F9", "F10", "F11", "F12", "G9", "G11", "G12", "H10", "H11", "I10", "I11", "J8", "J9", "J10", "J11", "K11", "L7", "L10", "L11" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Ordnance_Easy", "LegionAttackers_Shock_Easy", },
        squads_strong = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Ordnance_Hard", "LegionAttackers_Shock_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_SpecOps_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "G10",
            }),
        },
    },
    {
        --Camp Grand Prix
        name = "Camp Grand Prix (D10)",
        source = "D10",
        group = "D10",
        targets = { "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13", "D9", "D11", "D12", "E10", "E11", "E12" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", },
        squads_strong = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Marksmen_Hard", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        endgame_squads_strong = { "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_SpecOps_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "D10",
            }),
        },
    },
    {
        -- Camp du Crocodile
        name = "Camp du Crocodile (H14)",
        source = "H14",
        group = "H14",
        targets = { "G13", "G14", "G15", "H13", "H15", "H16", "I12", "I13", "I16", "J12", "J16", "K12", "K13", "K14", "K15" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Shock_Easy", },
        squads_strong = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Shock_Hard", },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", },
        endgame_squads_strong = { "ArmyAttackers_Balanced_Hard", "ArmyAttackers_Shock_Hard", "ArmyAttackers_Siege_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "H14",
            }),
        },
    },
    {
        -- Camp Chien Sauvage
        name = "Camp Chien Sauvage (E16)",
        source = "E16",
        group = "E16",
        targets = { "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Ordnance_Easy", },
        squads_strong = { "LegionAttackers_Shock_Hard", "LegionAttackers_Ordnance_Hard", },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", },
        endgame_squads_strong = { "ArmyAttackers_Balanced_Hard", "ArmyAttackers_Shock_Hard", "ArmyAttackers_Siege_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "E16",
            }),
        },
    },
    {
        -- Camp Bien Chien
        name = "Camp Bien Chien (F19)",
        source = "F19",
        group = "F19",
        targets = { "E20", "F20", "G19", "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", },
        squads_strong = { "LegionAttackers_Shock_Hard", "LegionAttackers_Balanced_Hard", "LegionAttackers_Marksmen_Hard", },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", },
        endgame_squads_strong = { "ArmyAttackers_Balanced_Hard", "ArmyAttackers_Shock_Hard", "ArmyAttackers_Siege_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "F19",
            }),
        },
    },
    {
        -- The Eagle's Nest
        name = "The Eagle's Nest (A20)",
        source = "A20",
        group = "A20",
        targets = { "A16", "A17", "A18", "A19", "B16", "B17", "B18", "B19", "B20" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", },
        squads_strong = { "LegionAttackers_Ordnance_Hard", "LegionAttackers_Marksmen_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "A20",
            }),
            PlaceObj('QuestIsVariableBool', {
                QuestId = "05_TakeDownMajor",
                Vars = set_neg("Completed"),
            }),
        },
    },
    {
        -- Fort Brigand
        name = "Fort Brigand (K16)",
        source = "K16",
        group = "K16",
        targets = {
            "G13", "G14", "G15", "H13", "H15", "H16", "I12", "I13", "I16", "J12", "J16", "K12", "K13", "K14", "K15", -- Camp Du Crocodile
            "E20", "F20", "G19", "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20", -- Camp Bien Chien
            "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15", -- Camp Chien Sauvage
        },
        squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", },
        squads_strong = { "ArmyAttackers_Balanced_Hard", "ArmyAttackers_Shock_Hard", "ArmyAttackers_Siege_Hard", },
        conditions = {
            PlaceObj('SectorCheckOwner', {
                Negate = true,
                sector_id = "K16",
            }),
            PlaceObj('QuestIsTCEState', {
                Prop = "TCE_SwitchGuardpostAttackSquads",
                QuestId = "04_Betrayal",
                Value = "done",
            }),
            PlaceObj('QuestIsVariableBool', {
                QuestId = "05_TakeDownFaucheux",
                Vars = set_neg("Completed"),
            }),
        },
    },

    -- Wilderness Regions
    {
        -- Barrens
        name = "Barrens",
        group = "Barrens",
        targets = { "A16", "A17", "A18", "A19", "B16", "B17", "B18", "B19", "B20" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas", },
    },
    {
        -- Cursed Forest
        name = "Cursed Forest",
        group = "CursedForest",
        targets = { "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Ordnance_Easy", },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", },
    },
    {
        -- East Swamp
        name = "East Swamp",
        group = "EastSwamp",
        targets = { "E20", "F20", "G19" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", "LCFYA_Crocodiles", },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", "LCFYA_Crocodiles", },
    },
    {
        -- Ernie
        name = "Ernie",
        group = "Ernie",
        targets = { "H3", "I2", "I3" },
        squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        conditions = {
            PlaceObj('QuestIsTCEState', {
                Prop = "TCE_SwitchGuardpostAttackSquads",
                QuestId = "04_Betrayal",
                Value = "done",
            }),
        },
    },
    {
        -- Farmland
        name = "Farmland",
        group = "Farmland",
        targets = { "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20" },
        squads = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", },
    },
    {
        -- Great Forest
        name = "Great Forest",
        group = "GreatForest",
        targets = { "D11", "D12", "E10", "E11", "E12", "F9", "F10", "F11", "F12", "G9", "G11", "G12", "G13", "H10", "H11", "I10", "I11", "I12" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Ordnance_Easy", "LegionAttackers_Shock_Easy" },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", },
        is_zombie_area = true,
    },
    {
        -- Highlands
        name = "Highlands",
        group = "Highlands",
        targets = { "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", "LCFYA_Hyenas", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas", },
    },
    {
        -- Savannah North
        name = "Savannah North",
        group = "SavannahNorth",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C5", "C6", "D4", "D5", "D9" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas", },
    },
    {
        -- Savannah South
        name = "Savannah South",
        group = "SavannahSouth",
        targets = { "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
        squads = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas", },
        endgame_squads = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas", },
    },
    {
        -- South Jungle
        name = "South Jungle",
        group = "SouthJungle",
        targets = { "J9", "J10", "J11", "J12", "K11", "K12", "K13", "K14", "K15", "L7", "L10", "L11" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Ordnance_Easy", "LegionAttackers_Shock_Easy", },
        endgame_squads = {
            "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy",
            "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy"
        },
        is_zombie_area = true,
    },
    {
        -- Wetlands
        name = "Wetlands",
        group = "Wetlands",
        targets = { "G14", "G15", "H13", "H15", "H16", "I13", "I16", "J16" },
        squads = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Shock_Easy", "LCFYA_Crocodiles" },
        endgame_squads = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", "LCFYA_Crocodiles", },
        is_zombie_area = true,
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

    if config.is_zombie_area then
        local quest = QuestGetState("Sanatorium")
        local zombie_outbreak = quest and quest.MangelTimerGiven and not (quest.Completed or quest.Failed)

        if zombie_outbreak then
            return "LCFYA_Infected"
        end
    end

    local quest = QuestGetState("04_Betrayal")
    local betray_happened = quest and quest.TCE_SwitchGuardpostAttackSquads == "done"

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

function ShuffleTables()
    for _, config in ipairs(attack_configurations) do
        local config_rng_seed = rng_seed .. config.group
        table.shuffle(config.targets, config_rng_seed)
        table.shuffle(config.endgame_targets, config_rng_seed)

        table.shuffle(config.squads, config_rng_seed)
        table.shuffle(config.squads_strong, config_rng_seed)

        table.shuffle(config.endgame_squads, config_rng_seed)
        table.shuffle(config.endgame_squads_strong, config_rng_seed)
    end
end

-- Debug world state
function DumpQuestVariables()
    print("[LCFYA]   » Checking quest status")
    
    local guard_post_attack_squads_switched = EvalConditionList({ PlaceObj('QuestIsTCEState', { Prop = "TCE_SwitchGuardpostAttackSquads", QuestId = "04_Betrayal", Value = "done", }), })
    local faucheux_taken_down = EvalConditionList({ PlaceObj('QuestIsVariableBool', { QuestId = "05_TakeDownFaucheux", Vars = set("Completed"), }) })
    local corazon_taken_down = EvalConditionList({ PlaceObj('QuestIsVariableBool', { QuestId = "05_TakeDownCorazon", Vars = set("Completed"), }) })

    print(string.format("[LCFYA]     - Guard post switch done: %s", tostring(guard_post_attack_squads_switched)))
    print(string.format("[LCFYA]     - TakeDownFaucheux completed: %s", tostring(faucheux_taken_down)))
    print(string.format("[LCFYA]     - TakeDownCorazon completed: %s", tostring(corazon_taken_down)))
end

-- The Hourly Logic Hook
function OnMsg.NewHour()
    local today = GetCurrentCampaignDay()

    print(string.format("[LCFYA] Hourly check for attacks: %s - %02d:00", GetDateStringFromDay(today), ((Game.CampaignTime % const.Scale.day) / const.Scale.h)))

    DumpQuestVariables()

    for _, config in ipairs(attack_configurations) do
        if IsActive(config) then
            print(string.format("[LCFYA] Checking configuration for %s", config.name))

            local can_attack = EvalConditionList(config.conditions)

            print(string.format("[LCFYA]   » Can attack: %s", tostring(can_attack)))

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
                    local last_attack_timestamp = gv_LCFYA_LastAttackTimestamps[config.group] or -1

                    -- Sanity check for timestamp in case a previous savegame leaked through
                    if last_attack_timestamp > today then
                        print(string.format("[LCFYA]   » [Warning] Invalid timestamp detected: %s (Today %s). Resetting.", GetDateStringFromDay(last_attack_timestamp), GetDateStringFromDay(today)))
                        gv_LCFYA_LastAttackTimestamps[config.group] = -1
                        last_attack_timestamp = -1
                    end

                    -- The Core Check:
                    -- a) Cooldown check (Has enough time passed since the last attack?)
                    local current_cooldown = GetCooldown(config)
                    print(string.format("[LCFYA]   » Last attack: %s - Today: %s - Cooldown: %d day(s)", GetDateStringFromDay(last_attack_timestamp), GetDateStringFromDay(today), current_cooldown))
                    local time_passed = (last_attack_timestamp < 0) or (today >= last_attack_timestamp + current_cooldown)

                    if time_passed then
                        print("[LCFYA]   » Time check passed")
                        local config_rng_seed = rng_seed .. config.group

                        -- b) Probability check (Weighted hourly roll for daily probability)
                        local success = InteractionRand(10000, config_rng_seed) < GetHourlyThreshold(config)

                        if success then
                            print("[LCFYA]   » Hourly threshold RNG check passed")
                            local attack_squad = PickAttackSquad(config)
                            if attack_squad then
                                print(string.format("[LCFYA]   » Launching attack with '%s' from %s to %s", attack_squad, config.name, valid_target))

                                -- Trigger the attack programmatically
                                local effect = TriggerSquadAttack:new({
                                    Squad = attack_squad,
                                    effect_target_sector_ids = { valid_target },
                                    source_sector_id = config.source or valid_target,
                                })
                                effect:__exec()

                                -- Update timestamp and shuffle for variety
                                print(string.format("[LCFYA]   » Setting last attack for %s to %s", config.group, GetDateStringFromDay(today)))
                                gv_LCFYA_LastAttackTimestamps[config.group] = today

                                print(string.format("[LCFYA]   » Shuffling sector and squad tables for %s", config.group))

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
end

-- Synchronize Mod Options
function OnMsg.ApplyModOptions(id)
    if id ~= CurrentModId then return end

    print("[LCFYA] Applying mod options")

    -- Reset the cooldowns
    ResetTimestamps()
    ShuffleTables()

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
    ShuffleTables()
end

function OnMsg.LoadSessionData()
    print("[LCFYA] Save game loaded")
    local today = GetCurrentCampaignDay()

    print("[LCFYA]   » Performing sanity check on timestamps")

    for _, config in ipairs(attack_configurations) do
        -- Sanity check for timestamp in case a previous savegame leaked through
        local last_attack_timestamp = gv_LCFYA_LastAttackTimestamps[config.group] or -1

        if last_attack_timestamp > today then
            print(string.format("[LCFYA]   » [Warning] Invalid timestamp detected: %d (Today %d). Resetting.", last_attack_timestamp, today))
            gv_LCFYA_LastAttackTimestamps[config.group] = -1
        end
    end

    ShuffleTables()
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
			'UnitCountMin', 10,
			'UnitCountMax', 10,
		}),
	},
	displayName = T(548200000001, "Hyena Pack"),
	group = "Mod_LCFYA Custom Squads",
	id = "LCFYA_Hyenas",
})

PlaceObj('EnemySquads', {
	Units = {
		PlaceObj('EnemySquadUnit', {
			'weightedList', {
				PlaceObj('UnitTypeListWithWeights', {
					'unitType', "SanatoriumNPC_Infected",
					'spawnWeight', 10,
				}),
			},
			'UnitCountMin', 10,
			'UnitCountMax', 10,
		}),
	},
	displayName = T(739205028532, "Unknown Entities"),
	group = "Mod_LCFYA Custom Squads",
	id = "LCFYA_Infected",
})

PlaceObj('EnemySquads', {
	Units = {
		PlaceObj('EnemySquadUnit', {
			'weightedList', {
				PlaceObj('UnitTypeListWithWeights', {
					'unitType', "Beast_Crocodile",
					'spawnWeight', 10,
				}),
			},
			'UnitCountMin', 6,
			'UnitCountMax', 6,
		}),
	},
	displayName = T(233951801999, "Unknown Enemies"),
	group = "Mod_LCFYA Custom Squads",
	id = "LCFYA_Crocodiles",
})