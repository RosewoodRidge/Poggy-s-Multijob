Config = {}

Config.Debug = false

-- Command to open the menu
Config.Command = 'multijob'
Config.CommandDescription = 'Open Multijob Menu'

-- Command to quick switch job
Config.SwitchCommand = 'mj'
Config.SwitchCommandDescription = 'Quick switch job (e.g. /mj 1)'

-- Max jobs a player can have
Config.MaxJobs = 5

-- Default job when quitting all jobs
Config.DefaultJob = 'unemployed'
Config.DefaultGrade = 0
Config.DefaultJobLabel = 'Unemployed'

-- Webhook for logging
Config.Webhook = ''

-- Admin Groups that can access the admin menu
Config.AdminGroups = {
    'admin',
    'superadmin',
    'moderator'
}

-- Job Presets for Admin Panel
-- Categories: police, government, medical, business, shops
Config.JobPresets = {
    police = {
        name = "Police Departments",
        jobs = {
            -- Lemoyne Sheriff
            { job = "Lemoyne", label = "DEPUTY", grade = 0, category = "Lemoyne Sheriff" },
            { job = "Lemoyne", label = "SERGEANT", grade = 1, category = "Lemoyne Sheriff" },
            { job = "Lemoyne", label = "LIEUTENANT", grade = 2, category = "Lemoyne Sheriff" },
            { job = "Lemoyne", label = "UNDERSHERIFF", grade = 3, category = "Lemoyne Sheriff" },
            { job = "Lemoyne", label = "SHERIFF", grade = 4, category = "Lemoyne Sheriff" },
            -- West Elizabeth Sheriff
            { job = "WestElizabeth", label = "DEPUTY", grade = 0, category = "West Elizabeth Sheriff" },
            { job = "WestElizabeth", label = "SERGEANT", grade = 1, category = "West Elizabeth Sheriff" },
            { job = "WestElizabeth", label = "LIEUTENANT", grade = 2, category = "West Elizabeth Sheriff" },
            { job = "WestElizabeth", label = "UNDERSHERIFF", grade = 3, category = "West Elizabeth Sheriff" },
            { job = "WestElizabeth", label = "SHERIFF", grade = 4, category = "West Elizabeth Sheriff" },
            -- New Hanover Sheriff
            { job = "NewHanover", label = "DEPUTY", grade = 0, category = "New Hanover Sheriff" },
            { job = "NewHanover", label = "SERGEANT", grade = 1, category = "New Hanover Sheriff" },
            { job = "NewHanover", label = "LIEUTENANT", grade = 2, category = "New Hanover Sheriff" },
            { job = "NewHanover", label = "UNDERSHERIFF", grade = 3, category = "New Hanover Sheriff" },
            { job = "NewHanover", label = "SHERIFF", grade = 4, category = "New Hanover Sheriff" },
            -- New Austin Sheriff
            { job = "NewAustin", label = "DEPUTY", grade = 0, category = "New Austin Sheriff" },
            { job = "NewAustin", label = "SERGEANT", grade = 1, category = "New Austin Sheriff" },
            { job = "NewAustin", label = "LIEUTENANT", grade = 2, category = "New Austin Sheriff" },
            { job = "NewAustin", label = "UNDERSHERIFF", grade = 3, category = "New Austin Sheriff" },
            { job = "NewAustin", label = "SHERIFF", grade = 4, category = "New Austin Sheriff" },
            -- Cavalry
            { job = "CAVALRY", label = "TROOPER", grade = 0, category = "Cavalry" },
            { job = "CAVALRY", label = "CORPORAL", grade = 1, category = "Cavalry" },
            { job = "CAVALRY", label = "SERGEANT", grade = 2, category = "Cavalry" },
            { job = "CAVALRY", label = "LIEUTENANT", grade = 3, category = "Cavalry" },
            { job = "CAVALRY", label = "CAPTAIN", grade = 4, category = "Cavalry" },
        }
    },
    government = {
        name = "Government",
        jobs = {
            -- DOJ
            { job = "DOJ", label = "CLERK", grade = 0, category = "Department of Justice" },
            { job = "DOJ", label = "PA", grade = 1, category = "Department of Justice" },
            { job = "DOJ", label = "ADA", grade = 2, category = "Department of Justice" },
            { job = "DOJ", label = "DA", grade = 3, category = "Department of Justice" },
            { job = "DOJ", label = "JUDGE", grade = 4, category = "Department of Justice" },
            -- DOJM (Marshals)
            { job = "DOJM", label = "DEPMARSHAL", grade = 0, category = "US Marshals" },
            { job = "DOJM", label = "MARSHAL", grade = 1, category = "US Marshals" },
            { job = "DOJM", label = "CHIEFMARSHAL", grade = 2, category = "US Marshals" },
            { job = "DOJM", label = "AG", grade = 3, category = "US Marshals" },
            -- GOVT
            { job = "GOVT", label = "MAYOR", grade = 0, category = "Government Officials" },
            { job = "GOVT", label = "COS", grade = 1, category = "Government Officials" },
            { job = "GOVT", label = "GOVERNOR", grade = 2, category = "Government Officials" },
            { job = "GOVT", label = "PRESIDENT", grade = 3, category = "Government Officials" },
        }
    },
    medical = {
        name = "Medical",
        jobs = {
            -- Lemoyne Doc
            { job = "LemoyneDoc", label = "Doctor", grade = 0, category = "Lemoyne Medical" },
            { job = "LemoyneDoc", label = "SD", grade = 0, category = "Lemoyne Medical" },
            { job = "LemoyneDoc", label = "AHD", grade = 1, category = "Lemoyne Medical" },
            { job = "LemoyneDoc", label = "HD", grade = 2, category = "Lemoyne Medical" },
            -- New Hanover Doc
            { job = "NewHanoverDoc", label = "Doctor", grade = 0, category = "New Hanover Medical" },
            { job = "NewHanoverDoc", label = "SD", grade = 0, category = "New Hanover Medical" },
            { job = "NewHanoverDoc", label = "AHD", grade = 1, category = "New Hanover Medical" },
            { job = "NewHanoverDoc", label = "HD", grade = 2, category = "New Hanover Medical" },
            -- New Austin Doc
            { job = "NewAustinDoc", label = "Doctor", grade = 0, category = "New Austin Medical" },
            { job = "NewAustinDoc", label = "SD", grade = 0, category = "New Austin Medical" },
            { job = "NewAustinDoc", label = "AHD", grade = 1, category = "New Austin Medical" },
            { job = "NewAustinDoc", label = "HD", grade = 2, category = "New Austin Medical" },
            -- West Elizabeth Doc
            { job = "WestElizabethDoc", label = "Doctor", grade = 0, category = "West Elizabeth Medical" },
            { job = "WestElizabethDoc", label = "SD", grade = 0, category = "West Elizabeth Medical" },
            { job = "WestElizabethDoc", label = "AHD", grade = 1, category = "West Elizabeth Medical" },
            { job = "WestElizabethDoc", label = "HD", grade = 2, category = "West Elizabeth Medical" },
            -- Cavalry Doc
            { job = "CavalryDoc", label = "FM", grade = 0, category = "Cavalry Medical" },
            { job = "CavalryDoc", label = "SFM", grade = 0, category = "Cavalry Medical" },
            { job = "CavalryDoc", label = "AFS", grade = 1, category = "Cavalry Medical" },
            { job = "CavalryDoc", label = "FS", grade = 2, category = "Cavalry Medical" },
            -- General Doc (High Command)
            { job = "GeneralDoc", label = "AMD", grade = 0, category = "Medical High Command" },
            { job = "GeneralDoc", label = "MD", grade = 1, category = "Medical High Command" },
            { job = "GeneralDoc", label = "CMD", grade = 2, category = "Medical High Command" },
            { job = "GeneralDoc", label = "SG", grade = 3, category = "Medical High Command" },
        }
    },
    business = {
        name = "Business Licenses",
        jobs = {
            { job = "miner", label = "Miner", grade = 0, category = "Trade Licenses" },
            { job = "lumberjack", label = "Lumberjack", grade = 0, category = "Trade Licenses" },
            { job = "blacksmith", label = "Blacksmith", grade = 0, category = "Trade Licenses" },
            { job = "distiller", label = "Distiller", grade = 0, category = "Trade Licenses" },
            { job = "horsetrainer", label = "Horse Trainer", grade = 0, category = "Animal Trades" },
            { job = "horsebreeder", label = "Horse Breeder", grade = 0, category = "Animal Trades" },
            { job = "wheelwright", label = "Wheelwright", grade = 0, category = "Trade Licenses" },
        }
    },
    shops = {
        name = "Shop Owners",
        jobs = {
            -- Stables
            { job = "emerstableowner", label = "Emerald Stable", grade = 3, category = "Stables" },
            { job = "valstableowner", label = "Valentine Stable", grade = 3, category = "Stables" },
            { job = "blacksmithowner", label = "Blacksmith Stable", grade = 3, category = "Stables" },
            { job = "scarmeadstableowner", label = "Scarlett Meadows Stable", grade = 3, category = "Stables" },
            { job = "stdenstableowner", label = "Saint Denis Stable", grade = 3, category = "Stables" },
            { job = "armstableowner", label = "Armadillo Stable", grade = 3, category = "Stables" },
            { job = "rhostableowner", label = "Rhodes Stable", grade = 3, category = "Stables" },
            { job = "strawstableowner", label = "Strawberry Stable", grade = 3, category = "Stables" },
            { job = "tumstableowner", label = "Tumbleweed Stable", grade = 3, category = "Stables" },
            { job = "bwstableowner", label = "Blackwater Stable", grade = 3, category = "Stables" },
            -- Gunsmiths
            { job = "gunsmithBW", label = "Blackwater Gunsmith", grade = 3, category = "Gunsmiths" },
            { job = "gunsmithV", label = "Valentine Gunsmith", grade = 3, category = "Gunsmiths" },
            { job = "gunsmithS", label = "Saint Denis Gunsmith", grade = 3, category = "Gunsmiths" },
            { job = "gunsmithR", label = "Rhodes Gunsmith", grade = 3, category = "Gunsmiths" },
            { job = "gunsmithT", label = "Tumbleweed Gunsmith", grade = 3, category = "Gunsmiths" },
            { job = "gunsmithA", label = "Annesburg Gunsmith", grade = 3, category = "Gunsmiths" },
            -- General Stores
            { job = "generalstoreBW", label = "Blackwater General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreV", label = "Valentine General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreSD", label = "Saint Denis General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreR", label = "Rhodes General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreT", label = "Tumbleweed General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreAr", label = "Armadillo General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreAn", label = "Annesburg General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreE", label = "Emerald General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreS", label = "Strawberry General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreVH", label = "Van Horn General Store", grade = 3, category = "General Stores" },
            { job = "generalstoreW", label = "Wapiti General Store", grade = 3, category = "General Stores" },
            -- Saloons
            { job = "saloonBW", label = "Blackwater Saloon", grade = 3, category = "Saloons" },
            { job = "saloonV", label = "Valentine Saloon", grade = 3, category = "Saloons" },
            { job = "saloonSD", label = "Saint Denis Saloon", grade = 3, category = "Saloons" },
            { job = "saloonR", label = "Rhodes Saloon", grade = 3, category = "Saloons" },
            { job = "saloonT", label = "Tumbleweed Saloon", grade = 3, category = "Saloons" },
            { job = "saloonA", label = "Armadillo Saloon", grade = 3, category = "Saloons" },
            { job = "saloonE", label = "Emerald Saloon", grade = 3, category = "Saloons" },
            { job = "saloonAn", label = "Annesburg Saloon", grade = 3, category = "Saloons" },
            -- Blacksmiths
            { job = "blacksmithE", label = "Emerald Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithBW", label = "Blackwater Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithV", label = "Valentine Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithSD", label = "Saint Denis Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithR", label = "Rhodes Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithS", label = "Strawberry Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithA", label = "Armadillo Blacksmith", grade = 3, category = "Blacksmith Shops" },
            { job = "blacksmithAn", label = "Annesburg Blacksmith", grade = 3, category = "Blacksmith Shops" },
        }
    }
}
