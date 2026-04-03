-- Persist attack timestamps in savegame
GameVar("gv_LCFYA_LastAttackTimestamps", {})

-- Custom Squads
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

-- Infected
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

-- Crocodiles
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

-- Helper to check if a sector is NOT owned by the player.
-- Returns a SectorCheckOwner object with Negate set to true.
local function NotOwned(sector_id)
    return PlaceObj('SectorCheckOwner', { Negate = true, sector_id = sector_id })
end

-- Helper to check if a specific boolean variable is set to true for a quest.
-- Returns a QuestIsVariableBool object.
local function IsTrue(quest_id, quest_bool_variable)
    return PlaceObj('QuestIsVariableBool', { QuestId = quest_id, Vars = set(quest_bool_variable), })
end

-- Helper to check if a specific boolean variable is set to false (negated) for a quest.
-- Returns a QuestIsVariableBool object.
local function IsFalse(quest_id, quest_bool_variable)
    return PlaceObj('QuestIsVariableBool', { QuestId = quest_id, Vars = set_neg(quest_bool_variable), })
end

-- Helper to check if a quest's 'Completed' variable is true.
-- Returns a QuestIsVariableBool object.
local function IsCompleted(quest_id)
    return IsTrue(quest_id, "Completed")
end

-- Helper to check if a quest's 'Completed' variable is false (not yet completed).
-- Returns a QuestIsVariableBool object.
local function IsNotCompleted(quest_id)
    return IsFalse(quest_id, "Completed")
end

-- Helper to check if a quest's 'Failed' variable is true.
-- Returns a QuestIsVariableBool object.
local function IsFailed(quest_id)
    return IsTrue(quest_id, "Failed")
end

-- Helper to check if a quest has been given to the player.
-- Returns a QuestIsVariableBool object.
local function IsGiven(quest_id)
    return IsTrue(quest_id, "Given")
end

-- Helper to check if a quest has not yet been given to the player.
-- Returns a QuestIsVariableBool object.
local function IsNotGiven(quest_id)
    return IsFalse(quest_id, "Given")
end

-- Combines multiple conditions into a single logical "OR" check.
-- Returns a CheckOR object where if any condition is met, the whole object evaluates to true.
local function AnyOf(...)
    return PlaceObj('CheckOR', { Conditions = { ... }, })
end

-- Helper to check if a quest is either completed or has failed.
-- Returns a CheckOR object containing IsCompleted and IsFailed conditions.
local function IsCompletedOrFailed(quest_id)
    return AnyOf(IsCompleted(quest_id), IsFailed(quest_id))
end

-- Helper to check for a specific Triggered Conditional Event (TCE) state.
-- Returns a QuestIsTCEState object for the given quest, property, and optional value (default: "done").
local function IsTCEState(quest_id, prop, value)
    return PlaceObj('QuestIsTCEState', { QuestId = quest_id, Prop = prop, Value = value or "done" })
end

-- Helper to check if a specific TCE state is NOT a certain value (default: not "done").
-- Returns a QuestIsTCEState object with the Negate property set to true.
local function IsNotTCEState(quest_id, prop, value)
    return PlaceObj('QuestIsTCEState', { QuestId = quest_id, Prop = prop, Value = value or "done", Negate = true })
end

-- Helper to check if the endgame phase has started.
-- This is defined by the TCE_SwitchGuardpostAttackSquads event in the '04_Betrayal' quest.
local function IsEndgame()
    return IsTCEState("04_Betrayal", "TCE_SwitchGuardpostAttackSquads")
end

-- Helper to check if a group of NPCs is dead.
-- Returns a GroupIsDead object.
local function IsGroupDead(group_id)
    return PlaceObj('GroupIsDead', { Group = group_id, })
end

-- Helper to check if a custom quest related squad has been defeated.
-- Returns a SquadDefeated object.
local function IsSquadDefeated(squad_id)
    return PlaceObj('SquadDefeated', { custom_squad_id = squad_id, })
end

-- Helper to check if an objective to lower an outpost's guard strength has been completed.
-- Returns a GuardpostObjectiveDone object.
local function IsGuardpostObjectiveDone(objective_id)
    return PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = objective_id, })
