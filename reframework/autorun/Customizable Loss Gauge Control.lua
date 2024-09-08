local health_loss_presets = {
    ["No Loss"] = 0,
    ["25% Loss"] = 0.25,
    ["50% Loss"] = 0.50,
    ["75% Loss"] = 0.75,
    ["Default Loss"] = 1.00,
    ["125% Loss"] = 1.25,
    ["150% Loss"] = 1.50,
    ["175% Loss"] = 1.75,
    ["Double Loss"] = 2.00
}

local original_default_rates = {
    0.15000000596046, 0.25, 0.25, 0.34799998998642, 0.34799998998642,
    0.34799998998642, 0.20000000298023, 0.25, 0.25, 0.070000000298023,
    0.050000000745058, 0.050000000745058, 0.0, 0.20000000298023, 0.34799998998642
}

local original_default_reduce_rate = 0.100

local health_loss_preset_order = { "No Loss", "25% Loss", "50% Loss", "75% Loss", "Default Loss", "125% Loss", "150% Loss", "175% Loss", "Double Loss" }
local selected_health_loss_preset = "Default Loss"
local selected_death_penalty_preset = "Default Loss"

local save_file_path = "Mr. Boobie\\HealthLossPresets.json"



local function set_Loss_Values(preset_percentage)
    local character_manager = sdk.get_managed_singleton("app.CharacterManager")
    local reduce_hp_param = character_manager:call("get_HumanActionParam"):get_ReduceMaxHpParamProp()
    local reduce_rate_list = reduce_hp_param:get_field("ReduceRateList")
    local reduce_rate_list_length = reduce_rate_list:get_Length()

    if reduce_rate_list_length then
        for i = 0, reduce_rate_list_length - 1 do
            if i ~= 13 then -- Skip the death penalty rate
                local reduce_rate_member = reduce_rate_list:get_Item(i)
                local original_rate = original_default_rates[i + 1]
                if original_rate then
                    local adjusted_rate = original_rate * preset_percentage
                    reduce_rate_member:set_field("Rate", adjusted_rate)
                else
                    log.error("No original rate for member " .. tostring(i))
                end
            end
        end
        local adjusted_default_reduce_rate = original_default_reduce_rate * preset_percentage
        reduce_hp_param:set_field("DefaultReduceRate", adjusted_default_reduce_rate)
    end
end


local function set_DeathLossRate(amount)
    local CharacterManager = sdk.get_managed_singleton("app.CharacterManager")
    local ReduceRateList = CharacterManager:call("get_HumanActionParam"):get_ReduceMaxHpParamProp():get_field("ReduceRateList")

    if ReduceRateList then
        local DeathLossRate = ReduceRateList:get_Item(13)
        DeathLossRate:set_field("Rate", amount)
    end
end

local function save_configuration()
    local data = {
        selected_health_loss_preset = selected_health_loss_preset,
        selected_death_penalty_preset = selected_death_penalty_preset
    }
    local success, err = pcall(json.dump_file, save_file_path, data)
    if not success then
        log.error("Error saving configuration: " .. tostring(err))
    end
end

local function load_configuration()
    local file = io.open(save_file_path, "r")
    if file then
        file:close()
        local status, data = pcall(json.load_file, save_file_path)
        if status and data then
            if data.selected_health_loss_preset then
                selected_health_loss_preset = data.selected_health_loss_preset
            end
            local preset_percentage = health_loss_presets[selected_health_loss_preset]
            set_Loss_Values(preset_percentage)

            if data.selected_death_penalty_preset then
                selected_death_penalty_preset = data.selected_death_penalty_preset
            end
            local death_penalty_percentage = health_loss_presets[selected_death_penalty_preset]
            set_DeathLossRate(death_penalty_percentage)
        else
            log.error("Error loading configuration: Data is corrupt or invalid.")
            save_configuration() 
        end
    else
        log.error("Error loading configuration: File does not exist.")
        save_configuration()
    end
end

load_configuration()

re.on_draw_ui(function()
    if imgui.tree_node("Loss Gauge Control") then
        local selected_health_loss_preset_index = 1
        for i, preset in ipairs(health_loss_preset_order) do
            if selected_health_loss_preset == preset then
                selected_health_loss_preset_index = i
                break
            end
        end

        local changed_health_loss = false
        changed_health_loss, selected_health_loss_preset_index = imgui.combo("Loss Gauge Preset",
            selected_health_loss_preset_index, health_loss_preset_order)
        if changed_health_loss then
            selected_health_loss_preset = health_loss_preset_order[selected_health_loss_preset_index]
            local preset_percentage = health_loss_presets[selected_health_loss_preset]
            set_Loss_Values(preset_percentage)
            save_configuration()
        end

        local selected_death_penalty_preset_index = 1
        for i, preset in ipairs(health_loss_preset_order) do
            if selected_death_penalty_preset == preset then
                selected_death_penalty_preset_index = i
                break
            end
        end

        local changed_death_penalty = false
        changed_death_penalty, selected_death_penalty_preset_index = imgui.combo("Death Loss Preset",
            selected_death_penalty_preset_index, health_loss_preset_order)
        if changed_death_penalty then
            selected_death_penalty_preset = health_loss_preset_order[selected_death_penalty_preset_index]
            local death_penalty_percentage = health_loss_presets[selected_death_penalty_preset]
            set_DeathLossRate(death_penalty_percentage)
            save_configuration()
        end

        imgui.tree_pop()
    end
end)
