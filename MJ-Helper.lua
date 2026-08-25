---@diagnostic disable: undefined-global, lowercase-global

script_author("elyrin")
script_name("MJ-Helper")
script_properties("work-in-pause")

local fa = require("fAwesome6")
local vkeys = require("vkeys")
local sampev = require("samp.events")
local json = require("dkjson")
local ffi = require("ffi")
local imgui = require("mimgui")
local hotkey = require("mimgui_hotkeys")
local encoding = require("encoding")
encoding.default = "CP1251"
local u8 = encoding.UTF8

local config = {
    ui = {
        window = {
            main = imgui.new.bool(false),
            wanted = imgui.new.bool(false),
            federal = imgui.new.bool(false),
            administrative = imgui.new.bool(false),
            notepad = imgui.new.bool(false),
            searched = imgui.new.bool(false),
            update = imgui.new.bool(false)
        },

        bools = {
            redactMode = imgui.new.bool(false),
            autoBodyCam = imgui.new.bool(false),
            autoTake = imgui.new.bool(false),
            autoPursuit = imgui.new.bool(false),
            offEffectPursuit = imgui.new.bool(false),
            customMegaphone = imgui.new.bool(false)
        },

        punishment = {
            section = imgui.new.char[16](),
            description = imgui.new.char[256](),
            level = imgui.new.char[2](),
            ticket = imgui.new.char[8]()
        },

        search = {
            description = imgui.new.char[256]()
        },

        notepad = {
            field = imgui.new.char[8192](),
            title = imgui.new.char[32]()
        },

        timer = {
            time = imgui.new.char[8](),
            name = imgui.new.char[128](),
            active = imgui.new.bool(false)
        },

        departament = {
            text_departament = imgui.new.char[256](),
            text_for_player = imgui.new.char[256]()
        },

        palitre = {
            megafon = imgui.new.float[3](1, 1, 0)
        }
    },
}

local ui = {
    main = 0.0,
    wanted = 0.0,
    federal = 0.0,
    admin = 0.0,
    notepad = 0.0,
    searched = 0.0,
    update = 0.0
}

local buttonAnims = {}
local listAnims = {}

local int_item_departament_from = imgui.new.int(0)
local item_list_departament_from = {u8("ЛСПД"), u8("СФПД"), u8("ЛВПД"), u8("ФБР"), u8("РКШД"), u8("СВАТ")}
local ImItemsDepartamentFrom = imgui.new["const char*"][#item_list_departament_from](item_list_departament_from)

local int_item_departament_to = imgui.new.int(0)
local item_list_departament_to = {u8("ОГП"), u8("ГКА"), u8("ЛСПД"), u8("СФПД"), u8("ЛВПД"), u8("РКШД"), u8("СВАТ"), u8("ФБР"), u8("ЛСа"), u8("СФа"), u8("ТСР"), u8("ЛСМЦ"), u8("СФМЦ"), u8("ЛВМЦ"), u8("ЦЛ"), u8("СМИ ЛС"), u8("СМИ СФ"), u8("СМИ ЛВ")}
local ImItemsDepartamentTo = imgui.new["const char*"][#item_list_departament_to](item_list_departament_to)

local int_item_departament_location = imgui.new.int(0)
local item_list_departament_location = {u8("ЛСПД"), u8("СФПД"), u8("ЛВПД"), u8("ФБР"), u8("РКШД"), u8("СВАТ")}
local ImItemsDepartamentLocation = imgui.new["const char*"][#item_list_departament_location](item_list_departament_location)

local activeTab = imgui.new.int(1)
local activeNoteTab = imgui.new.int(1)

local searchWanted = false
local logMessage = false
local bodyCamActive = false
local offerActive = false

local targetID = -1

local wanteds = {}
local federals = {}
local administratives = {}
local notepad = {}
local searched = {}
local timers = {}
local binds = {
    mainWindow = "[113]",
    siren = "[51]",
    offerAccept = "[49]",
    offerDecline = "[48]",
    searchedWindow = "[46]"
}
local text_for_departament = {
    {
        text_departament = "Адвоката в допросную {location}.",
        text_for_player = "Адвокат вызван. Время вызова: {time}. Время на приезд, после принятия вызова: 5 минут.",
    },
    {
        text_departament = "Прокурора в допросную {location}.",
        text_for_player = "Прокурор вызван. Время вызова: {time}. Время на приезд, после принятия вызова: 10 минут.",
    },
    {
        text_departament = "Начальство в допросную {location}.",
        text_for_player = "Начальство вызвано. Время вызова: {time}. Время на приезд, после принятия вызова: 10 минут.",
    }
}

local afind = false
local afindErrors = {
    "^%[Ошибка%] Команда доступна с 5 ранга",
    "^%[Ошибка%] Игрок находится в каком%-то здании",
    "^%[Ошибка%] Нельзя применить действие на администрации.",
    "^%[Ошибка%] Вы не на дежурстве"
}

local moveSearchedWindow = false
local settingsSearchedWindow = {
    x = 960,
    y = 540
}

local renderFont = renderCreateFont("Verdana", 10, 1 + 8)
local config_path = getWorkingDirectory() .. "\\config\\MJ-Helper.json"

local sendMJHelperMessage = function (text)
    if logMessage then
        return print(text)
    end

    sampAddChatMessage(string.format("[MJ-Helper]: {FFFFFF}%s", text), 0xff4f00)
end

local saveConfig = function ()
    local data = {
        wanteds = wanteds,
        federals = federals,
        administratives = administratives,
        notepad = notepad,
        logMessage = logMessage,
        settingsSearchedWindow = settingsSearchedWindow,
        timers = timers,
        megafon = {config.ui.palitre.megafon[0], config.ui.palitre.megafon[1], config.ui.palitre.megafon[2]},
        autoBodyCam = config.ui.bools.autoBodyCam[0],
        autoTake = config.ui.bools.autoTake[0],
        autoPursuit = config.ui.bools.autoPursuit[0],
        offEffectPursuit = config.ui.bools.offEffectPursuit[0],
        customMegaphone = config.ui.bools.customMegaphone[0],
        binds = binds,
        text_for_departament = text_for_departament
    }

    local file = io.open(config_path, "w")

    if file then
        file:write(json.encode(data, { indent = true }))
        file:close()
    end
end

local loadConfig = function ()
    local file = io.open(config_path, "r")

    if file then
        local content = file:read("*a")
        file:close()

        local ok, parsed = pcall(json.decode, content)

        if ok and parsed then
            wanteds = parsed.wanteds or {}
            federals = parsed.federals or {}
            administratives = parsed.administratives or {}
            notepad = parsed.notepad or {}
            logMessage = parsed.logMessage or false
            settingsSearchedWindow = parsed.settingsSearchedWindow or settingsSearchedWindow
            timers = parsed.timers or {}
            binds = parsed.binds or binds
            text_for_departament = parsed.text_for_departament or text_for_departament

            config.ui.palitre.megafon[0] = parsed.megafon[1] or 1.0
            config.ui.palitre.megafon[1] = parsed.megafon[2] or 1.0
            config.ui.palitre.megafon[2] = parsed.megafon[3] or 0.0

            config.ui.bools.autoBodyCam[0] = parsed.autoBodyCam or false
            config.ui.bools.autoTake[0] = parsed.autoTake or false
            config.ui.bools.autoPursuit[0] = parsed.autoPursuit or false
            config.ui.bools.offEffectPursuit[0] = parsed.offEffectPursuit or false
            config.ui.bools.customMegaphone[0] = parsed.customMegaphone or false
        end
    end
end

local lower = function (str)
    return str:gsub("А", "а"):gsub("Б", "б"):gsub("В", "в"):gsub("Г", "г"):gsub("Д", "д"):gsub("Е", "е"):gsub("Ё", "ё"):gsub("Ж", "ж"):gsub("З", "з"):gsub("И", "и"):gsub("Й", "й"):gsub("К", "к"):gsub("Л", "л"):gsub("М", "м"):gsub("Н", "н"):gsub("О", "о"):gsub("П", "п"):gsub("Р", "р"):gsub("С", "с"):gsub("Т", "т"):gsub("У", "у"):gsub("Ф", "ф"):gsub("Х", "х"):gsub("Ц", "ц"):gsub("Ч", "ч"):gsub("Ш", "ш"):gsub("Щ", "щ"):gsub("Ъ", "ъ"):gsub("Ы", "ы"):gsub("Ь", "ь"):gsub("Э", "э"):gsub("Ю", "ю"):gsub("Я", "я")
end

local toHEX = function (r, g, b)
    local clamp = function (v)
        return math.max(0, math.min(255, math.floor(v + 0.5)))
    end

    return string.format("%02X%02X%02X", clamp(r), clamp(g), clamp(b))
end

local keyNames = function (keys)
    if #keys == 1 then
        return vkeys.id_to_name(keys[1])
    elseif #keys > 1 then
        local keysNames = {}

        for _, id in ipairs(keys) do
            table.insert(keysNames, vkeys.id_to_name(id))
        end

        return table.concat(keysNames, " + ")
    else
        return "Нет"
    end
end

local DarkTheme = function ()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.WindowPadding                      = imgui.ImVec2(12, 12)
    style.FramePadding                       = imgui.ImVec2(8, 6)
    style.ItemSpacing                        = imgui.ImVec2(8, 8)
    style.WindowRounding                     = 8.0
    style.ChildRounding                      = 4.0
    style.FrameRounding                      = 4.0
    style.PopupRounding                      = 6.0
    style.ScrollbarRounding                  = 6.0
    style.GrabRounding                       = 4.0
    style.TabRounding                        = 4.0
    style.WindowBorderSize                   = 1.0
    style.ChildBorderSize                    = 2.0
    style.PopupBorderSize                    = 1.0
    style.FrameBorderSize                    = 0.0

    colors[imgui.Col.Text]                   = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
    colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.03, 0.03, 0.03, 1.00)
    colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.04, 0.04, 0.04, 0.98)
    colors[imgui.Col.Border]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.03, 0.03, 0.03, 1.00)
    colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.02, 0.02, 0.02, 1.00)
    colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
    colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    colors[imgui.Col.Button]                 = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[imgui.Col.Header]                 = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[imgui.Col.Separator]              = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.15, 0.15, 0.15, 0.50)
    colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.25, 0.25, 0.25, 0.80)
    colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    colors[imgui.Col.Tab]                    = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[imgui.Col.TabActive]              = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.02, 0.02, 0.02, 1.00)
    colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.30, 0.30, 0.30, 0.50)
    colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

