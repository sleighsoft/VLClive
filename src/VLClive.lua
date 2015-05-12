-- 00000008
-- Increment the above number by 1 to enable auto update at next extension startup
--[[
The MIT License (MIT)
Copyright (c) 2014 sleighsoft
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

function descriptor()
    return {
        title = "VLClive",
        version = vlclive.version,
        author = "Julian Niedermeier",
        url = 'http://',
        shortdesc = "VLClive",
        description = "Integrates Livestreamer into VLC for easier handling of twitch.tv streams (more to come)",
        capabilities = {"menu", "input-listener", "meta-listener"}
    }
end


function activate()
    -- this is where extension starts
    -- for example activation of extension opens custom dialog box:
    setup()
    if not update_extension_via_github() then
        show_Main()
    else
        show_Update()
    end
end

function deactivate()
    -- what should be done on deactivation of extension
end

function close()
    -- function triggered on dialog box close event
    -- for example to deactivate extension on dialog box close:
    vlc.deactivate()
end

function input_changed()
    -- related to capabilities={"input-listener"} in descriptor()
    -- triggered by Start/Stop media input event
end

function playing_changed()
    -- related to capabilities={"playing-listener"} in descriptor()
    -- triggered by Pause/Play madia input event
end

vlclive = {
    version = 'v1.0',
    default = {
        language = 'en',
        livestream_base_name = 'twitch'
    },
    os = nil,
    path = {
        userdir = nil,
        configfile = nil,
        livestreamer = "livestreamer",
        extension = nil,
        vlcexe = nil
    },
    quality = {
        twitch = {
            "Source", "High", "Medium", "Low", "Mobile", "Audio"
        }
    },
    livestreamBaseURLs = {
        twitch = "twitch.tv/"
    },
    githubSrcFile = "https://raw.githubusercontent.com/sleighsoft/VLClive/master/src/VLClive.lua",
    localSrcFileName = 'VLClive.lua',
    language = {
        de = {
            streamer_name_label = "Einzelner Streamer:",
            streamer_add_button = "Hinzufügen",
            streamer_remove_button = "Entfernen",
            streamer_favourites_label = "Favoriten:",
            streamer_online_button = "Online?",
            livestreamer_quality_label = "Qualität:",
            watch_button = "Stream starten!",
            update_label = "VLClive wurde aktualisiert. Bitte starten sie das Plugin neu",
            favourite_offline_text = "OFF",
            favourite_online_text = "ONLINE",
            twitch_favourites_label = "Importiere alle Favoriten des Nutzers:",
            twitch_favourites_add_button = "Twitch Favoriten hinzufügen"
        },
        en = {
            streamer_name_label = "Single Streamer Channel:",
            streamer_add_button = "Add",
            streamer_remove_button = "Remove",
            streamer_favourites_label = "Favourites:",
            streamer_online_button = "Online?",
            livestreamer_quality_label = "Quality:",
            watch_button = "Watch stream!",
            update_label = "VLClive was updated. Please restart the plugin",
            favourite_offline_text = "OFF",
            favourite_online_text = "ONLINE",
            twitch_favourites_label = "Import all favourites of user:",
            twitch_favourites_add_button = "Add Twitch favourites"
        }
    },
    gui_isOnlineRow = nil
}



local widget_table = {}
local savedStreamers = nil
local dlg = nil
local current_LivestreamBaseName = vlclive.default.livestream_base_name
local current_LivestreamBaseURL = vlclive.livestreamBaseURLs[current_LivestreamBaseName]
local current_QualitySettings = vlclive.quality[current_LivestreamBaseName]


-- Custom part, Dialog box example: -------------------------

function setup()
    local datadir = vlc.config.datadir()
    local userdatadir = vlc.config.userdatadir()

    vlc.msg.dbg("VLC datadir: " .. datadir)
    vlc.msg.dbg("VLC userdatadir: " .. userdatadir)

    -- Determine operating system
    if is_window_path(datadir) then
        vlclive.os = 'win'
        slash = '\\'
    elseif string.find(datadir, 'MacOS') then
        vlclive.os = 'mac'
        slash = '/'
    else
        -- Check for Mac specific code later
        vlclive.os = 'lin'
        slash = '/'
    end

    vlc.msg.dbg('Detected OS is: ' .. vlclive.os)

    -- Setup pathes
    local path_generic = {"lua", "extensions", "userdata", "vlclive"}
    vlclive.path.userdir = userdatadir .. slash .. table.concat(path_generic, slash) .. slash
    vlclive.path.configfile = vlclive.path.userdir .. 'vlclive.config'
    
    if vlclive.os == 'win' then
        vlclive.path.vlcexe = datadir .. slash .. 'vlc.exe'
        vlclive.path.extension = datadir .. slash .. 'lua' .. slash .. 'extensions' .. slash .. vlclive.localSrcFileName
    else
        if vlclive.os == 'mac' then
            vlclive.path.vlcexe = string.gsub(datadir, 'share', 'VLC')
            vlclive.path.extension = datadir .. slash .. 'lua' .. slash .. 'extensions' .. slash .. vlclive.localSrcFileName
        else
            -- Linux like path
            vlclive.path.extension = userdatadir .. slash .. 'lua' .. slash .. 'extensions' .. slash .. vlclive.localSrcFileName
        end
    end

    if vlclive.path.userdir then
        if not is_dir(vlclive.path.userdir) then
            mkdir_p(vlclive.path.userdir)
            vlc.msg.dbg('Creating directory ' .. vlclive.path.userdir)
        end
    end

    if vlclive.path.configfile then
        if not file_exist(vlclive.path.configfile) then
            local fconf = io.open(vlclive.path.configfile, 'w')
            fconf:write('')
            fconf:close()
            vlc.msg.dbg('Created configfile at ' .. vlclive.path.configfile)
        end
    end
end

function create_MainDialog()
    local row = 1
    local lang = vlclive.default.language
    -- First row
    widget_table['streamer_name_label'] = dlg:add_label(vlclive.language[lang].streamer_name_label, 1, row, 1, 1)
    widget_table['streamer_name_input'] = dlg:add_text_input('', 2, row, 2, 1)
    widget_table['streamer_add_button'] = dlg:add_button(vlclive.language[lang].streamer_add_button, addFav_Action, 4, row, 1, 1)
    widget_table['streamer_remove_button'] = dlg:add_button(vlclive.language[lang].streamer_remove_button, removeFav_Action, 5, row, 1, 1)
    -- Second row
    row = row + 1
    widget_table['twitch_favourites_label'] = dlg:add_label(vlclive.language[lang].twitch_favourites_label, 1, row, 1, 1)
    widget_table['twitch_favourites_input'] = dlg:add_text_input('', 2, row, 2, 1)
    widget_table['twitch_favourites_add_button'] = dlg:add_button(vlclive.language[lang].twitch_favourites_add_button, addTwitchFav_Action, 4, row, 2, 1)
    -- Third row
    row = row + 1;
    vlclive.gui_isOnlineRow = row
    widget_table['streamer_favourites_label'] = dlg:add_label(vlclive.language[lang].streamer_favourites_label, 1, row, 1, 1)
    widget_table['streamer_favourites_dropdown'] = dlg:add_dropdown(2, row, 2, 1)
    widget_table['streamer_online_button'] = dlg:add_button(vlclive.language[lang].streamer_online_button, refresh_Action, 4, row, 1, 1)
    -- Fourth row
    row = row + 1;
    widget_table['livestreamer_quality_label'] = dlg:add_label(vlclive.language[lang].livestreamer_quality_label, 1, row, 1, 1)
    widget_table['livestreamer_quality_dropdown'] = dlg:add_dropdown(2, row, 2, 1)
    widget_table['watch_button'] = dlg:add_button(vlclive.language[lang].watch_button, watch_Action, 5, row, 1, 1)

    -- Add availabel quality settings to the dropdown
    for key, value in ipairs(current_QualitySettings) do
        add_to_qualityDropdown(key, value)
    end

    savedStreamers = loadStreamersFromConfig()
    widget_table['streamer_favourites_dropdown']:add_value('----', 0)
    if savedStreamers then
        for key, value in ipairs(savedStreamers) do
            add_to_streamerDropdown(key, value)
        end
    else
        savedStreamers = nil
    end
end

function create_UpdateDialog()
    widget_table['update_label'] = dlg:add_label(vlclive.language[vlclive.default.language].update_label, 1, 1, 1, 1)
end

function create_SettingsDialog()
    -- Maybe later
end

function trigger_menu(dlgId)
    if dlgId == 1 then
        close_dlg()
        dlg = vlc.dialog('VLClive ' .. vlclive.version)
        create_MainDialog()
    elseif dlgId == 2 then
        close_dlg()
        dlg = vlc.dialog('Extension Updated!')
        create_UpdateDialog()
    end
end

function show_Main()
    trigger_menu(1)
end

function show_Update()
    trigger_menu(2)
end

function close_dlg()
    if dlg then 
        --~ dlg:delete() -- Throw an error
        dlg:hide() 
    end
    
    dlg = nil
    widget_table = nil
    widget_table = {}
    collectgarbage() --~ !important 
end

function watch_Action()
    local input_string = widget_table['streamer_name_input']:get_text()
    local dropdown_string = widget_table['streamer_favourites_dropdown']:get_value()
    local quality_string = widget_table['livestreamer_quality_dropdown']:get_value()
    quality_string = current_QualitySettings[quality_string]
    if dropdown_string == 0 then
        dropdown_string = ''
    else
        input_string = savedStreamers[dropdown_string]
    end
    vlc.msg.dbg(input_string)
    if input_string ~= '' and input_string then
        local cmd = ''
        if vlclive.os == 'win' then
            cmd = 'start /min "" "' .. vlclive.path.livestreamer .. '" ' .. current_LivestreamBaseURL .. input_string .. ' ' .. quality_string .. ' --player "' .. vlclive.path.vlcexe .. '" & exit'
        elseif vlclive.os == 'mac' then
            vlc.msg.dbg("Livestreamer: " .. vlclive.path.livestreamer)
            vlc.msg.dbg("BaseURL: " .. current_LivestreamBaseURL)
            vlc.msg.dbg("Quality: " .. quality_string)
            vlc.msg.dbg("Exepath: " .. vlclive.path.vlcexe)
            cmd = "osascript -e 'tell application \"Terminal\" to do script \"" .. vlclive.path.livestreamer .. ' ' .. current_LivestreamBaseURL .. input_string .. ' ' .. quality_string .. " && exit\"'"
        elseif vlclive.os == 'lin' then
            vlc.msg.dbg("Livestreamer: " .. vlclive.path.livestreamer)
            vlc.msg.dbg("BaseURL: " .. current_LivestreamBaseURL)
            vlc.msg.dbg("Quality: " .. quality_string)
            cmd = vlclive.path.livestreamer .. ' ' .. current_LivestreamBaseURL .. input_string .. ' ' .. quality_string
        end
        vlc.msg.dbg(cmd)
        os.execute(cmd)
    end
end

function refresh_Action()
    local row = vlclive.gui_isOnlineRow
    dlg:del_widget(widget_table['streamer_favourites_dropdown'])
    dlg:del_widget(widget_table['streamer_online_button'])
    loadingLabel = dlg:add_label('Loading...', 4, row, 1, 1)
    dlg:update()
    widget_table['streamer_favourites_dropdown'] = dlg:add_dropdown(2, row, 2, 1)
    widget_table['streamer_favourites_dropdown']:add_value("----", 0)
    local tStreamerNames = is_online(savedStreamers)
    for key,value in ipairs(tStreamerNames) do
        widget_table['streamer_favourites_dropdown']:add_value(value, key)
    end
    dlg:del_widget(loadingLabel)
    widget_table['streamer_online_button'] = dlg:add_button('Is Online?', refresh_Action, 4, row, 1, 1)
end

function add_to_streamerDropdown(index)
    local streamerName = savedStreamers[index]
    widget_table['streamer_favourites_dropdown']:add_value(streamerName, index)
end

function add_to_qualityDropdown(index)
    local qualityName = current_QualitySettings[index]
    widget_table['livestreamer_quality_dropdown']:add_value(qualityName, index)
end

-- Queries the twitch api for all 'favourite' streamers
-- Appends their online status to the name
function is_online(tStreamerNames)
    -- Copy the table to not affect the table that is used for querying
    local localStreamerTable = table_shallow_copy(tStreamerNames)
    local requestURL = 'https://api.twitch.tv/kraken/streams?channel='
    for key,value in ipairs(localStreamerTable) do
        requestURL = requestURL .. value .. ","
    end
    vlc.msg.dbg(requestURL)
    local stream = vlc.stream(requestURL)
    local data = stream:readline()
    local onlineCount = 0
    if data then
        data = string.lower(data)
        for key,value in ipairs(localStreamerTable) do
            local online = string.find(data, '"display_name":"' .. string.lower(value) .. '"')
            if not online then
                localStreamerTable[key] = value .. ' (' .. vlclive.language[vlclive.default.language].favourite_offline_text .. ')'
            else
                onlineCount = onlineCount + 1
                localStreamerTable[key] = value .. ' (' .. vlclive.language[vlclive.default.language].favourite_online_text .. ')'
            end 
        end
    end
    local sortedByOnline = true -- This is a placeholder, maybe a settings page will be added later which enables configuration of this value
    if sortedByOnline then
        local sortedStreamerTable = {}
        local onlineIndex = 0
        local offlineIndex = onlineCount
        for key,value in ipairs(localStreamerTable) do
            if string.find(value, vlclive.language[vlclive.default.language].favourite_offline_text) then
                sortedStreamerTable[offlineIndex] = value
                vlc.msg.dbg("Offline @" .. offlineIndex .. " ::: " .. value)
                offlineIndex = offlineIndex + 1
            else
                sortedStreamerTable[onlineIndex] = value
                vlc.msg.dbg("Online @" .. onlineIndex .. " ::: " .. value)
                onlineIndex = onlineIndex + 1
            end
        end
        localStreamerTable = sortedStreamerTable
    end
    stream = nil
    data = nil
    return localStreamerTable
end

function addFav_Action()
    local input_string = widget_table['streamer_name_input']:get_text()
    if input_string ~= '' then
        if not table_contains_item(savedStreamers, input_string) then
            write_line(vlclive.path.configfile, input_string)
            widget_table['streamer_favourites_dropdown']:add_value(input_string)
            table.insert(savedStreamers, input_string)
        end
    end
end

-- Adds every user the user that has been entered follows to the local favourites list
function addTwitchFav_Action()
    local input_string = widget_table['twitch_favourites_input']:get_text()
    if input_string then
        local offset = 0
        local limit = 100
        local isFirst = true
        local number_of_items = 0
        repeat
            local data = getTwitchFavByUser(input_string, offset, limit)
            if data then
                if isFirst then
                    for num in string.gfind(data, '"_total":([0-9]+)') do
                        number_of_items = num
                        vlc.msg.err(number_of_items)
                    end
                    isFirst = false
                end
                for name in string.gfind(data, '"display_name":"([a-zA-Z0-9_]+)') do
                    if not table_contains_item(savedStreamers, name) then
                        write_line(vlclive.path.configfile, name)
                        widget_table['streamer_favourites_dropdown']:add_value(name)
                        table.insert(savedStreamers, name)
                    end
                end
            end
            number_of_items = number_of_items - limit
            offset = offset + limit
        until number_of_items <= 0
    end
end

function getTwitchFavByUser(user, offset, limit)
    local requestURL = 'https://api.twitch.tv/kraken/users/'
    requestURL = requestURL .. user .. '/follows/channels?limit=' .. limit .. '&offset=' .. offset
    vlc.msg.dbg("Requesting user follows for " .. requestURL)
    local stream = vlc.stream(requestURL)
    local data = stream:readline()
    stream = nil
    if data then
        data = string.lower(data)
    end
    return data
end

function removeFav_Action()
    local input_string = widget_table['streamer_name_input']:get_text()
    local key = table_contains_item(savedStreamers, input_string)
    if key then
        table.remove(savedStreamers, key)
        write_lines(vlclive.path.configfile, savedStreamers)
    end
    dlg:del_widget(widget_table['streamer_favourites_dropdown'])
    widget_table['streamer_favourites_dropdown'] = dlg:add_dropdown(2, 2, 2, 1)
    widget_table['streamer_favourites_dropdown']:add_value('----', 0)
    for key, value in ipairs(savedStreamers, add_to_streamerDropdown) do
        add_to_streamerDropdown(key, value)
    end
end

function table_contains_item(table, item)
    for key,value in ipairs(table) do
        if value == item then
            return key
        end
    end
    return nil
end

function table_shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function loadStreamersFromConfig()
    return read_lines(vlclive.path.configfile)
end

function read_line(filepath)
    if file_exist(filepath) then
        local file = io.open(filepath, 'r')
        local line = file:read('*line')
        return line
    end
    return ''
end

function read_lines(filepath) -- read lines from a file into a table
    if file_exist(filepath) then
        local tLines = {}
        for line in io.lines(filepath) do
            table.insert(tLines, line)
        end
        return tLines
    end
    return nil
end

function write_line(filepath, line)
    if file_exist(filepath) then
        local file = io.open(filepath, "a")
        file:write(line .. "\n")
        file:close()
    end
end

function write_lines(filepath, tlines)
    local file = io.open(filepath, 'w+')
    for key,value in ipairs(tlines) do
        file:write(value .. '\n')
    end
    file:close()
end

function file_touch(name) -- test writetability
    if not name or trim(name) == ''
    then return false end
    
    local f=io.open(name ,'w')
    if f~=nil then 
        io.close(f) 
        return true 
    else 
        return false 
    end
end

function file_exist(name) -- test readability
    if not name or trim(name) == '' 
    then return false end
    local f=io.open(name ,'r')
    if f~=nil then 
        io.close(f) 
        return true 
    else 
        return false 
    end
end

function is_window_path(path)
    return string.match(path, '^(%a:.+)$')
end

function mkdir_p(path) -- create a directory windows or linux via commandline
    if not path or trim(path) == ''
    then return false end
    vlc.msg.dbg(vlclive.os)
    if vlclive.os == 'win' then
        os.execute('mkdir "' .. path ..'"')
    elseif vlclive.os == "lin" or vlclive.os == "mac" then
        os.execute("mkdir -p '" .. path .."'")
    end
end

function trim(str)
    if not str then return "" end
    return string.gsub(str, "^[\r\n%s]*(.-)[\r\n%s]*$", "%1")
end

function is_win_safe(path)
    if not path or trim(path) == "" 
    or not is_window_path(path)
    then return false end
    return string.match(path, "^%a?%:?[\\%w%p%s§¤]+$")
end

function is_dir(path) -- checks if given path is a directory
    if not path or trim(path) == "" 
    then return false end
    -- Remove slash at the end or it won't work on Windows
    path = string.gsub(path, "^(.-)[\\/]?$", "%1")
    local f, _, code = io.open(path, "rb")
    
    if f then 
        _, _, code = f:read("*a")
        f:close()
        if code == 21 then
            return true
        end
    elseif code == 13 then
        return true
    end
    
    return false
end

function update_extension_via_github()
    -- check online github version number
    local stream = vlc.stream(vlclive.githubSrcFile)
    local data = stream:readline()
    stream = nil
    local github_version_number = string.gsub(data, '-- ', '')
    data = nil
    -- check local version number
    local local_version_number = string.gsub(read_line(vlclive.path.extension), '-- ', '')
    vlc.msg.dbg("Github version: " .. github_version_number .. " Local version: " .. local_version_number)

    if local_version_number < github_version_number then
        vlc.msg.dbg('Update available at ' .. vlclive.githubSrcFile)
        local stream = vlc.stream(vlclive.githubSrcFile)
        local data = ""
        local extension_file = io.open(vlclive.path.extension, "w+")
                
        while data do
            extension_file:write(data)
            data = stream:read(65536)
        end

        extension_file:flush()
        extension_file:close()
        stream = nil
        collectgarbage()
        return true
    end
    return false
end