end

-- Helper to check if Flay's quest has reached a resolved state (dead, recruited, etc.)
local function IsFlayResolved()
    return AnyOf(
        IsCompletedOrFailed("HunterHunted"),
        IsTrue("HunterHunted", "FlayDead"),
        IsTrue("HunterHunted", "FlayRecruited"),
        IsTrue("HunterHunted", "FlayHunting"),
        IsTrue("HunterHunted", "FlayPacified"),
        IsTrue("HunterHunted", "FlayCampCombat_Flay")
    )
end

-- Helper to check if a zombie outbreak is active in the Sanatorium.
-- Returns true if the Mangel timer has been given and the quest is neither completed nor failed.
local function IsZombieOutbreakActive()
    local quest = QuestGetState("Sanatorium")
    return quest and quest.MangelTimerGiven and not (quest.Completed or quest.Failed)
end

-- Merges two arrays (t1 and t2) into a new table.
-- Returns a new table containing elements from t1 followed by elements from t2.
local function ConcatTables(t1, t2)
    local result = {}
    for _, v in ipairs(t1) do
        result[#result + 1] = v
    end
    for _, v in ipairs(t2) do
        result[#result + 1] = v
    end
    return result
end

-- Sector to Quest Safety Conditions Lookup Table
local sector_quest_conditions = {
    -- Savannah North
    ["B2"] = {}, ["B3"] = {}, ["B5"] = {}, ["C3"] = {}, ["C4"] = {}, ["D4"] = {}, ["D5"] = {},
    ["B4"] = { AnyOf(IsFalse("HunterHunted", "FlaySpawned"), IsFlayResolved()), },
    ["C5"] = { AnyOf(IsNotGiven("NeverHitAGirl"), IsGroupDead("AbuserPoacher_Main"), IsCompletedOrFailed("NeverHitAGirl")), },
    ["C6"] = { AnyOf(IsFalse("HunterHunted", "FlaySpawned"), IsFlayResolved()), },
    ["D6"] = { AnyOf(IsNotGiven("NeverHitAGirl"), IsGroupDead("AbuserOutskirts_Main"), IsCompletedOrFailed("NeverHitAGirl")), },
    ["D9"] = { AnyOf(IsCompletedOrFailed("RefugeeBlues"), IsTrue("RefugeeBlues", "ClaudetteSaved"), IsTrue("RefugeeBlues", "ClaudetteDead")), },

    -- Savannah South
    ["E4"] = {}, ["E5"] = {}, ["F5"] = {}, ["F6"] = {}, ["G7"] = {}, ["H6"] = {}, ["I7"] = {}, ["I8"] = {}, ["J8"] = {},
    ["E6"] = {
        AnyOf(IsNotGiven("ReduceSavannaCampStrength"), IsGuardpostObjectiveDone("BaitOutWithActivity")),
        AnyOf(IsFalse("HunterHunted", "FlaySpawned"), IsFlayResolved()),
    },
    ["E7"] = {
        AnyOf(IsNotGiven("ReduceSavannaCampStrength"), IsGuardpostObjectiveDone("BaitOutWithActivity")),
        AnyOf(IsCompletedOrFailed("PantagruelDramas"), IsNotTCEState("PantagruelDramas", "TCE_ChimurengaEnemySquad"), IsSquadDefeated("ChimurengaEnemySquad_Dead")),
    },
    ["E8"] = { AnyOf(IsNotGiven("ReduceSavannaCampStrength"), IsGuardpostObjectiveDone("BaitOutWithActivity")), },
    ["F8"] = { AnyOf(IsNotGiven("ReduceSavannaCampStrength"), IsGuardpostObjectiveDone("BaitOutWithActivity")), },
    ["G6"] = { IsGuardpostObjectiveDone("WaterWell"), },

    -- Highlands - "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13"
    ["A9"] = { IsCompleted("RescueBiff") },
    ["A10"] = { IsCompleted("MiddleOfNowhere") },
    ["A11"] = { IsCompleted("MiddleOfNowhere") },
    ["B8"] = { IsCompleted("RescueBiff") },
    ["B9"] = { IsCompleted("ReduceCrossroadsCampStrength") }, -- Pit Stop
    ["B10"] = {},
    ["C9"] = {},
    ["C10"] = { IsCompleted("Landsbach") }, -- Mad Max
    ["C11"] = { IsCompleted("Landsbach") }, -- Gas Station
    ["C12"] = {},
    ["C13"] = {},

    -- Great Forest / Sanatorium / Fleatown - "D11", "D12", "E10", "E11", "E12", "F9", "F10", "F11", "F12", "G9", "G11", "G12", "G13", "H10", "H11", "I10", "I11", "I12"
    -- Check ReduceBarrierCampStrength!!! (Likely irrelevant, H10, Fleatown and N-Night)
    ["D11"] = {},
    ["D12"] = {},
    ["E10"] = {},
    ["E11"] = {},
    ["E12"] = {},
    ["F9"] = { IsCompleted("VoodooCult"), IsCompleted("FleatownGeneral"), IsCompleted("PiratesGold") },
    ["F10"] = {},
    ["F11"] = {},
    ["F12"] = { IsCompleted("VoodooCult"), IsCompleted("FleatownGeneral"), IsCompleted("PiratesGold") },
    ["G9"] = {},
    ["G11"] = {},
    ["G12"] = {},
    ["G13"] = {},
    ["H10"] = {}, -- Boat with explosives
    ["H11"] = {},
    ["I10"] = { IsCompleted("VoodooCult"), IsCompleted("FleatownGeneral"), IsCompleted("PiratesGold") },
    ["I11"] = {},
    ["I12"] = { IsCompleted("Sanatorium") },

    -- South Jungle - "J9", "J10", "J11", "J12", "K11", "K12", "K13", "K14", "K15", "L7", "L10", "L11"
    ["J9"] = {},
    ["J10"] = {},
    ["J11"] = { IsCompleted("Sanatorium") },
    ["J12"] = {},
    ["K11"] = {},
    ["K12"] = {},
    ["K13"] = {},
    ["K14"] = { IsCompleted("Sanatorium") },
    ["K15"] = { IsCompleted("Sanatorium"), IsCompleted("04_Betrayal") },
    ["L7"] = {},
    ["L10"] = {},
    ["L11"] = {},

    -- Wetlands - "G14", "G15", "H13", "H15", "H16", "I13", "I16", "J16"
    ["G14"] = {},
    ["G15"] = { IsCompleted("VoodooCult"), IsCompleted("WetlandsSideQuests") },
    ["H13"] = { IsCompleted("ReduceCrocodileCampStrength") },
    ["H15"] = { IsCompleted("VoodooCult"), IsCompleted("WetlandsSideQuests") },
    ["H16"] = { IsCompleted("Sanatorium") },
    ["I13"] = {},
    ["I16"] = {},
    ["J16"] = {},

    -- Cursed Forest - "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15"
    ["C14"] = { IsCompleted("CursedForestSideQuests") },
    ["C15"] = {},
    ["C16"] = { IsCompleted("CursedForestSideQuests") },
    ["D13"] = { IsCompleted("CursedForestSideQuests") },
    ["D14"] = { IsCompleted("CursedForestSideQuests") },
    ["D15"] = { IsCompleted("ReduceRiverCampStrength") },
    ["D16"] = { IsCompleted("CursedForestSideQuests") },
    ["D19"] = { IsCompleted("CharonsBoat") },
    ["D20"] = { IsCompleted("CharonsBoat") },
    ["E13"] = { IsCompleted("CursedForestSideQuests") },
    ["E14"] = {},
    ["E15"] = { IsCompleted("CursedForestSideQuests") },

    -- East Swamp
    ["F20"] = {},
    ["E20"] = { IsGuardpostObjectiveDone("FreePrisoners"), },
    ["G19"] = { IsGuardpostObjectiveDone("SlaversGroup"), },

    -- Farmland
    ["I20"] = {}, ["K20"] = {}, ["L17"] = {}, ["L20"] = {},
    ["J18"] = { IsCompletedOrFailed("Witch") },
    ["J19"] = { AnyOf(IsFalse("Ted", "TedSpawn"), IsCompleted("Ted")), },
    ["J20"] = { AnyOf(IsFalse("Ted", "TedSpawn"), IsCompleted("Ted")), },
    ["K17"] = { AnyOf(IsFalse("Ted", "TedSpawn"), IsCompleted("Ted")), },
    ["K18"] = { AnyOf(IsFalse("Ted", "TedSpawn"), IsCompleted("Ted")), },
    ["K19"] = { AnyOf(IsFalse("Ted", "TedSpawn"), IsCompleted("Ted")), },
    ["L19"] = { AnyOf(IsFalse("Ted", "TedSpawn"), IsCompleted("Ted")), },

    -- Barrens / Eagle's Nest
    ["A16"] = {}, ["A17"] = {}, ["A18"] = {}, ["A19"] = {}, ["B17"] = {}, ["B18"] = {}, ["B19"] = {}, ["B20"] = {},
    ["B16"] = { AnyOf(IsCompletedOrFailed("RescueBiff"), IsFalse("RescueBiff", "MajorAttackStarted"), IsSquadDefeated("SquadToAttackBif")), },

    -- Ernie
    ["H3"] = { IsEndgame() },
    ["I2"] = { IsEndgame() },
    ["I3"] = { IsEndgame() },
}

-- Shared squad lists to reduce repetition
local squads_adonis_easy = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy" }
local squads_adonis_hard = { "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_SpecOps_Hard" }
local squads_army_easy = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy" }
local squads_army_hard = { "ArmyAttackers_Balanced_Hard", "ArmyAttackers_Shock_Hard", "ArmyAttackers_Siege_Hard" }
local squads_legion_savane_easy = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy" }
local squads_legion_savane_hard = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard" }
local squads_legion_barriere_easy = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Ordnance_Easy", "LegionAttackers_Shock_Easy" }
local squads_legion_barriere_hard = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Ordnance_Hard", "LegionAttackers_Shock_Hard" }
local squads_legion_grandprix_easy = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy" }
local squads_legion_grandprix_hard = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Marksmen_Hard" }
local squads_legion_crocodile_easy = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Shock_Easy" }
local squads_legion_crocodile_hard = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Shock_Hard" }
local squads_legion_chiensauvage_easy = { "LegionAttackers_Shock_Easy", "LegionAttackers_Ordnance_Easy" }
local squads_legion_chiensauvage_hard = { "LegionAttackers_Shock_Hard", "LegionAttackers_Ordnance_Hard" }
local squads_legion_bienchien_easy = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy" }
local squads_legion_bienchien_hard = { "LegionAttackers_Shock_Hard", "LegionAttackers_Balanced_Hard", "LegionAttackers_Marksmen_Hard" }
local squads_legion_major_easy = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy" }
local squads_legion_major_hard = { "LegionAttackers_Ordnance_Hard", "LegionAttackers_Marksmen_Hard" }

-- Squads including wildlife
local squads_wild_barrens = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas" }
local squads_wild_swamp = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", "LCFYA_Crocodiles" }
local squads_wild_swamp_endgame = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", "LCFYA_Crocodiles" }
local squads_wild_highlands = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", "LCFYA_Hyenas" }
local squads_wild_highlands_endgame = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas" }
local squads_wild_savannah = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas" }
local squads_wild_savannah_endgame = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas" }
local squads_wild_wetlands = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Shock_Easy", "LCFYA_Crocodiles" }
local squads_wild_wetlands_endgame = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", "LCFYA_Crocodiles" }

local squads_southjungle_endgame = ConcatTables(squads_adonis_easy, squads_army_easy)

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
        squads = squads_adonis_easy,
        squads_strong = squads_adonis_hard,
        conditions = { NotOwned("H4"), IsEndgame(), IsNotCompleted("05_TakeDownCorazon"), },
    },
    {
        -- Camp Savane
        name = "Camp Savane (F7)",
        source = "F7",
        group = "F7",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C5", "C6", "D4", "D5", "D6", "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8" },
        squads = squads_legion_savane_easy,
        squads_strong = squads_legion_savane_hard,
        endgame_squads = squads_adonis_easy,
        endgame_squads_strong = squads_adonis_hard,
        conditions = { NotOwned("F7"), },
    },
    {
        -- Camp La Barrière
        name = "Camp La Barrière (G10)",
        source = "G10",
        group = "G10",
        targets = { "F9", "F10", "F11", "F12", "G9", "G11", "G12", "H10", "H11", "I10", "I11", "J8", "J9", "J10", "J11", "K11", "L7", "L10", "L11" },
        squads = squads_legion_barriere_easy,
        squads_strong = squads_legion_barriere_hard,
        endgame_squads = squads_adonis_easy,
        endgame_squads_strong = squads_adonis_hard,
        conditions = { NotOwned("G10"), },
    },
    {
        --Camp Grand Prix
        name = "Camp Grand Prix (D10)",
        source = "D10",
        group = "D10",
        targets = { "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13", "D9", "D11", "D12", "E10", "E11", "E12" },
        squads = squads_legion_grandprix_easy,
        squads_strong = squads_legion_grandprix_hard,
        endgame_squads = squads_adonis_easy,
        endgame_squads_strong = squads_adonis_hard,
        conditions = { NotOwned("D10"), },
    },
    {
        -- Camp du Crocodile
        name = "Camp du Crocodile (H14)",
        source = "H14",
        group = "H14",
        targets = { "G13", "G14", "G15", "H13", "H15", "H16", "I12", "I13", "I16", "J12", "J16", "K12", "K13", "K14", "K15" },
        squads = squads_legion_crocodile_easy,
        squads_strong = squads_legion_crocodile_hard,
        endgame_squads = squads_army_easy,
        endgame_squads_strong = squads_army_hard,
        conditions = { NotOwned("H14"), },
    },
    {
        -- Camp Chien Sauvage
        name = "Camp Chien Sauvage (E16)",
        source = "E16",
        group = "E16",
        targets = { "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" },
        squads = squads_legion_chiensauvage_easy,
        squads_strong = squads_legion_chiensauvage_hard,
        endgame_squads = squads_army_easy,
        endgame_squads_strong = squads_army_hard,
        conditions = { NotOwned("E16"), },
    },
    {
        -- Camp Bien Chien
        name = "Camp Bien Chien (F19)",
        source = "F19",
        group = "F19",
        targets = { "E20", "F20", "G19", "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20" },
        squads = squads_legion_bienchien_easy,
        squads_strong = squads_legion_bienchien_hard,
        endgame_squads = squads_army_easy,
        endgame_squads_strong = squads_army_hard,
        conditions = { NotOwned("F19"), },
    },
    {
        -- The Eagle's Nest
        name = "The Eagle's Nest (A20)",
        source = "A20",
        group = "A20",
        targets = { "A16", "A17", "A18", "A19", "B16", "B17", "B18", "B19", "B20" },
        squads = squads_legion_major_easy,
        squads_strong = squads_legion_major_hard,
        conditions = { NotOwned("A20"), IsNotCompleted("05_TakeDownMajor"), },
    },
    {
        -- Fort Brigand
        name = "Fort Brigand (K16)",
        source = "K16",
        group = "K16",
        targets = {
            "G13", "G14", "G15", "H13", "H15", "H16", "I12", "I13", "I16", "J12", "J16", "K12", "K13", "K14", "K15", -- Camp du Crocodile
            "E20", "F20", "G19", "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20", -- Camp Bien Chien
            "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15", -- Camp Chien Sauvage
        },
        squads = squads_army_easy,
        squads_strong = squads_army_hard,
        conditions = { NotOwned("K16"), IsEndgame(), IsNotCompleted("05_TakeDownFaucheux"), },
    },

    -- Wilderness Regions
    {
        -- Barrens
        name = "Barrens",
        group = "Barrens",
        targets = { "A16", "A17", "A18", "A19", "B16", "B17", "B18", "B19", "B20" },
        squads = squads_wild_barrens,
    },
    {
        -- Cursed Forest
        name = "Cursed Forest",
        group = "CursedForest",
        targets = { "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" },
        squads = squads_legion_chiensauvage_easy,
        endgame_squads = squads_army_easy,
    },
    {
        -- East Swamp
        name = "East Swamp",
        group = "EastSwamp",
        targets = { "E20", "F20", "G19" },
        squads = squads_wild_swamp,
        endgame_squads = squads_wild_swamp_endgame,
    },
    {
        -- Ernie
        name = "Ernie",
        group = "Ernie",
        targets = { "H3", "I2", "I3" },
        squads = squads_adonis_easy,
        conditions = { IsEndgame(), },
    },
    {
        -- Farmland
        name = "Farmland",
        group = "Farmland",
        targets = { "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20" },
        squads = squads_legion_bienchien_easy,
        endgame_squads = squads_army_easy,
    },
    {
        -- Great Forest
        name = "Great Forest",
        group = "GreatForest",
        targets = { "D11", "D12", "E10", "E11", "E12", "F9", "F10", "F11", "F12", "G9", "G11", "G12", "G13", "H10", "H11", "I10", "I11", "I12" },
        squads = squads_legion_barriere_easy,
        endgame_squads = squads_adonis_easy,
        is_zombie_area = true,
    },
    {
        -- Highlands
        name = "Highlands",
        group = "Highlands",
        targets = { "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13" },
        squads = squads_wild_highlands,
        endgame_squads = squads_wild_highlands_endgame,
    },
    {
        -- Savannah North
        name = "Savannah North",
        group = "SavannahNorth",
        targets = { "B2", "B3", "B4", "B5", "C3", "C4", "C5", "C6", "D4", "D5", "D6", "D9" },
        squads = squads_wild_savannah,
        endgame_squads = squads_wild_savannah_endgame,
    },
    {
        -- Savannah South
        name = "Savannah South",
        group = "SavannahSouth",
        targets = { "E4", "E5", "E6", "E7", "E8", "F5", "F6", "F8", "G6", "G7", "H6", "I7", "I8", "J8" },
        squads = squads_wild_savannah,
        endgame_squads = squads_wild_savannah_endgame,
    },
    {
        -- South Jungle
        name = "South Jungle",
        group = "SouthJungle",
        targets = { "J9", "J10", "J11", "J12", "K11", "K12", "K13", "K14", "K15", "L7", "L10", "L11" },
        squads = squads_legion_barriere_easy,
        endgame_squads = squads_southjungle_endgame,
        is_zombie_area = true,
    },
    {
        -- Wetlands
        name = "Wetlands",
        group = "Wetlands",
        targets = { "G14", "G15", "H13", "H15", "H16", "I13", "I16", "J16" },
        squads = squads_wild_wetlands,
        endgame_squads = squads_wild_wetlands_endgame,
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

-- Returns the current day of the campaign (0-indexed).
-- Uses Game.CampaignTime and const.Scale.day for the calculation.
local function GetCurrentCampaignDay()
    if Game and Game.CampaignTime then
        return math.floor(Game.CampaignTime / const.Scale.day)
    end
    return -1
end

-- Clears the gv_LCFYA_LastAttackTimestamps table.
-- Called when mod options are applied or a new campaign starts to reset attack timers.
local function ResetTimestamps()
    print("[LCFYA]   » Resetting last attack timestamps")
    gv_LCFYA_LastAttackTimestamps = {}
end

-- Determines the list of target sectors for a given attack configuration.
-- Switches to config.endgame_targets if the endgame has started.
local function PickTargets(config)
    local is_endgame = EvalConditionList({ IsEndgame() })

    if is_endgame and config.endgame_targets then
        return config.endgame_targets
    else
        return config.targets
    end
end

-- Evaluates whether an sector is safe to be a target for an attack based on quest progress.
-- Uses the sector_quest_conditions lookup table to check specific quest completion requirements.
-- This prevents attacks from disrupting active quest-related sectors or scripted events.
local function IsSectorQuestSafe(sector_id)
    local conditions = sector_quest_conditions[sector_id]
    if not conditions or #conditions == 0 then
        return true
    end

    return EvalConditionList(conditions)
end

-- Selects the appropriate enemy squad for an attack based on world state.
-- Prioritizes zombie squads if the outbreak is active in a zombie-marked area.
-- Otherwise, picks between easy/strong or standard/endgame squads based on player mine count and quest progress.
local function PickAttackSquad(config)
    print(string.format("[LCFYA]   » Picking attack squad for %s", config.name))

    -- Special case for zombie outbreaks
    if config.is_zombie_area and IsZombieOutbreakActive() then
        return "LCFYA_Infected"
    end

    -- Endgame check
    local is_endgame = EvalConditionList({ IsEndgame() })

    print(string.format("[LCFYA]     - Quest check - Betrayal occurred: %s", tostring(is_endgame)))

    -- Scaling based on player progress (mines owned)
    local num_player_mines = gv_PlayerSectorCounts.Mine or 0
    local use_hard_enemies = num_player_mines > 2

    print(string.format("[LCFYA]     - Player has %d mines - Using hard enemies: %s", num_player_mines, tostring(use_hard_enemies)))

    local chosen_squad = false

    if is_endgame and config.endgame_squads then
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
        print("[LCFYA] [Warning] No valid squad chosen")
    end

    print(string.format("[LCFYA]     - Picked squad '%s'", chosen_squad))

    return chosen_squad
end

-- Returns the hourly success threshold for an attack.
-- Differentiates between Outposts (hourly_threshold) and Wilderness (hourly_threshold_wild).
function GetHourlyThreshold(config)
    if config.source then
        return hourly_threshold
    else
        return hourly_threshold_wild
    end
end

-- Returns the required cooldown (in days) for an attack.
-- Differentiates between Outposts (cooldown) and Wilderness (cooldown_wild).
function GetCooldown(config)
    if config.source then
        return cooldown
    else
        return cooldown_wild
    end
end

-- Checks if a specific category of attack (Outpost or Wilderness) is currently enabled.
-- Attacks are considered inactive if their hourly threshold is set to 0 ("Off").
function IsActive(config)
    if config.source then
        return hourly_threshold ~= 0
    else
        return hourly_threshold_wild ~= 0
    end
end

-- Shuffles the target and squad lists for every configuration to ensure variety in attacks.
-- Uses a stable RNG seed based on the configuration's group ID.
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

-- Logs the status of various world and quest variables to the console for debugging.
-- This helps identify why certain attacks may or may not be triggering.
function DumpQuestVariables()
    print("[LCFYA]   » Checking quest status")

    local guard_post_attack_squads_switched = EvalConditionList({ IsEndgame() })
    local faucheux_taken_down = EvalConditionList({ IsCompleted("05_TakeDownFaucheux") })
    local corazon_taken_down = EvalConditionList({ IsCompleted("05_TakeDownCorazon") })
    local major_taken_down = EvalConditionList({ IsCompleted("05_TakeDownMajor") })

    print(string.format("[LCFYA]     - Guard post switch done: %s", tostring(guard_post_attack_squads_switched)))
    print(string.format("[LCFYA]     - TakeDownFaucheux completed: %s", tostring(faucheux_taken_down)))
    print(string.format("[LCFYA]     - TakeDownCorazon completed: %s", tostring(corazon_taken_down)))
    print(string.format("[LCFYA]     - TakeDownMajor completed: %s", tostring(major_taken_down)))

    local sector_guard_quests = {
        "ReduceCrossroadsCampStrength", "ReduceSavannaCampStrength", "HunterHunted", "TreasureHunting",
        "Docks", "PantagruelDramas", "PantagruelLostAndFound", "MiddleOfXWhere", "RescueBiff",
        "Landsbach", "ErnieSideQuests", "04_Betrayal", "ReduceBarrierCampStrength", "VoodooCult",
        "FleatownGeneral", "PiratesGold", "Sanatorium", "MiddleOfNowhere", "ReduceCrocodileCampStrength",
        "WetlandsSideQuests", "ReduceRiverCampStrength", "CursedForestSideQuests", "CharonsBoat",
        "ReduceBienChienCampStrength", "Ted"
    }

    for _, quest_id in ipairs(sector_guard_quests) do
        local completed = EvalConditionList({ IsCompleted(quest_id) })
        print(string.format("[LCFYA]     - %s completed: %s", quest_id, tostring(completed)))
    end
end

-- Primary logic loop that runs at the start of every in-game hour.
-- Iterates through attack configurations, checks conditions, and rolls for attack success.
-- If successful, it triggers a 'TriggerSquadAttack' effect targeting a player-occupied, quest-safe sector.
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
                    if #playerSquads > 0 and IsSectorQuestSafe(target_sector) then
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
                        print(string.format("[LCFYA] [Warning] Invalid timestamp detected: %s (Today %s). Resetting.", GetDateStringFromDay(last_attack_timestamp), GetDateStringFromDay(today)))
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

-- Synchronizes local variables with settings from the Mod Options menu.
-- This is called whenever options are changed or the game is first initialized.
function OnMsg.ApplyModOptions(id)
    if id ~= CurrentModId then return end

    print("[LCFYA] Applying mod options")

    -- Reset the cooldowns to ensure new settings take effect immediately
    ResetTimestamps()
    ShuffleTables()

    -- Synchronize Outpost attack settings
    local daily_chance = CurrentModOptions and CurrentModOptions['options_chance_lcfya'] or "20"
    hourly_threshold = hourly_chance_map[daily_chance]

    -- Sanity check
    if not hourly_threshold then
        print("[LCFYA] [Warning] hourly_threshold was not set - using fallback")
        hourly_threshold = 93
    end

    if daily_chance == "Off" then
        print("[LCFYA]   » Outpost attacks: Disabled")
    else
        print(string.format("[LCFYA]   » Outpost Attacks: %s%% Daily Chance", daily_chance))
    end

    -- Synchronize Wilderness attack settings
    local daily_chance_wild = CurrentModOptions and CurrentModOptions['options_chance_wild_lcfya'] or "10"
    hourly_threshold_wild = hourly_chance_map[daily_chance_wild]

    -- Sanity check
    if not hourly_threshold_wild then
        print("[LCFYA] [Warning] hourly_threshold_wild was not set - using fallback")
        hourly_threshold_wild = 44
    end

    if daily_chance_wild == "Off" then
        print("[LCFYA]   » Wilderness attacks: Disabled")
    else
        print(string.format("[LCFYA]   » Wilderness Attacks: %s%% Daily Chance", daily_chance_wild))
    end

    -- Update Cooldowns from options
    if CurrentModOptions then
        local opt = CurrentModOptions['options_cooldown_lcfya']
        cooldown = tonumber(opt) or 1

        local opt_wild = CurrentModOptions['options_cooldown_wild_lcfya']
        cooldown_wild = tonumber(opt_wild) or 2

        print(string.format("[LCFYA]   » Minimum Cooldown: %d days (Outposts) / %d days (Wilderness)", cooldown, cooldown_wild))
    end
end

-- Initializes attack state for a brand new campaign.
function OnMsg.InitSessionCampaignObjects()
    print("[LCFYA] New campaign started")
    ResetTimestamps()
    ShuffleTables()
end

-- Validates persistent state and prepares target lists after loading a savegame.
function OnMsg.LoadSessionData()
    print("[LCFYA] Save game loaded")
    local today = GetCurrentCampaignDay()

    print("[LCFYA]   » Performing sanity check on timestamps")

    for _, config in ipairs(attack_configurations) do
        -- Sanity check for timestamp in case a previous savegame leaked through or campaign time was manipulated
        local last_attack_timestamp = gv_LCFYA_LastAttackTimestamps[config.group] or -1

        if last_attack_timestamp > today then
            print(string.format("[LCFYA] [Warning] Invalid timestamp detected: %d (Today %d). Resetting.", last_attack_timestamp, today))
            gv_LCFYA_LastAttackTimestamps[config.group] = -1
        end
    end

    -- Re-shuffle to maintain non-deterministic behavior after load
    ShuffleTables()
end