imgui.OnInitialize(function ()
    DarkTheme()

    local atlas = imgui.GetIO().Fonts
    local font_path = getWorkingDirectory() .. "\\resource\\fonts\\Eagle-Sans-Bold.ttf"
    local cyr_ranges = atlas:GetGlyphRangesCyrillic()

    iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)

    local config16 = imgui.ImFontConfig()
    config16.MergeMode = true
    config16.PixelSnapH = true

    font = atlas:AddFontFromFileTTF(font_path, 16.0, nil, cyr_ranges)
    atlas:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85("solid"), 12.0, config16, iconRanges)

    local config20 = imgui.ImFontConfig()
    config20.MergeMode = true
    config20.PixelSnapH = true

    bigFont = atlas:AddFontFromFileTTF(font_path, 20.0, nil, cyr_ranges)
    atlas:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85("solid"), 15.0, config20, iconRanges)

    local iconConfig = imgui.ImFontConfig()
    iconConfig.PixelSnapH = true
    bigIcon = atlas:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85("solid"), 20.0, iconConfig, iconRanges)

    imgui.GetIO().IniFilename = nil
end)

imgui.CenterText = function (text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)

    imgui.SetCursorPosX(width / 2 - calc.x / 2)
    imgui.Text(text)
end

imgui.CenterColumnText = function (text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)

    imgui.Text(text)
end

local AnimButton = function (label, size)
    if not buttonAnims[label] then
        buttonAnims[label] = 0.0
    end

    local target = 0.0

    local cIdle = imgui.GetStyle().Colors[imgui.Col.Button]
    local cHover = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]

    local t = buttonAnims[label]
    local r = cIdle.x + (cHover.x - cIdle.x) * t
    local g = cIdle.y + (cHover.y - cIdle.y) * t
    local b = cIdle.z + (cHover.z - cIdle.z) * t
    local a = cIdle.w + (cHover.w - cIdle.w) * t

    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, a))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, a))

    local clicked = imgui.Button(label, size or imgui.ImVec2(0, 0))

    imgui.PopStyleColor(2)

    if imgui.IsItemActive() then
        buttonAnims[label] = 1.0
    elseif imgui.IsItemHovered() then
        target = 1.0
    end

    local dt = imgui.GetIO().DeltaTime
    buttonAnims[label] = buttonAnims[label] + (target - buttonAnims[label]) * math.min(dt * 15.0, 1.0)

    return clicked
end

local RenderAnimated = function (id, isActive, windowAlpha, renderFunc)
    if not listAnims[id] then
        listAnims[id] = isActive and 1.0 or 0.0
    end

    local target = isActive and 1.0 or 0.0
    local dt = imgui.GetIO().DeltaTime

    listAnims[id] = listAnims[id] + (target - listAnims[id]) * math.min(dt * 12.0, 1.0)

    if listAnims[id] > 0.01 then
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, listAnims[id] * windowAlpha)

        local origX = imgui.GetCursorPosX()
        imgui.SetCursorPosX(origX + (1.0 - listAnims[id]) * 15.0)

        renderFunc()

        imgui.PopStyleVar()
    end
end

local drawList = function (widthOne, widthTwo, widthThree, indexOne, indexTwo, ...)
    local min, max = imgui.GetItemRectMin(), imgui.GetItemRectMax()
    local dl = imgui.GetWindowDrawList()

    local x = { 0, widthOne * widthTwo, widthOne * widthThree }
    local t = {...}

    for i = indexOne, indexTwo do
        dl:AddLine(imgui.ImVec2(min.x + x[i], min.y), imgui.ImVec2(min.x + x[i], max.y), 0x20FFFFFF, 1.0)
    end

    for i = 1, #t do
        dl:AddText(imgui.ImVec2(min.x + x[i] + 8, min.y + 10), 0xFFFFFFFF, t[i])
    end
end

local NavButton = function (label, index, activeVar)
    local isSelected = activeVar[0] == index

    if isSelected then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.15, 0.15, 1.0))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
    else
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.02, 0.02, 0.02, 0.0))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
    end

    if AnimButton(label .. "##nav_"..index, imgui.ImVec2(-1, 40)) then
        activeVar[0] = index
    end

    imgui.PopStyleColor(2)
end

local HandleWindowAlpha = function (bool_val, key)
    local speed = 8.0 * imgui.GetIO().DeltaTime

    if bool_val then
        ui[key] = math.min(1.0, ui[key] + speed)
    else
        ui[key] = math.max(0.0, ui[key] - speed)
    end

    return ui[key]
end

imgui.CheckboxHint = function (text, checkbox, hint, func)
    if imgui.Checkbox(text, checkbox) then
        func()
    end

    imgui.SameLine()

    imgui.TextDisabled("(?)")

    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(hint)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end

    imgui.Separator()
end

imgui.CheckboxRedact = function ()
    imgui.CheckboxHint(u8("Режим редактирования"), config.ui.bools.redactMode, u8("Включите этот режим, чтобы редактировать законодательство"), function ()
        loadConfig()
        saveConfig()
    end)
end

