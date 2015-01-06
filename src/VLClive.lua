-- 00000001
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
		description = "Integrates Livestreamer into VLC for easier handling of currently only twitch.tv streams.",
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
	version = 'v0.8',
	os = nil,
	path = {
		userdir = nil,
		configfile = nil,
		livestreamer = nil,
		extension = nil,
		vlcexe = nil
	},
	streamerOfflineText = 'OFF',
	streamerOnlineText = 'ONLINE',
	quality = {
		twitch = {
			"Source", "High", "Medium", "Low", "Mobile", "Audio"
		}
	},
	default_LivestreamBaseName = "twitch",
	livestreamBaseURLs = {
		twitch = "twitch.tv/"
	},
	githubSrcFile = "https://raw.githubusercontent.com/sleighsoft/VLClive/master/src/VLClive.lua",
	localSrcFileName = 'VLClive.lua'
}



local widget_table = {}
local dlg = nil
local current_LivestreamBaseName = vlclive.default_LivestreamBaseName
local current_LivestreamBaseURL = vlclive.livestreamBaseURLs[current_LivestreamBaseName]
local current_QualitySettings = vlclive.quality[current_LivestreamBaseName]


-- Custom part, Dialog box example: -------------------------

function setup()
	local datadir = vlc.config.datadir()
	local userdatadir = vlc.config.userdatadir()
	vlc.msg.dbg("DATADIR: " .. datadir)
	vlc.msg.dbg("USERDATADIR: " .. userdatadir)
  	if is_window_path(datadir) then
		vlclive.os = 'win'
		slash = '\\'
	else
		-- Check for Mac specific code later
		vlclive.os = 'lin'
		slash = '/'
	end

	local path_generic = {"lua", "extensions", "userdata", "vlclive"}
	vlclive.path.userdir = userdatadir .. slash .. table.concat(path_generic, slash) .. slash
	vlclive.path.configfile = vlclive.path.userdir .. 'vlclive.config'
	if vlclive.os == 'win' then
		vlclive.path.livestreamer = vlclive.path.userdir .. 'livestreamer' .. slash .. 'livestreamer.exe'
		vlclive.path.vlcexe = datadir .. slash .. 'vlc.exe'
		vlclive.path.extension = datadir .. slash .. 'lua' .. slash .. 'extensions' .. slash .. vlclive.localSrcFileName
	else
		if string.find(datadir, 'MacOS') ~= nil then
			vlclive.path.vlcexe = string.gsub(datadir, 'share', 'VLC')
			vlclive.os = 'mac'
			vlclive.path.extension = datadir .. slash .. 'lua' .. slash .. 'extensions' .. slash .. vlclive.localSrcFileName
		else
			-- Linux like path
			vlclive.path.extension = datadir .. slash .. 'lua' .. slash .. 'extensions' .. slash .. vlclive.localSrcFileName
		end
	end

	-- Override livestreamer path if a console version is available
	local consoleLivestreamerInstalled = os.execute('livestreamer')
	if consoleLivestreamerInstalled == 0 then
		vlclive.path.livestreamer = 'livestreamer'
	end
	
	if vlclive.path.userdir then
		if not is_dir(vlclive.path.userdir) then
			mkdir_p(vlclive.path.userdir)
			vlc.msg.dbg('Creating dir ' .. vlclive.path.userdir)
		end
	end

	if vlclive.path.configfile then
		if not file_exist(vlclive.path.configfile) then
			local fconf = io.open(vlclive.path.configfile, 'w')
			fconf:write('')
			fconf:close()
		end
	end
	vlc.msg.dbg("Extension path: " .. vlclive.path.extension)
end

function create_MainDialog()
	-- widget_table['livestream_site_lable'] = dlg:add_label('Livestream Site: ', 1, 1, 1, 1)
	-- widget_table['livestream_site_dropdown'] = dlg:add_dropdown(2, 1, 2, 1)
	-- widget_table['livestream_site_load'] = dlg:add_button('Load Site', loadSite_Action, 4, 1, 2, 1)
  	widget_table['streamer_name_lable'] = dlg:add_label('Streamer Channel: ', 1, 1, 1, 1)
    widget_table['streamer_name_input'] = dlg:add_text_input('', 2, 1, 2, 1)
    widget_table['streamer_add_button'] = dlg:add_button('Add', addFav_Action, 4, 1, 1, 1)
    widget_table['streamer_remove_button'] = dlg:add_button('Remove', removeFav_Action, 5, 1, 1, 1)
    widget_table['streamer_favourites_lable'] = dlg:add_label('Favourites: ', 1, 2, 1, 1)
   	widget_table['streamer_favourites_dropdown'] = dlg:add_dropdown(2, 2, 2, 1)
   	widget_table['streamer_online_button'] = dlg:add_button('Is Online?', refresh_Action, 4, 2, 1, 1)
   	widget_table['livestreamer_quality_lable'] = dlg:add_label('Quality: ', 1, 3, 1, 1)
   	widget_table['livestreamer_quality_dropdown'] = dlg:add_dropdown(2, 3, 2, 1)

	for key,value in ipairs(current_QualitySettings) do
		add_to_qualityDropdown(key, value)
	end
   	--table.foreach(current_QualitySettings, add_to_qualityDropdown)
   	widget_table['watch_button'] = dlg:add_button('Watch!',watch_Action, 5, 3, 1, 1)

   	savedStreamers = loadStreamersFromConfig()
   	widget_table['streamer_favourites_dropdown']:add_value('----', 0)
   	if savedStreamers ~= nil then
		for key,value in ipairs(savedStreamers) do
			add_to_streamerDropdown(key,value)
		end
   		--table.foreach(savedStreamers, add_to_streamerDropdown)
   	else
   		savedStreamers = {}
   	end
