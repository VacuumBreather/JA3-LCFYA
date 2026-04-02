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

-- Helper to check if a quest is safe to trigger attacks (completed or effectively done)
local function Safe(quest_id)
    local conditions = {
        PlaceObj('QuestIsVariableBool', { QuestId = quest_id, Vars = set("Completed"), }),
    }

    if quest_id == "ReduceBarrierCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "Poison" }))
    elseif quest_id == "ReduceBienChienCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "SlaversGroup" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "Defector" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "FreePrisoners" }))
    elseif quest_id == "ReduceCrocodileCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "CirclingPatrol" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "InfectedInvasion" }))
    elseif quest_id == "ReduceCrossroadsCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "FridayNightPoker" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "ClaudetteEncounter" }))
    elseif quest_id == "ReduceMajorCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "MineControl" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "OtherGuardpostControl" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "StairControl" }))
    elseif quest_id == "ReduceRiverCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "AlphaHyena" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "Effigies" }))
    elseif quest_id == "ReduceSavannaCampStrength" then
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "AbandonedMansion" }))
        table.insert(conditions, PlaceObj('GuardpostObjectiveDone', { GuardpostObjective = "BaitOutWithActivity" }))
    elseif quest_id == "ErnieSideQuests" then
        table.insert(conditions, PlaceObj('QuestIsVariableBool', { QuestId = "ErnieSideQuests", Vars = set("RustReinforcmentsSpawn"), }))
    elseif quest_id == "PantagruelDramas" then
        table.insert(conditions, PlaceObj('QuestIsVariableBool', { QuestId = "PantagruelDramas", Vars = set("ChimurengaDead"), }))
        table.insert(conditions, PlaceObj('QuestIsVariableBool', { QuestId = "PantagruelDramas", Vars = set("ChimurengaLeave"), }))
        table.insert(conditions, PlaceObj('QuestIsVariableBool', { QuestId = "PantagruelDramas", Vars = set("SucceedChimurenga"), }))
    end

    return PlaceObj('CheckOR', { Conditions = conditions })
end

-- Helper to check if a quest is completed (Simple version)
local function Q(quest_id)
    return PlaceObj('QuestIsVariableBool', {
        QuestId = quest_id,
        Vars = set("Completed"),
    })
end