local showNotification = (function ()
    local notif = {
        show = false, text = "", timer = 0, duration = 3.0, alpha = 0.0, type = "success",
        types = {
            ["success"] = { icon = fa["CHECK"], color = 0xFF71C743 },
            ["info"]    = { icon = fa["INFO"],  color = 0xFFE69138 },
            ["error"]   = { icon = fa["XMARK"], color = 0xFF3838E6 }
        }
    }

    imgui.OnFrame(function() return notif.show or notif.alpha > 0.001 end, function(self)
        self.HideCursor = true

        local dt = imgui.GetIO().DeltaTime
        local target = (notif.show and os.clock() < notif.timer) and 1.0 or 0.0

        notif.alpha = notif.alpha + (target - notif.alpha) * math.min(dt * 5.0, 1.0)

        if notif.alpha < 0.005 and not notif.show then
            notif.alpha = 0.0
        end

        imgui.PushFont(bigFont)
        local minW, fixedH = 320.0, 55.0

        local singleLineSize = imgui.CalcTextSize(notif.text, nil, false, 0.0)
        local realTextW = singleLineSize.x
        local realTextH = singleLineSize.y

        local w = math.max(minW, realTextW + 75.0)
        local h = fixedH

        local ds = imgui.GetIO().DisplaySize
        local posX = (ds.x - w) / 2
        local posY = ds.y - ((h + 55.0) * notif.alpha) + (25.0 * (1.0 - notif.alpha))
        local cur = notif.types[notif.type]

        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(w, h), imgui.Cond.Always)

        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, notif.alpha)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.95))

        if imgui.Begin("##NotificationWindow", _, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoSavedSettings) then
            local dl = imgui.GetWindowDrawList()
            local p, s = imgui.GetWindowPos(), imgui.GetWindowSize()
            local centerY = p.y + (s.y / 2)
            local iconSize = imgui.CalcTextSize(cur.icon)

            dl:AddCircleFilled(imgui.ImVec2(p.x + 25, centerY), 12.0, cur.color)
            dl:AddText(imgui.ImVec2(p.x + (notif.type == "info" and 26 or 25) - iconSize.x / 2, centerY - iconSize.y / 2), 0xFFFFFFFF, cur.icon)
            dl:PushClipRect(imgui.ImVec2(p.x + s.x - 4.0, p.y), imgui.ImVec2(p.x + s.x, p.y + s.y), true)
            dl:AddRectFilled(p, imgui.ImVec2(p.x + s.x, p.y + s.y), cur.color, 8.0)
            dl:PopClipRect()

            local textY = ((s.y - realTextH) / 2)

            imgui.SetCursorPos(imgui.ImVec2(50, textY))
            imgui.TextUnformatted(notif.text)

            imgui.End()
        end
        imgui.PopFont()

        imgui.PopStyleColor(1)
        imgui.PopStyleVar(3)
    end)

    return function (nType, text)
        notif.text = u8(text)
        notif.type = nType
        notif.duration = 3.0
        notif.timer = os.clock() + notif.duration
        notif.show = true
    end
end)()

local OfferMenu = (function ()
    local offer = {
        show = false,
        alpha = 0,
        title = "",
        subtitle = "",
        onAccept = nil,
        onDecline = nil,
        onTime = nil,
        timer = 0,
        bindAccept = {},
        bindDecline = {}
    }

    imgui.OnFrame(function() return offer.show or offer.alpha > 0.001 end, function(self)
        self.HideCursor = true

        if offer.show and os.clock() > offer.timer then
            if offer.onTime then offer.onTime() end
            offerActive = false
            offer.show = false
        end

        local targetAlpha = offer.show and 1.0 or 0.0
        offer.alpha = offer.alpha + (targetAlpha - offer.alpha) * math.min(imgui.GetIO().DeltaTime * 12.0, 1.0)

        imgui.PushFont(font)

        local titleW = imgui.CalcTextSize(u8(offer.title)).x
        local subW = imgui.CalcTextSize(u8(offer.subtitle)).x
        local contentW = math.max(titleW, subW)

        local width = math.max(360.0, 64.0 + contentW + 20.0)
        local btnWidth = (width - 36.0) / 2
        local height = 110.0

        local posX = (imgui.GetIO().DisplaySize.x - width) / 2
        local posY = imgui.GetIO().DisplaySize.y * 0.825 - 45.0 * offer.alpha

        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(width, height), imgui.Cond.Always)

        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, offer.alpha)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 10.0)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.9))

        if imgui.Begin(u8("Предложение"), _, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoSavedSettings) then
            local dl, p = imgui.GetWindowDrawList(), imgui.GetWindowPos()

            imgui.PushFont(bigIcon)
            local iconUser = fa.USER
            local iconSize = imgui.CalcTextSize(iconUser)

            dl:AddRectFilled(imgui.ImVec2(p.x + 12, p.y + 12), imgui.ImVec2(p.x + 52, p.y + 52), 0xFFFFFFFF, 8.0)
            dl:AddText(imgui.ImVec2(p.x + 32 - iconSize.x / 2, p.y + 32 - iconSize.y / 2), 0xFF000000, iconUser)
            imgui.PopFont()

            local progress = offer.show and math.max(0.0, math.min(1.0, (offer.timer - os.clock()) / 10.0)) or 0.0

            dl:AddRectFilled(
                imgui.ImVec2(p.x + 12, p.y + 62),
                imgui.ImVec2(p.x + 12 + (width - 24) * progress, p.y + 64),
                0xFF421CE1
            )

            imgui.SetCursorPos(imgui.ImVec2(64, 15))
            imgui.TextColored(imgui.ImVec4(1, 1, 1, 0.95), u8(offer.title))
            imgui.SetCursorPos(imgui.ImVec2(64, 31))
            imgui.TextColored(imgui.ImVec4(0.65, 0.65, 0.65, 1.0), u8(offer.subtitle))

            local drawButton = function (x, key, text)
                local btnHeight = 26.0
                local keySize, textSize = imgui.CalcTextSize(key), imgui.CalcTextSize(text)
                local keyBoxWidth = math.max(28.0, keySize.x + 16.0)

                dl:AddRectFilled(imgui.ImVec2(x, p.y + 72), imgui.ImVec2(x + btnWidth, p.y + 72 + btnHeight), 0x20FFFFFF, 6.0)
                dl:AddRectFilled(imgui.ImVec2(x, p.y + 72), imgui.ImVec2(x + keyBoxWidth, p.y + 72 + btnHeight), 0x40FFFFFF, 6.0)

                dl:AddText(imgui.ImVec2(x + (keyBoxWidth - keySize.x) / 2, p.y + 72 + (btnHeight - keySize.y) / 2), 0xFFFFFFFF, key)
                dl:AddText(imgui.ImVec2(x + keyBoxWidth + 10, p.y + 72 + (btnHeight - textSize.y) / 2), 0xDDFFFFFF, text)
            end

            drawButton(p.x + 12, keyNames(offer.bindAccept), u8("Принять"))
            drawButton(p.x + 24 + btnWidth, keyNames(offer.bindDecline), u8("Отказаться"))

            imgui.End()
        end

        imgui.PopStyleColor(1)
        imgui.PopStyleVar(2)
        imgui.PopFont()
    end)

    return {
        show = function (title, subtitle, bindA, bindD, onA, onD, onT)
            offer.title, offer.subtitle = title, subtitle
            offer.bindAccept, offer.bindDecline = bindA, bindD
            offer.onAccept, offer.onDecline, offer.onTime = onA, onD, onT
            offer.timer = os.clock() + 10
            offer.show = true
        end,

        triggerAccept = function ()
            if offer.show and offer.alpha > 0.5 then
                if offer.onAccept then offer.onAccept() end
                offerActive = false
                offer.show = false
            end
        end,

        triggerDecline = function ()
            if offer.show and offer.alpha > 0.5 then
                if offer.onDecline then offer.onDecline() end
                offerActive = false
                offer.show = false
            end
        end
    }
end)()

local showHotkey = function (key, text)
    if hotkey.ShowHotKey(key) then
        binds[key] = encodeJson(hotkey.GetHotKey(key))

        saveConfig()
    end

    imgui.SameLine()

    imgui.SetCursorPosX(imgui.GetCursorPosX() - 2.5)
    imgui.Text(u8("- " .. text))

    imgui.Separator()
end