end

function create_UpdateDialog()
	widget_table['update_lable'] = dlg:add_label('Extension updated! Restart it to apply the update', 1, 1, 1, 1)
end

function create_SettingsDialog()
	widget_table['livestreamer_path_lable'] = dlg:add_label('Path to livestreamer.exe', 1, 1, 1, 1)
	widget_table['livestreamer_path_input'] = dlg:add_text_input(1, 2, 1, 1)
	widget_table['settings_save_button'] = dlg:add_button('Save', settings_Save_Action, 1, 3, 1, 1)
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
	if dlg ~= nil then 
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
  	if input_string ~= '' and input_string ~= nil then
  		local cmd = ''
  		if vlclive.os == 'win' then
  			cmd = 'start /min "" "' .. vlclive.path.livestreamer .. '" ' .. current_LivestreamBaseURL .. input_string .. ' ' .. quality_string .. ' --player "' .. vlclive.path.vlcexe .. '" & exit'
  		elseif vlclive.os == 'mac' then
  			vlc.msg.dbg("Livestreamer: " .. vlclive.path.livestreamer)
  			vlc.msg.dbg("BaseURL: " .. current_LivestreamBaseURL)
  			vlc.msg.dbg("Quality: " .. quality_string)
  			vlc.msg.dbg("Exepath: " .. vlclive.path.vlcexe)
  			cmd = "osascript -e 'tell application \"Terminal\" to do script \"" .. vlclive.path.livestreamer .. ' ' .. current_LivestreamBaseURL .. input_string .. ' ' .. quality_string .. " && exit\"'"
  		end
   		vlc.msg.dbg(cmd)
  		os.execute(cmd)
  	end
end

function refresh_Action()
	dlg:del_widget(widget_table['streamer_favourites_dropdown'])
	dlg:del_widget(widget_table['streamer_online_button'])
	loadingLabel = dlg:add_label('Loading...', 4, 2, 1, 1)
	dlg:update()
	widget_table['streamer_favourites_dropdown'] = dlg:add_dropdown(2, 2, 2, 1)
	widget_table['streamer_favourites_dropdown']:add_value("----", 0)
	local tStreamerNames = is_online(savedStreamers)
	for key,value in ipairs(tStreamerNames) do
		widget_table['streamer_favourites_dropdown']:add_value(value, key)
	end
	dlg:del_widget(loadingLabel)
	widget_table['streamer_online_button'] = dlg:add_button('Is Online?', refresh_Action, 4, 2, 1, 1)
end

function add_to_streamerDropdown(index)
	local streamerName = savedStreamers[index]
	widget_table['streamer_favourites_dropdown']:add_value(streamerName, index)
end

function add_to_qualityDropdown(index)
	local qualityName =	current_QualitySettings[index]
	widget_table['livestreamer_quality_dropdown']:add_value(qualityName, index)
end

function is_online(tStreamerNames)
	local localStreamerTable = table_shallow_copy(tStreamerNames)
	local requestURL = 'https://api.twitch.tv/kraken/streams?channel='
	for key,value in ipairs(localStreamerTable) do
		requestURL = requestURL .. value .. ","
	end
	vlc.msg.dbg(requestURL)
	local stream = vlc.stream(requestURL)
   	local data = string.lower(stream:readline())

   	for key,value in ipairs(localStreamerTable) do
		local online = string.find(data, '"display_name":"' .. string.lower(value) .. '"')
		if not online then
			localStreamerTable[key] = value .. ' (' .. vlclive.streamerOfflineText .. ')'
	   	else
	   		localStreamerTable[key] = value .. ' (' .. vlclive.streamerOnlineText .. ')'
	   	end 
	end
   	stream = nil
   	data = nil
   	online = nil
   	return localStreamerTable
end

function addFav_Action()
	local input_string = widget_table['streamer_name_input']:get_text()
	if input_string ~= "" or input_string ~= nil then
		if not table_contains_item(savedStreamers, input_string) then
			write_line(vlclive.path.configfile, input_string)
			widget_table['streamer_favourites_dropdown']:add_value(input_string)
			table.insert(savedStreamers, input_string)
		end
	end
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
	table.foreach(savedStreamers, add_to_streamerDropdown)
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
   	vlc.msg.dbg(github_version_number)
   	-- check local version number
   	vlc.msg.dbg(vlclive.path.extension)
   	local local_version_number = string.gsub(read_line(vlclive.path.extension), '-- ', '')

   	if local_version_number < github_version_number then
   		vlc.msg.dbg('Update available at ' .. vlclive.githubSrcFile)


   		local stream = vlc.stream(vlclive.githubSrcFile)
		local data = ""
		local extension_file = io.open(vlclive.path.extension, "w+")
	   
		vlc.msg.dbg("The opened file is: " .. extension_file)

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