-- Sector to Quest Safety Conditions Lookup Table
local sector_quest_conditions = {
    -- Savannah North
    ["B2"] = {}, ["B3"] = {}, ["B5"] = {}, ["D4"] = {}, ["D9"] = {},
    ["B4"] = { Q("HunterHunted") },
    ["C3"] = { Q("TreasureHunting") },
    ["C4"] = { Q("Docks") },
    ["C5"] = { Q("PantagruelDramas"), Q("PantagruelLostAndFound") },
    ["D5"] = { Q("PantagruelDramas"), Q("PantagruelLostAndFound") },
    ["C6"] = { Q("HunterHunted") },
    ["D6"] = { Q("PantagruelDramas"), Q("PantagruelLostAndFound") },

    -- Savannah South
    ["E4"] = {}, ["F6"] = {}, ["H6"] = {}, ["I7"] = {}, ["I8"] = {}, ["J8"] = {},
    ["E8"] = { Q("ReduceSavannaCampStrength") },
    ["F8"] = { Q("ReduceSavannaCampStrength") },
    ["G6"] = { Q("ReduceSavannaCampStrength") },
    ["G7"] = { Q("ReduceSavannaCampStrength") },
    ["E5"] = { Q("MiddleOfXWhere") },
    ["E6"] = { Q("HunterHunted") },
    ["E7"] = { Q("PantagruelDramas"), Q("PantagruelLostAndFound") },
    ["F5"] = { Q("PantagruelDramas"), Q("ReduceSavannaCampStrength") }, -- Added from Savannah South Guarded

    -- Highlands
    ["B10"] = {}, ["C9"] = {}, ["C12"] = {}, ["C13"] = {},
    ["B9"] = { Q("ReduceCrossroadsCampStrength") },
    ["C11"] = { Q("Landsbach") },
    ["A9"] = { Q("RescueBiff") },
    ["A10"] = { Q("MiddleOfNowhere") },
    ["A11"] = { Q("MiddleOfNowhere") },
    ["B8"] = { Q("RescueBiff") },
    ["D9"] = {}, -- Savannah North / Highlands border

    -- Great Forest / Sanatorium / Fleatown
    ["D11"] = {}, ["D12"] = {}, ["E10"] = {}, ["E11"] = {}, ["E12"] = {}, ["F10"] = {}, ["F11"] = {}, ["G9"] = {}, ["G11"] = {}, ["G12"] = {}, ["G13"] = {}, ["H10"] = {}, ["H11"] = {}, ["I11"] = {},
    ["F9"] = { Q("VoodooCult"), Q("FleatownGeneral"), Q("PiratesGold") },
    ["F12"] = { Q("VoodooCult"), Q("FleatownGeneral"), Q("PiratesGold") },
    ["I10"] = { Q("VoodooCult"), Q("FleatownGeneral"), Q("PiratesGold") },
    ["I12"] = { Q("Sanatorium") },
    ["J11"] = { Q("Sanatorium") },

    -- South Jungle
    ["J9"] = {}, ["J10"] = {}, ["J12"] = {}, ["K11"] = {}, ["K12"] = {}, ["K13"] = {}, ["L7"] = {}, ["L10"] = {}, ["L11"] = {},
    ["K14"] = { Q("Sanatorium") },
    ["K15"] = { Q("Sanatorium"), Q("04_Betrayal") },

    -- Wetlands
    ["G14"] = {}, ["I13"] = {}, ["I16"] = {}, ["J16"] = {},
    ["H13"] = { Q("ReduceCrocodileCampStrength") },
    ["H14"] = { Q("ReduceCrocodileCampStrength") },
    ["G15"] = { Q("VoodooCult"), Q("WetlandsSideQuests") },
    ["H15"] = { Q("VoodooCult"), Q("WetlandsSideQuests") },
    ["H16"] = { Q("Sanatorium") },

    -- Cursed Forest
    ["C15"] = {}, ["E14"] = {},
    ["D15"] = { Q("ReduceRiverCampStrength") },
    ["C14"] = { Q("CursedForestSideQuests") },
    ["C16"] = { Q("CursedForestSideQuests") },
    ["D13"] = { Q("CursedForestSideQuests") },
    ["D14"] = { Q("CursedForestSideQuests") },
    ["D16"] = { Q("CursedForestSideQuests") },
    ["E13"] = { Q("CursedForestSideQuests") },
    ["E15"] = { Q("CursedForestSideQuests") },
    ["D19"] = { Q("CharonsBoat") },
    ["D20"] = { Q("CharonsBoat") },

    -- Farmland / East Swamp / Ted
    ["F20"] = {}, ["G19"] = {}, ["I20"] = {}, ["L20"] = {},
    ["E20"] = { Q("ReduceBienChienCampStrength") },
    ["J19"] = { Q("Ted") },
    ["J20"] = { Q("Ted") },
    ["K17"] = { Q("Ted") },
    ["K18"] = { Q("Ted") },
    ["K19"] = { Q("Ted") },
    ["L19"] = { Q("Ted") },
    ["J18"] = { Q("Ted") }, -- Farmland Ted targets
    ["K20"] = { Q("Ted") },
    ["L17"] = { Q("Ted") },

    -- Barrens / Eagle's Nest
    ["A16"] = {}, ["A17"] = {}, ["A19"] = {}, ["B17"] = {},
    ["A18"] = { Q("RescueBiff") },
    ["B16"] = { Q("RescueBiff") },
    ["B18"] = { Q("RescueBiff") },
    ["B19"] = { Q("RescueBiff") },
    ["B20"] = { Q("RescueBiff") },

    -- Ernie
    ["H3"] = { Q("ErnieSideQuests"), Q("04_Betrayal") },
    ["I2"] = { Q("ErnieSideQuests"), Q("04_Betrayal") },
    ["I3"] = { Q("ErnieSideQuests"), Q("04_Betrayal") },
}

-- Function to check an sector for quest safety
local function IsSectorQuestSafe(sector_id)
    local conditions = sector_quest_conditions[sector_id]
    if not conditions or #conditions == 0 then
        return true
    end

    return EvalConditionList(conditions)
end