imgui.OnFrame(
    function() return config.ui.window.main[0] or ui.main > 0.0 end,
    function()
        local alpha = HandleWindowAlpha(config.ui.window.main[0], "main")
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 650, 450

        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)

        imgui.PushFont(font)
        if imgui.Begin(u8("MJ-Helper"), config.ui.window.main, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar) then
            imgui.BeginChild("SideMenu", imgui.ImVec2(160, 0), true, imgui.WindowFlags.NoScrollbar)

            NavButton(u8"Департамент", 1, activeTab)
            imgui.Separator()
            NavButton(u8"Мегафон", 2, activeTab)
            imgui.Separator()
            NavButton(u8"Таймеры", 3, activeTab)
            imgui.Separator()
            NavButton(u8"Настройки", 4, activeTab)
            imgui.Separator()

            imgui.EndChild()

            imgui.SameLine()

            imgui.BeginChild("MainContent", imgui.ImVec2(0, 0), true, imgui.WindowFlags.NoScrollbar)

            if activeTab[0] == 1 then
                local categories = {
                    departament = {
                        {
                            name = "Адвокат",
                            text_departament = text_for_departament[1].text_departament,
                            text_for_player = text_for_departament[1].text_for_player,
                            departament_selection = 1,
                            timer = {
                                name = "Адвокат",
                                time = 180,
                                active = true
                            },
                        },
                        {
                            name = "Прокурор",
                            text_departament = text_for_departament[2].text_departament,
                            text_for_player = text_for_departament[2].text_for_player,
                            departament_selection = 0,
                            timer = {
                                name = "Прокурор",
                                time = 300,
                                active = true
                            }
                        },
                        {
                            name = "Начальство",
                            text_departament = text_for_departament[3].text_departament,
                            text_for_player = text_for_departament[3].text_for_player,
                            departament_selection = 2,
                            timer = {
                                name = "Начальство",
                                time = 300,
                                active = true
                            }
                        }
                    },

                    functions = {
                        time = function ()
                            return os.date("%H:%M", os.time())
                        end,

                        location = function ()
                            return u8:decode(item_list_departament_location[int_item_departament_location[0] + 1])
                        end
                    }
                }

                for index, category in pairs(categories.departament) do
                    local message_departament = string.format("/d [%s] - [%s]: %s", u8:decode(item_list_departament_from[int_item_departament_from[0] + 1]), u8:decode(item_list_departament_to[int_item_departament_to[0] + 1]), category["text_departament"])

                    if AnimButton(u8(category.name), imgui.ImVec2(imgui.GetContentRegionAvail().x, 35)) then
                        int_item_departament_to[0] = category["departament_selection"]

                        imgui.OpenPopup(u8(category.name))
                    end

                    if imgui.BeginPopupModal(u8(category.name), _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar) then
                        imgui.SetWindowSizeVec2(imgui.ImVec2(500, 340))

                        imgui.PushItemWidth(475)
                        imgui.Text(u8("Нахождение:"))
                        imgui.Combo("##selectFounding", int_item_departament_location, ImItemsDepartamentLocation, #item_list_departament_location)

                        imgui.Text(u8("От:"))
                        imgui.Combo("##selectDepartamentFrom", int_item_departament_from, ImItemsDepartamentFrom, #item_list_departament_from)

                        imgui.Text(u8("Кому:"))
                        imgui.Combo("##selectDepartamentTo", int_item_departament_to, ImItemsDepartamentTo, #item_list_departament_to)
                        imgui.PopItemWidth()

                        imgui.Separator()

                        imgui.CenterText(u8(message_departament):gsub("{location}", u8(categories.functions.location())))

                        imgui.Separator()

                        if AnimButton(u8("Отправить"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                            sampSendChat(message_departament:gsub("{location}", categories.functions.location()))
                            sampSendChat(category["text_for_player"]:gsub("{time}", categories.functions.time()))

                            table.insert(timers, category["timer"])

                            saveConfig()

                            showNotification("success", "Сообщение в департамент отправлено!")
                            sendMJHelperMessage("Сообщение в департамент отправлено!")

                            imgui.CloseCurrentPopup()
                        end

                        if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                            imgui.CloseCurrentPopup()
                        end

                        imgui.End()
                    end
                end

                imgui.Separator()

                if AnimButton(u8("Редактирование"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 35)) then
                    imgui.OpenPopup(u8("Редактирование"))
                end

                if imgui.BeginPopupModal(u8("Редактирование"), _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(500, 220))

                    for index, category in pairs(categories.departament) do
                        if AnimButton(u8(category.name) .. "##" .. index, imgui.ImVec2(imgui.GetContentRegionAvail().x, 35)) then
                            ffi.copy(config.ui.departament.text_departament, u8(category.text_departament))
                            ffi.copy(config.ui.departament.text_for_player, u8(category.text_for_player))

                            imgui.OpenPopup(u8(string.format("Редактирование [%s]", category.name)))
                        end

                        if imgui.BeginPopupModal(u8(string.format("Редактирование [%s]", category.name)), _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar) then
                            imgui.SetWindowSizeVec2(imgui.ImVec2(750, 210))

                            imgui.PushItemWidth(imgui.GetContentRegionAvail().x)
                            imgui.Text(u8("Сообщение в департамент:"))
                            if imgui.InputText("##textDepartament", config.ui.departament.text_departament, 256) then
                                text_for_departament[index].text_departament = u8:decode(ffi.string(config.ui.departament.text_departament))
                                saveConfig()
                            end

                            imgui.Text(u8("Сообщение для игрока:"))
                            if imgui.InputText("##textForPlayer", config.ui.departament.text_for_player, 256) then
                                text_for_departament[index].text_for_player = u8:decode(ffi.string(config.ui.departament.text_for_player))
                                saveConfig()
                            end
                            imgui.PopItemWidth()

                            imgui.Separator()

                            if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                                imgui.CloseCurrentPopup()
                            end

                            imgui.End()
                        end
                    end

                    imgui.Separator()

                    if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                        imgui.CloseCurrentPopup()
                    end

                    imgui.End()
                end
            elseif activeTab[0] == 2 then
                imgui.PushItemWidth(imgui.GetContentRegionAvail().x - 60)

                if imgui.ColorEdit3(u8("Мегафон"), config.ui.palitre.megafon) then
                    saveConfig()
                end

                imgui.PopItemWidth()
            elseif activeTab[0] == 3 then
                if #timers ~= 0 then
                    for index, timer in pairs(timers) do
                        local width = imgui.GetContentRegionAvail().x

                        if AnimButton("##" .. index, imgui.ImVec2(width, 35)) then
                            timer.active = not timer.active

                            saveConfig()

                            showNotification("info", string.format("Таймер \"%s\" %s!", timer.name, timer.active and "включен" or "отключён"))
                            sendMJHelperMessage(string.format("Таймер \"%s\" %s!", timer.name, timer.active and "включен" or "отключён"))
                        end

                        drawList(width, 0.835, 0, 2, 2, u8(timer.name), os.date("!%H:%M:%S", timer.time))

                        if imgui.IsItemClicked(1) then
                            ffi.copy(config.ui.timer.name, u8(timer.name))
                            ffi.copy(config.ui.timer.time, tostring(timer.time))
                            config.ui.timer.active[0] = timer.active

                            imgui.OpenPopup(u8("Редактирование ##" .. index))
                        end

                        if imgui.BeginPopupModal(u8("Редактирование ##" .. index), _, imgui.WindowFlags.NoResize) then
                            imgui.SetWindowSizeVec2(imgui.ImVec2(500, 295))

                            imgui.PushItemWidth(475)
                            imgui.Text(u8("Время (секунды):"))
                            imgui.InputText(u8("##time"), config.ui.timer.time, 8)

                            imgui.Separator()

                            imgui.Text(u8("Название:"))
                            imgui.InputText(u8("##name"), config.ui.timer.name, 128)
                            imgui.PopItemWidth()

                            imgui.Separator()

                            if AnimButton(u8("Сохранить"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                                timer.name = u8:decode(ffi.string(config.ui.timer.name))
                                timer.time = tonumber(u8:decode(ffi.string(config.ui.timer.time)))
                                timer.active = config.ui.timer.active[0]

                                saveConfig()

                                imgui.CloseCurrentPopup()
                            end

                            if AnimButton(u8("Удалить"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                                table.remove(timers, index)

                                saveConfig()

                                imgui.CloseCurrentPopup()
                            end

                            if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                                imgui.CloseCurrentPopup()
                            end

                            imgui.End()
                        end

                        imgui.Separator()
                    end
                else
                    imgui.Text(u8("Таймеров нет!"))

                    imgui.Separator()
                end

                if AnimButton(u8("Добавить таймер"), imgui.ImVec2(imgui.GetContentRegionAvail().x, 30)) then
                    table.insert(timers, {
                        name = "Новый таймер",
                        time = 60,
                        active = false
                    })

                    saveConfig()
                end
            elseif activeTab[0] == 4 then
                if imgui.BeginTabBar("SettingsTabs") then
                    if imgui.BeginTabItem(u8("Основные")) then
                        imgui.CheckboxHint(u8("Авто боди-камера"), config.ui.bools.autoBodyCam, u8("При спавне боди-камера будет включаться автоматически"), function ()
                            saveConfig()
                        end)

                        imgui.CheckboxHint(u8("Авто /take при изъятии"), config.ui.bools.autoTake, u8("При изъятии чего-либо незаконного у игрока - /take будет отправлен автоматически"), function ()
                            saveConfig()
                        end)

                        imgui.CheckboxHint(u8("Авто /pursuit"), config.ui.bools.autoPursuit, u8("После окончания /pursuit он автоматически будет прописываться заново"), function ()
                            saveConfig()
                        end)

                        imgui.CheckboxHint(u8("Отключение эффектов от /pursuit"), config.ui.bools.offEffectPursuit, u8("При включении/выключении /pursuit эффекты от него выключатся"), function ()
                            saveConfig()
                        end)

                        imgui.CheckboxHint(u8("Старый стиль мегафона"), config.ui.bools.customMegaphone, u8("При включении старый стиль мегафона (желтого цвета) восстановится\nПри этом, можно будет сменить цвет мегафона"), function ()
                            saveConfig()
                        end)

                        imgui.EndTabItem()
                    end

                    if imgui.BeginTabItem(u8("Бинды")) then
                        showHotkey("mainWindow", "Главное меню")
                        showHotkey("siren", "Сирена")
                        showHotkey("offerAccept", "Принять /offer")
                        showHotkey("offerDecline", "Отказаться от /offer")
                        showHotkey("searchedWindow", "Перемещение окна /awanted")

                        imgui.EndTabItem()
                    end

                    imgui.EndTabBar()
                end
            end

            imgui.EndChild()
            imgui.End()
        end
        imgui.PopFont()
        imgui.PopStyleVar()
    end
)

imgui.OnFrame(
    function() return config.ui.window.wanted[0] or ui.wanted > 0.0 end,
    function()
        local alpha = HandleWindowAlpha(config.ui.window.wanted[0], "wanted")
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 750, 750

        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)

        imgui.PushFont(font)
        if imgui.Begin(u8("Умный розыск"), config.ui.window.wanted, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar) then
            imgui.CheckboxRedact()

            if #wanteds ~= 0 then
                local searchText = u8:decode(ffi.string(config.ui.search.description))

                imgui.PushItemWidth(725)
                imgui.InputTextWithHint("##search", u8("Поиск статьи..."), config.ui.search.description, 256)
                imgui.PopItemWidth()

                imgui.Separator()

                imgui.BeginChild("WantedList", imgui.ImVec2(0, 0), true, imgui.WindowFlags.NoScrollbar)

                for indexWanted, wanted in pairs(wanteds) do
                    local is_match = #searchText == 0 or string.find(lower(wanted.description), lower(searchText))

                    RenderAnimated("wanted_group_" .. indexWanted, is_match, alpha, function ()
                        local is_open = imgui.CollapsingHeader(u8(string.format("Статья %s. %s ##" .. indexWanted, wanted.section, wanted.description)))

                        RenderAnimated("wanted_child_" .. indexWanted, is_open, alpha, function ()
                            for indexChildren, children in pairs(wanted.children) do
                                local descriptionMenu = children.description

                                if #descriptionMenu > 80 then
                                    descriptionMenu = descriptionMenu:sub(1, 80) .. "..."
                                end

                                local width = imgui.GetContentRegionAvail().x

                                if AnimButton("##" .. indexChildren, imgui.ImVec2(width, 35)) then
                                    config.ui.window.wanted[0] = false

                                    sampSendChat(string.format("/su %s %s %s", targetID, children.level, children.section))
                                end

                                drawList(width, 0.0925, 0.9425, 2, 3, u8(children.section), u8(descriptionMenu), children.level .. " " .. fa.STAR)

                                if imgui.IsItemClicked(1) then
                                    ffi.copy(config.ui.punishment.section, u8(children.section))
                                    ffi.copy(config.ui.punishment.description, u8(children.description))
                                    ffi.copy(config.ui.punishment.level, u8(children.level))

                                    imgui.OpenPopup(u8("Редактирование ##" .. u8(children.section)))
                                end

                                if imgui.BeginPopupModal(u8("Редактирование ##" .. u8(children.section)), _, imgui.WindowFlags.NoResize) then
                                    imgui.SetWindowSizeVec2(imgui.ImVec2(750, config.ui.bools.redactMode[0] and 490 or 405))

                                    imgui.PushItemWidth(725)
                                    imgui.Text(u8("Статья:"))
                                    imgui.InputText("##section_children", config.ui.punishment.section, 16)

                                    imgui.Separator()

                                    imgui.Text(u8("Описание:"))
                                    imgui.InputTextMultiline("##description_children", config.ui.punishment.description, 256)

                                    imgui.Separator()

                                    imgui.Text(u8("Уровень розыска:"))
                                    imgui.InputText("##level_children", config.ui.punishment.level, 2)
                                    imgui.PopItemWidth()

                                    imgui.Separator()

                                    if config.ui.bools.redactMode[0] then
                                        if AnimButton(u8("Сохранить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                            children.section = u8:decode(ffi.string(config.ui.punishment.section))
                                            children.description = u8:decode(ffi.string(config.ui.punishment.description))
                                            children.level = u8:decode(ffi.string(config.ui.punishment.level))

                                            saveConfig()

                                            imgui.CloseCurrentPopup()
                                        end

                                        if AnimButton(u8("Удалить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                            table.remove(wanted.children, indexChildren)

                                            if #wanted.children == 0 then
                                                table.remove(wanteds, indexWanted)
                                            end

                                            saveConfig()

                                            imgui.CloseCurrentPopup()
                                        end
                                    end

                                    if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                        imgui.CloseCurrentPopup()
                                    end

                                    imgui.End()
                                end
                            end

                            if config.ui.bools.redactMode[0] then
                                imgui.Separator()

                                if AnimButton(u8("Добавить подпункт"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 30)) then
                                    table.insert(wanted.children, {
                                        section = "1.2",
                                        description = "Описание",
                                        level = 1
                                    })

                                    saveConfig()
                                end

                                if AnimButton(u8("Изменить группу"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 30)) then
                                    ffi.copy(config.ui.punishment.section, u8(wanted.section))
                                    ffi.copy(config.ui.punishment.description, u8(wanted.description))

                                    imgui.OpenPopup(u8("Редактирование ##" .. indexWanted))
                                end

                                if imgui.BeginPopupModal(u8("Редактирование ##" .. indexWanted), _, imgui.WindowFlags.NoResize) then
                                    imgui.SetWindowSizeVec2(imgui.ImVec2(500, 425))

                                    imgui.PushItemWidth(475)
                                    imgui.Text(u8("Статья:"))
                                    imgui.InputText("##section", config.ui.punishment.section, 16)

                                    imgui.Separator()

                                    imgui.Text(u8("Описание:"))
                                    imgui.InputTextMultiline("##description", config.ui.punishment.description, 256)
                                    imgui.PopItemWidth()

                                    imgui.Separator()

                                    if AnimButton(u8("Сохранить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                        wanted.section = u8:decode(ffi.string(config.ui.punishment.section))
                                        wanted.description = u8:decode(ffi.string(config.ui.punishment.description))

                                        saveConfig()

                                        imgui.CloseCurrentPopup()
                                    end

                                    if AnimButton(u8("Удалить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                        table.remove(wanteds, indexWanted)

                                        saveConfig()

                                        imgui.CloseCurrentPopup()
                                    end

                                    if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                        imgui.CloseCurrentPopup()
                                    end

                                    imgui.End()
                                end

                                if AnimButton(u8("Удалить группу"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 30)) then
                                    table.remove(wanteds, indexWanted)

                                    saveConfig()
                                end
                            end
                        end)
                    end)
                end

                if config.ui.bools.redactMode[0] then
                    if AnimButton(u8("Добавить статью"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                        table.insert(wanteds, {
                            section = "1.1 УК",
                            description = "Описание",
                            children = {
                                {
                                    section = "1.2 УК",
                                    description = "Описание",
                                    level = 1
                                }
                            }
                        })
                        saveConfig()
                    end
                end

                imgui.EndChild()
            else
                imgui.Text(u8("УК не настроено!"))

                if config.ui.bools.redactMode[0] then
                    if AnimButton(u8("Добавить статью"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                        table.insert(wanteds, {
                            section = "1.1 УК",
                            description = "Описание",
                            children = {
                                {
                                    section = "1.2 УК",
                                    description = "Описание",
                                    level = 1
                                }
                            }
                        })
                        saveConfig()
                    end
                end
            end

            imgui.End()
        end
        imgui.PopFont()
        imgui.PopStyleVar()
    end
)

imgui.OnFrame(
    function() return config.ui.window.federal[0] or ui.federal > 0.0 end,
    function()
        local alpha = HandleWindowAlpha(config.ui.window.federal[0], "federal")
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 750, 750

        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)

        imgui.PushFont(font)
        if imgui.Begin(u8("Умное ФП"), config.ui.window.federal, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar) then
            imgui.CheckboxRedact()

            if #federals ~= 0 then
                local searchText = u8:decode(ffi.string(config.ui.search.description))

                imgui.PushItemWidth(725)
                imgui.InputTextWithHint("##search", u8("Поиск статьи..."), config.ui.search.description, 256)
                imgui.PopItemWidth()

                imgui.Separator()

                imgui.BeginChild("FederalList", imgui.ImVec2(0, 0), true, imgui.WindowFlags.NoScrollbar)

                for indexFederal, federal in pairs(federals) do
                    local is_match = #searchText == 0 or string.find(lower(federal.description), lower(searchText))

                    RenderAnimated("fed_item_" .. indexFederal, is_match, alpha, function ()
                        local descriptionMenu = federal.description

                        if #descriptionMenu > 85 then
                            descriptionMenu = descriptionMenu:sub(1, 85) .. "..."
                        end

                        local width = imgui.GetContentRegionAvail().x

                        if AnimButton("##" .. indexFederal, imgui.ImVec2(width, 35)) then
                            config.ui.window.federal[0] = false

                            sampSendChat(string.format("/gwarn %s %s", targetID, federal.section))
                        end

                        drawList(width, 0.080, 0, 2, 2, u8(federal.section), u8(descriptionMenu))

                        if imgui.IsItemClicked(1) then
                            ffi.copy(config.ui.punishment.section, u8(federal.section))
                            ffi.copy(config.ui.punishment.description, u8(federal.description))

                            imgui.OpenPopup(u8("Редактирование ##" .. indexFederal))
                        end

                        if imgui.BeginPopupModal(u8("Редактирование ##" .. indexFederal), _, imgui.WindowFlags.NoResize) then
                            imgui.SetWindowSizeVec2(imgui.ImVec2(750, config.ui.bools.redactMode[0] and 425 or 335))

                            imgui.PushItemWidth(725)
                            imgui.Text(u8("Статья:"))
                            imgui.InputText("##section_children", config.ui.punishment.section, 16)

                            imgui.Separator()

                            imgui.Text(u8("Описание:"))
                            imgui.InputTextMultiline("##description_children", config.ui.punishment.description, 256)
                            imgui.PopItemWidth()

                            imgui.Separator()

                            if config.ui.bools.redactMode[0] then
                                if AnimButton(u8("Сохранить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                    federal.section = u8:decode(ffi.string(config.ui.punishment.section))
                                    federal.description = u8:decode(ffi.string(config.ui.punishment.description))

                                    saveConfig()

                                    imgui.CloseCurrentPopup()
                                end

                                if AnimButton(u8("Удалить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                    table.remove(federals, indexFederal)

                                    saveConfig()

                                    imgui.CloseCurrentPopup()
                                end
                            end

                            if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                imgui.CloseCurrentPopup()
                            end

                            imgui.End()
                        end
                    end)
                end

                if config.ui.bools.redactMode[0] then
                    if AnimButton(u8("Добавить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                        table.insert(federals, {
                            section = "1.1 ФП",
                            description = "Описание",
                        })

                        saveConfig()
                    end
                end

                imgui.EndChild()
            else
                imgui.Text(u8("ФП не настроено!"))

                if config.ui.bools.redactMode[0] then
                    if AnimButton(u8("Добавить"), imgui.ImVec2(imgui.GetWindowSize().x - 10, 35)) then
                        table.insert(federals, {
                            section = "1.1 ФП",
                            description = "Описание",
                        })

                        saveConfig()
                    end
                end
            end

            imgui.End()
        end
        imgui.PopFont()
        imgui.PopStyleVar()
    end
)

imgui.OnFrame(
    function() return config.ui.window.administrative[0] or ui.admin > 0.0 end,
    function()
        local alpha = HandleWindowAlpha(config.ui.window.administrative[0], "admin")
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 750, 750

        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)

        imgui.PushFont(font)
        if imgui.Begin(u8("Умная выдача штрафов"), config.ui.window.administrative, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar) then
            imgui.CheckboxRedact()

            if #administratives ~= 0 then
                local searchText = u8:decode(ffi.string(config.ui.search.description))

                imgui.PushItemWidth(725)
                imgui.InputTextWithHint("##search", u8("Поиск статьи..."), config.ui.search.description, 256)
                imgui.PopItemWidth()

                imgui.Separator()

                imgui.BeginChild("AdminList", imgui.ImVec2(0, 0), true, imgui.WindowFlags.NoScrollbar)

                for indexAdministrative, administrative in pairs(administratives) do
                    local is_match = #searchText == 0 or string.find(lower(administrative.description), lower(searchText))

                    RenderAnimated("admin_item_" .. indexAdministrative, is_match, alpha, function ()
                        local descriptionMenu = administrative.description

                        if #descriptionMenu > 75 then
                            descriptionMenu = descriptionMenu:sub(1, 75) .. "..."
                        end

                        local width = imgui.GetContentRegionAvail().x

                        if AnimButton("##" .. indexAdministrative, imgui.ImVec2(width, 35)) then
                            config.ui.window.administrative[0] = false

                            sampSendChat(string.format("/writeticket %s %s %s", targetID, administrative.ticket, administrative.section))
                        end

                        drawList(width, 0.0775, 0.87, 2, 3, u8(administrative.section), u8(descriptionMenu), "$" .. tostring(administrative.ticket):gsub("%D", ""):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", ""))

                        if imgui.IsItemClicked(1) then
                            ffi.copy(config.ui.punishment.section, u8(administrative.section))
                            ffi.copy(config.ui.punishment.description, u8(administrative.description))
                            ffi.copy(config.ui.punishment.ticket, u8(administrative.ticket))

                            imgui.OpenPopup(u8("Редактирование ##" .. indexAdministrative))
                        end

                        if imgui.BeginPopupModal(u8("Редактирование ##" .. indexAdministrative), _, imgui.WindowFlags.NoResize) then
                            imgui.SetWindowSizeVec2(imgui.ImVec2(800, config.ui.bools.redactMode[0] and 490 or 405))

                            imgui.PushItemWidth(775)
                            imgui.Text(u8("Статья:"))
                            imgui.InputText("##section", config.ui.punishment.section, 16)

                            imgui.Separator()

                            imgui.Text(u8("Описание:"))
                            imgui.InputTextMultiline("##description", config.ui.punishment.description, 256)

                            imgui.Separator()

                            imgui.Text(u8("Штраф:"))
                            imgui.InputText("##ticket", config.ui.punishment.ticket, 8)
                            imgui.PopItemWidth()

                            imgui.Separator()

                            if config.ui.bools.redactMode[0] then
                                if AnimButton(u8("Сохранить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                    administrative.section = u8:decode(ffi.string(config.ui.punishment.section))
                                    administrative.description = u8:decode(ffi.string(config.ui.punishment.description))
                                    administrative.ticket = u8:decode(ffi.string(config.ui.punishment.ticket))

                                    saveConfig()

                                    imgui.CloseCurrentPopup()
                                end

                                if AnimButton(u8("Удалить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                    table.remove(administratives, indexAdministrative)

                                    saveConfig()

                                    imgui.CloseCurrentPopup()
                                end
                            end

                            if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                                imgui.CloseCurrentPopup()
                            end

                            imgui.End()
                        end
                    end)
                end

                if config.ui.bools.redactMode[0] then
                    if AnimButton(u8("Добавить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                        table.insert(administratives, {
                            section = "1.1 АК",
                            description = "Описание",
                            ticket = 100000
                        })

                        saveConfig()
                    end
                end

                imgui.EndChild()
            else
                imgui.Text(u8("АК не настроено!"))

                if config.ui.bools.redactMode[0] then
                    if AnimButton(u8("Добавить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 35)) then
                        table.insert(administratives, {
                            section = "1.1 АК",
                            description = "Описание",
                            ticket = 100000
                        })

                        saveConfig()
                    end
                end
            end

            imgui.End()
        end
        imgui.PopFont()
        imgui.PopStyleVar()
    end
)

imgui.OnFrame(
    function() return config.ui.window.notepad[0] or ui.notepad > 0.0 end,
    function()
        local alpha = HandleWindowAlpha(config.ui.window.notepad[0], "notepad")
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 800, 600

        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)

        imgui.PushFont(font)
        if imgui.Begin(u8("Блокнот"), config.ui.window.notepad, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
            imgui.BeginChild("SidePanelNotepad", imgui.ImVec2(200, 0), true, imgui.WindowFlags.NoScrollbar)

            for index, value in pairs(notepad) do
                NavButton(u8(value.title) .. "##" .. index, index, activeNoteTab)

                if imgui.IsItemClicked(1) then
                    ffi.copy(config.ui.notepad.title, u8(value.title))

                    imgui.OpenPopup(u8("Редактирование ##" .. index))
                end

                imgui.Separator()

                if imgui.BeginPopupModal(u8("Редактирование ##" .. index), _, imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(500, 202))

                    imgui.PushItemWidth(475)
                    imgui.InputText("##title", config.ui.notepad.title, 32)
                    imgui.PopItemWidth()

                    imgui.Separator()

                    if AnimButton(u8("Сохранить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 30)) then
                        value.title = u8:decode(ffi.string(config.ui.notepad.title))

                        saveConfig()

                        imgui.CloseCurrentPopup()
                    end

                    if AnimButton(u8("Удалить"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 30)) then
                        table.remove(notepad, index)

                        activeNoteTab[0] = #notepad

                        saveConfig()

                        imgui.CloseCurrentPopup()
                    end

                    if AnimButton(u8("Закрыть"), imgui.ImVec2(imgui.GetWindowSize().x - 25, 30)) then
                        imgui.CloseCurrentPopup()
                    end

                    imgui.End()
                end
            end

            if AnimButton(u8("Добавить запись"), imgui.ImVec2(-1, 35)) then
                table.insert(notepad, {
                    title = "Новая запись",
                    field = ""
                })

                saveConfig()

                activeNoteTab[0] = #notepad
            end

            imgui.EndChild()

            imgui.SameLine()

            imgui.BeginChild("NotepadContent", imgui.ImVec2(0, 0), true)

            if #notepad > 0 and notepad[activeNoteTab[0]] then
                local value = notepad[activeNoteTab[0]]
                ffi.copy(config.ui.notepad.field, u8(value.field))

                if imgui.InputTextMultiline("##notepad_field_" .. tostring(activeNoteTab[0]), config.ui.notepad.field, 8192, imgui.ImVec2(imgui.GetContentRegionAvail().x, imgui.GetContentRegionAvail().y)) then
                    value.field = u8:decode(ffi.string(config.ui.notepad.field))

                    saveConfig()
                end
            else
                imgui.Text(u8("Нет записей!"))
            end

            imgui.EndChild()

            imgui.End()
        end
        imgui.PopFont()
        imgui.PopStyleVar()
    end
)

imgui.OnFrame(
    function() return config.ui.window.searched[0] or ui.searched > 0.0 end,
    function(player)
        local alpha = HandleWindowAlpha(config.ui.window.searched[0], "searched")
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
        imgui.SetNextWindowPos(imgui.ImVec2(settingsSearchedWindow.x, settingsSearchedWindow.y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))

        imgui.PushFont(font)
        if imgui.Begin(u8("Список преступников"), config.ui.window.searched, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar) then
            if imgui.GetIO().MouseClicked[2] then
                player.HideCursor = not player.HideCursor
            end

            if moveSearchedWindow then
                player.HideCursor = false

                local cX, cY = getCursorPos()
                settingsSearchedWindow.x, settingsSearchedWindow.y = cX, cY

                if imgui.IsMouseClicked(0) then
                    saveConfig()

                    moveSearchedWindow, player.HideCursor = false, true
                end
            end

            if AnimButton("/awanted", imgui.ImVec2(425, 30)) then
                sampProcessChatInput("/awanted")
            end

            imgui.Separator()

            if #searched ~= 0 then
                for indexSearch, search in pairs(searched) do
                    imgui.Columns(4)

                    imgui.CenterColumnText(search.level .. " " .. fa.STAR)
                    imgui.SetColumnWidth(-1, 80)

                    imgui.NextColumn()

                    imgui.CenterColumnText(string.format("%s[%s]", search.nickname, search.id))
                    imgui.SetColumnWidth(-1, 180)

                    imgui.NextColumn()

                    imgui.CenterColumnText(u8(search.distance))
                    imgui.SetColumnWidth(-1, 100)

                    imgui.NextColumn()

                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
                    imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.85))

                    if AnimButton(fa.MAGNIFYING_GLASS .. "##" .. indexSearch, imgui.ImVec2(65, 30)) then
                        sampSendChat("/pursuit " .. search.id)
                    end

                    imgui.PopStyleVar()

                    imgui.Columns(1)
                    imgui.Separator()
                end
            else
                imgui.Text(u8("Не найдено преступников!"))
            end

            imgui.End()
        end
        imgui.PopFont()
        imgui.PopStyleVar()
    end
)

local registerCommandWithArgument = function (command, window)
    sampRegisterChatCommand(command, function (id)
        if #id == 0 then
            showNotification("error", "ID не указан!")
            return sendMJHelperMessage("ID не указан!")
        end

        targetID = tonumber(id)
        window[0] = not window[0]
    end)
end

local switchingWindow = function (command, window)
    sampRegisterChatCommand(command, function ()
        window[0] = not window[0]
    end)
end

sampev.onServerMessage = function (color, text)
    local textWithoutHex = text:gsub("{......}", "")

    if afind then
        for _, error in pairs(afindErrors) do
            if textWithoutHex:find(error) then
                afind = false

                showNotification("error", "/afind прекратил свою работу из-за ошибки!")
                sendMJHelperMessage("/afind прекратил свою работу из-за ошибки!")
            end
        end
    end

    if config.ui.bools.autoPursuit[0] and textWithoutHex:match("^Преследование за (.+) было прекращено%, причина%: время погони истекло%.") then
        sampSendChat("/pursuit " .. pursuitID)
    end

    if searchWanted and (textWithoutHex:find("^%[Ошибка%] Используй%: %/wanted %[уровень розыска 1%-6%]") or textWithoutHex:find("^%[Ошибка%] Игроков с таким уровнем розыска нету!")) then
        return false
    end

    if config.ui.bools.customMegaphone[0] and textWithoutHex:match("^:u1f7e5::u1f7e6: (.+) %[(.+)%]: (.*)") then
        local nickname, fraction, message = textWithoutHex:match("^:u1f7e5::u1f7e6: (.+) %[(.+)%]: (.*)")
        local newColor = string.format("%s", toHEX(config.ui.palitre.megafon[0] * 255, config.ui.palitre.megafon[1] * 255, config.ui.palitre.megafon[2] * 255))
        local newText = string.format("{%s}[M] [%s] %s: %s", newColor, fraction, nickname, message)

        sampAddChatMessage(newText, "0x" .. newColor)

        return false
    end

    if bodyCamActive and textWithoutHex:find("^%[Ошибка%] Бодикамера уже активирована") then
        return false
    end

    if not offerActive and textWithoutHex:match("^%[Новое предложение%] Предложение перестанет быть активным через 60 секунд%.") then
        offerActive = true

        sampSendChat("/offer")
    end
end

sampev.onShowDialog = function (dialogId, style, title, button1, button2, text)
    local textWithoutHex = text:gsub("{......}", "")

    if searchWanted and dialogId == 1780 then
        for line in textWithoutHex:gmatch("[^\n]+") do
            local nickname, id, level, distance = line:match("(.+)%((%d+)%)%s+(%d) уровень%s+%[(.+)%]")

            if nickname and id and level and distance then
                if distance:find("в интерьере") then
                    distance = "В интерьере"
                end

                table.insert(searched, {
                    nickname = nickname,
                    id = id,
                    level = level,
                    distance = distance
                })
            end
        end

        return false
    end

    if offerActive then
        if dialogId == 25685 then
            sampSendDialogResponse(dialogId, 1, 0, "")
            return false
        end

        if dialogId == 25686 then
            for line in textWithoutHex:gmatch("[^\n]+") do
                if line:match("%[1%] Отправил предложение%: (.+)") then nickname = line:match("%[1%] Отправил предложение%: (.+)") end
                if line:match("%[2%] Суть предложения%: (.+)") then action = line:match("%[2%] Суть предложения%: (.+)") end
            end

            OfferMenu.show(
                nickname,
                action,
                decodeJson(binds.offerAccept),
                decodeJson(binds.offerDecline),
                function ()
                    sampSendDialogResponse(dialogId, 1, 2, "")
                end,
                function ()
                    sampSendDialogResponse(dialogId, 1, 3, "")
                end,
                function ()
                    sampSendDialogResponse(dialogId, 1, 3, "")
                end
            )

            return false
        end
    end
end

sampev.onSendCommand = function (command)
    takeID = command:match("^/take (.+)")
    pursuitID = command:match("^/pursuit (.+)")
end

sampev.onSendDialogResponse = function (dialogId, button, listboxId, input)
	if config.ui.bools.autoTake[0] and dialogId == 88 and button == 1 then
		sampSendChat("/take " .. takeID)
	end
end

sampev.onSendClientJoin = function () bodyCamActive = false end
sampev.onConnectionClosed = function () bodyCamActive = false end
sampev.onConnectionRejected = function () bodyCamActive = false end
sampev.onSendSpawn = function () bodyCamActive = false end
sampev.onSendDeathNotification = function (reason, killerId) bodyCamActive = false end

local hi = function ()
    showNotification("success", "Хелпер для МЮ инициализирован!")

    sendMJHelperMessage("Хелпер для МЮ инициализирован!")
    sendMJHelperMessage("В консоль SampFuncs написаны все команды для хелпера и их описание!")

    print("/asu - умный розыск")
    print("/agwarn - умное ФП")
    print("/aticket - умная выдача штрафов")
    print("/bl - блокнот")
    print("/afind - поиск игрока по ID")
    print("/awanted - поиск всех игроков в розыске")
    print("/log - переключение вывода сообщений в консоль")
    print("/siren - переключение сирены")
    print("/mj - меню основного функционала скрипта")
end

addEventHandler("onReceivePacket", function (id, bs)
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 16 then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            if length > 0 then
                local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)

                if config.ui.bools.offEffectPursuit[0] and (text:find("frontend/effects/effect_damage2/index.html") or text:find("frontend/effects/effect_blood_pulse/index.html")) then
                    return false
                end
            end
        end
    end
end)

local hotkeys = function ()
    hotkey.RegisterHotKey("mainWindow", false, decodeJson(binds.mainWindow), function ()
        if not sampIsCursorActive() and not sampIsDialogActive() then
            config.ui.window.main[0] = not config.ui.window.main[0]
        end
    end)

    hotkey.RegisterHotKey("siren", false, decodeJson(binds.siren), function ()
        if not sampIsCursorActive() and not sampIsDialogActive() then
            if isCharInAnyCar(PLAYER_PED) and getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) == PLAYER_PED then
                sampProcessChatInput("/siren")
            end
        end
    end)

    hotkey.RegisterHotKey("offerAccept", false, decodeJson(binds.offerAccept), function ()
        if not sampIsCursorActive() and not sampIsDialogActive() then
            OfferMenu.triggerAccept()
        end
    end)

    hotkey.RegisterHotKey("offerDecline", false, decodeJson(binds.offerDecline), function ()
        if not sampIsCursorActive() and not sampIsDialogActive() then
            OfferMenu.triggerDecline()
        end
    end)

    hotkey.RegisterHotKey("searchedWindow", false, decodeJson(binds.searchedWindow), function ()
        if config.ui.window.searched[0] then
            moveSearchedWindow = not moveSearchedWindow
        end
    end)
end

function main()
    while not isSampAvailable() do wait(0) end
    repeat wait(0) until sampIsLocalPlayerSpawned()

    loadConfig()
    saveConfig()

    hi()

    hotkeys()

    registerCommandWithArgument("asu", config.ui.window.wanted)
    registerCommandWithArgument("agwarn", config.ui.window.federal)
    registerCommandWithArgument("aticket", config.ui.window.administrative)

    switchingWindow("bl", config.ui.window.notepad)
    switchingWindow("mj", config.ui.window.main)

    lua_thread.create(function ()
        while true do wait(0)
            if afind then
                sampSendChat("/find " .. targetID)
                wait(2000)
            end
        end
    end)

    lua_thread.create(function ()
        while true do wait(1000)
            if #timers ~= 0 then
                for index, timer in pairs(timers) do
                    if timer.active then
                        timer.time = timer.time - 1

                        saveConfig()

                        if timer.time == 0 then
                            table.remove(timers, index)

                            saveConfig()

                            showNotification("info", string.format("Таймер \"%s\" закончился!", timer.name))
                            sendMJHelperMessage(string.format("Таймер \"%s\" закончился!", timer.name))
                        end
                    end
                end
            end
        end
    end)

    sampRegisterChatCommand("afind", function (id)
        if #id == 0 then
            if afind then
                afind = false

                showNotification("success", "/afind отключён!")
                return sendMJHelperMessage("/afind отключён!")
            end

            showNotification("error", "ID не указан!")
            return sendMJHelperMessage("ID не указан!")
        end

        targetID = tonumber(id)

        if targetID < 0 or targetID > 999 then
            showNotification("error", "ID должен быть от 0 до 999!")
            return sendMJHelperMessage("ID должен быть от 0 до 999!")
        end

        afind = true

        showNotification("success", string.format("Ищу по /find игрока с ID %d!", targetID))
        sendMJHelperMessage(string.format("Ищу по /find игрока с ID %d!", targetID))
    end)

    sampRegisterChatCommand("log", function ()
        logMessage = not logMessage

        saveConfig()

        showNotification("info", string.format("Теперь сообщения от хелпера выводятся в %s!", logMessage and "лог SampFuncs" or "чат"))
        sendMJHelperMessage(string.format("Теперь сообщения от хелпера выводятся в %s!", logMessage and "лог SampFuncs" or "чат"))
    end)

    sampRegisterChatCommand("awanted", function ()
        lua_thread.create(function ()
            searchWanted, searched, config.ui.window.searched[0] = true, {}, true

            showNotification("info", "Составляю список преступников...")
            sendMJHelperMessage("Составляю список преступников...")

            for i = 1, 7 do
                sampSendChat("/wanted " .. i)
                wait(1000)
            end

            searchWanted = false

            if #searched ~= 0 then
                showNotification("success", string.format("Найдено преступников: %s", #searched))
                sendMJHelperMessage("Список преступников составлен!")
                sendMJHelperMessage(string.format("Найдено преступников: %s", #searched))
            else
                showNotification("error", "Список преступников пуст!")
                sendMJHelperMessage("Список преступников пуст!")
            end
        end)
    end)

    sampRegisterChatCommand("siren", function ()
        if isCharInAnyCar(PLAYER_PED) then
            local car = storeCarCharIsInNoSave(PLAYER_PED)

            if getDriverOfCar(car) ~= PLAYER_PED then
                showNotification("error", "Вы должны быть водителем этого транспорта!")
                return sendMJHelperMessage("Вы должны быть водителем этого транспорта!")
            end

            switchCarSiren(car, not isCarSirenOn(car))
            sendMJHelperMessage(string.format("Мигалки %s!", isCarSirenOn(car) and "включены" or "выключены"))
        else
            showNotification("error", "Вы должны находиться в транспорте!")
            sendMJHelperMessage("Вы должны находиться в транспорте!")
        end
    end)

    while true do wait(0)
        for i, timer in pairs(timers) do
            if timer.active then
                renderFontDrawText(renderFont, string.format("%s: %s", timer.name, os.date("!%H:%M:%S", timer.time)), 55, (bodyCamActive and 705 or 775) - (i + 1) * 20, 0xFFFFFFFF, false)
            end
        end

        if sampIsLocalPlayerSpawned() then
            if not bodyCamActive and config.ui.bools.autoBodyCam[0] then
                bodyCamActive = true

                sampSendChat("/bodycamera")
            end
        end
    end
end

addEventHandler("onWindowMessage", function (msg, wp, lp)
    for name, window in pairs(config.ui.window) do
        if name ~= "searched" then
            if wp == 0x1B and window[0] then
                if msg == 0x100 then
                    consumeWindowMessage(true, false)
                end

                if msg == 0x101 then
                    window[0] = false
                end
            end
        end
    end
end)