-- Shared squad lists to reduce repetition
local squads_adonis_easy = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy" }
local squads_adonis_hard = { "AdonisAttackers_Demolitions_Hard", "AdonisAttackers_ShockAttack_Hard", "AdonisAttackers_SpecOps_Hard" }
local squads_legion_savane_easy = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Ordnance_Easy" }
local squads_legion_savane_hard = { "LegionAttackers_Marksmen_Hard", "LegionAttackers_Ordnance_Hard" }
local squads_legion_barriere_easy = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Ordnance_Easy", "LegionAttackers_Shock_Easy" }
local squads_legion_barriere_hard = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Ordnance_Hard", "LegionAttackers_Shock_Hard" }
local squads_legion_grandprix_easy = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy" }
local squads_legion_grandprix_hard = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Marksmen_Hard" }
local squads_legion_crocodile_easy = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Shock_Easy" }
local squads_legion_crocodile_hard = { "LegionAttackers_Balanced_Hard", "LegionAttackers_Shock_Hard" }
local squads_army_crocodile_easy = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy" }
local squads_army_crocodile_hard = { "ArmyAttackers_Balanced_Hard", "ArmyAttackers_Shock_Hard", "ArmyAttackers_Siege_Hard" }
local squads_legion_chiensauvage_easy = { "LegionAttackers_Shock_Easy", "LegionAttackers_Ordnance_Easy" }
local squads_legion_chiensauvage_hard = { "LegionAttackers_Shock_Hard", "LegionAttackers_Ordnance_Hard" }
local squads_legion_bienchien_easy = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy" }
local squads_legion_bienchien_hard = { "LegionAttackers_Shock_Hard", "LegionAttackers_Balanced_Hard", "LegionAttackers_Marksmen_Hard" }
local squads_legion_major_easy = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy" }
local squads_legion_major_hard = { "LegionAttackers_Ordnance_Hard", "LegionAttackers_Marksmen_Hard" }

local squads_wild_barrens = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas" }
local squads_wild_swamp = { "LegionAttackers_Shock_Easy", "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", "LCFYA_Crocodiles" }
local squads_wild_swamp_endgame = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", "LCFYA_Crocodiles" }
local squads_wild_highlands = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Marksmen_Easy", "LCFYA_Hyenas" }
local squads_wild_highlands_endgame = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_Demolitions_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas" }
local squads_wild_savannah = { "LegionAttackers_Marksmen_Easy", "LegionAttackers_Balanced_Easy", "LCFYA_Hyenas" }
local squads_wild_savannah_endgame = { "AdonisAttackers_ShockAttack_Easy", "AdonisAttackers_SpecOps_Easy", "LCFYA_Hyenas" }
local squads_wild_wetlands = { "LegionAttackers_Balanced_Easy", "LegionAttackers_Shock_Easy", "LCFYA_Crocodiles" }
local squads_wild_wetlands_endgame = { "ArmyAttackers_Balanced_Easy", "ArmyAttackers_Shock_Easy", "ArmyAttackers_Siege_Easy", "LCFYA_Crocodiles" }

local squads_southjungle_endgame = table.concat(squads_adonis_easy, squads_army_crocodile_easy)

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
        conditions = {
            PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "H4", }),
            PlaceObj('QuestIsTCEState', { Prop = "TCE_SwitchGuardpostAttackSquads", QuestId = "04_Betrayal", Value = "done", }),
            PlaceObj('QuestIsVariableBool', { QuestId = "05_TakeDownCorazon", Vars = set_neg("Completed"), }),
        },
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
        conditions = { PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "F7", }), },
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
        conditions = { PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "G10", }), Q("ReduceBarrierCampStrength"), },
    },
    {
        --Camp Grand Prix
        name = "Camp Grand Prix (D10)",
        source = "D10",
        group = "D10",
        targets = { "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C10", "C11", "C12", "C13", "D11", "D12", "E10", "E11", "E12" },
        squads = squads_legion_grandprix_easy,
        squads_strong = squads_legion_grandprix_hard,
        endgame_squads = squads_adonis_easy,
        endgame_squads_strong = squads_adonis_hard,
        conditions = { PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "D10", }), },
    },
    {
        -- Camp du Crocodile
        name = "Camp du Crocodile (H14)",
        source = "H14",
        group = "H14",
        targets = { "G13", "G14", "G15", "H15", "H16", "I12", "I16", "J12", "J16", "K12", "K13", "K14" },
        squads = squads_legion_crocodile_easy,
        squads_strong = squads_legion_crocodile_hard,
        endgame_squads = squads_army_crocodile_easy,
        endgame_squads_strong = squads_army_crocodile_hard,
        conditions = { PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "H14", }), Q("ReduceCrocodileCampStrength"), },
    },
    {
        -- Camp Chien Sauvage
        name = "Camp Chien Sauvage (E16)",
        source = "E16",
        group = "E16",
        targets = { "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" },
        squads = squads_legion_chiensauvage_easy,
        squads_strong = squads_legion_chiensauvage_hard,
        endgame_squads = squads_army_crocodile_easy,
        endgame_squads_strong = squads_army_crocodile_hard,
        conditions = { PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "E16", }), },
    },
    {
        -- Camp Bien Chien
        name = "Camp Bien Chien (F19)",
        source = "F19",
        group = "F19",
        targets = { "F20", "G19", "I20", "J19", "J20", "K17", "K18", "K19", "L19", "L20" },
        squads = squads_legion_bienchien_easy,
        squads_strong = squads_legion_bienchien_hard,
        endgame_squads = squads_army_crocodile_easy,
        endgame_squads_strong = squads_army_crocodile_hard,
        conditions = { PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "F19", }), Q("ReduceBienChienCampStrength"), },
    },
    {
        -- The Eagle's Nest
        name = "The Eagle's Nest (A20)",
        source = "A20",
        group = "A20",
        targets = { "A16", "A17", "A18", "A19", "B16", "B17", "B18", "B19", "B20" },
        squads = squads_legion_major_easy,
        squads_strong = squads_legion_major_hard,
        conditions = {
            PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "A20", }),
            PlaceObj('QuestIsVariableBool', { QuestId = "05_TakeDownMajor", Vars = set_neg("Completed"), }),
        },
    },
    {
        -- Fort Brigand
        name = "Fort Brigand (K16)",
        source = "K16",
        group = "K16",
        targets = {
            "G13", "G14", "G15", "H13", "H15", "H16", "I12", "I16", "J12", "J16", "K12", "K13", "K14", "K15", -- Camp du Crocodile
            "E20", "F20", "G19", "I20", "J19", "J20", "K17", "K18", "K19", "L19", "L20", -- Camp Bien Chien
            "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" -- Camp Chien Sauvage
        },
        squads = squads_army_crocodile_easy,
        squads_strong = squads_army_crocodile_hard,
        conditions = {
            PlaceObj('SectorCheckOwner', { Negate = true, sector_id = "K16", }),
            PlaceObj('QuestIsTCEState', { Prop = "TCE_SwitchGuardpostAttackSquads", QuestId = "04_Betrayal", Value = "done", }),
            PlaceObj('QuestIsVariableBool', { QuestId = "05_TakeDownFaucheux", Vars = set_neg("Completed"), }),
        },
    },

    -- Wilderness Regions
    {
        -- Barrens
        name = "Barrens",
        group = "Barrens",
        targets = { "A16", "A17", "A18", "A19", "B16", "B17", "B18", "B19", "B20", "E20" },
        squads = squads_wild_barrens,
    },
    {
        -- Cursed Forest
        name = "Cursed Forest",
        group = "CursedForest",
        targets = { "C14", "C15", "C16", "D13", "D14", "D15", "D16", "D19", "D20", "E13", "E14", "E15" },
        squads = squads_legion_chiensauvage_easy,
        endgame_squads = squads_army_crocodile_easy,
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
        conditions = {
            PlaceObj('QuestIsTCEState', { Prop = "TCE_SwitchGuardpostAttackSquads", QuestId = "04_Betrayal", Value = "done", }),
            Q("04_Betrayal"), Q("ErnieSideQuests"),
        },
    },
    {
        -- Farmland
        name = "Farmland",
        group = "Farmland",
        targets = { "I20", "J18", "J19", "J20", "K17", "K18", "K19", "K20", "L17", "L19", "L20" },
        squads = squads_legion_bienchien_easy,
        endgame_squads = squads_army_crocodile_easy,
    },
    {
        -- Great Forest
        name = "Great Forest",
        group = "GreatForest",
        targets = { "D11", "D12", "E10", "E11", "E12", "F9", "F10", "F11", "F12", "G9", "G11", "G12", "G13", "H10", "H11", "I10", "I11", "I12", "J11" },
        squads = squads_legion_barriere_easy,
        endgame_squads = squads_adonis_easy,
        is_zombie_area = true,
    },
    {
        -- Highlands
        name = "Highlands",
        group = "Highlands",
        targets = { "A9", "A10", "A11", "B8", "B9", "B10", "C9", "C11", "C12", "C13", "D9" },
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
        targets = { "G14", "G15", "H13", "H14", "H15", "H16", "I13", "I16", "J16" },
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
    local major_taken_down = EvalConditionList({ PlaceObj('QuestIsVariableBool', { QuestId = "05_TakeDownMajor", Vars = set("Completed"), }) })

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
        local completed = EvalConditionList({ Q(quest_id) })
        print(string.format("[LCFYA]     - %s completed: %s", quest_id, tostring(completed)))
    end
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