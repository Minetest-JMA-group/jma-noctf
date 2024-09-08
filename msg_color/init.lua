msg_color = {}

local storage = algorithms.get_mod_storage()

local tags = algorithms.getconfig("tag_list", {["[Admin]"]="#FF0000", ["[Moderator]"]="#3C3CC8", ["[Guardian]"]="#788296", ["[Developer]"]="#BE00C8"})
local tag_namecolor = algorithms.getconfig("tag_namecolor_list", {["[Admin]"]="#FF0000", ["[Moderator]"]="#3C3CC8", ["[Guardian]"]="#788296", ["[Developer]"]="#BE00C8"})
local colors = algorithms.getconfig("color_list", {"#E4FF00", "#17FF00", "#06E5CE", "#0617E5", "#005A28"})
local i = 0

local player_colors = {} -- Only for regular players
local player_tags = {}

minetest.register_chatcommand("msg_color", {
	description = "Manage chat tags and name colors",
	params = "<command> <command_args>",
	privs = { server=true },
	func = function(name, param)
		local iter = param:gmatch("%S+")
		local command = iter()

		if command == "help" then
			minetest.chat_send_player(name, "List of possible commands:")
			minetest.chat_send_player(name, "listtags: Lists the available tags")
			minetest.chat_send_player(name, "settag <name> <tag>: Sets the player's tag")
			minetest.chat_send_player(name, "unsettag <name>: Unset the player's tag")
			minetest.chat_send_player(name, "tagcolor <tag> <color>: Sets the color of the tag itself")
			minetest.chat_send_player(name, "namecolor <tag> <color>: Sets the name color for players with the given tag")
			minetest.chat_send_player(name, "rm [tag/color] <tagstr/colorstr>: Remove tag/color equal to tagstr/colorstr")
			minetest.chat_send_player(name, "add [tag/color] <tagstr/colorstr>: Add tag/color equal to tagstr/colorstr")
			return true
		end
		if command == "listtags" then
			minetest.chat_send_player(name, "List of available tags:")
			for tag, tag_color in pairs(tags) do
				minetest.chat_send_player(name, tag..": "..minetest.colorize(tag_color, tag).." "..minetest.colorize(tag_namecolor[tag], "<Username>"))
			end
			return true
		end
		if command == "unsettag" then
			local pname = iter()
			if pname == nil then
				return false, "Please provide a player name."
			end
			if not player_tags[pname] then
				return false, "Player "..pname.." doesn't have any tag."
			end
			player_tags[pname] = nil
			storage:set_string(pname.."_tag", "")
			return true, "Removed tags from player "..pname
		end
		if command == "settag" then
			local pname = iter()
			if pname == nil then
				return false, "Please provide a player name."
			end
			local tagname = iter()
			if tags[tagname] then
				player_tags[pname] = tagname
				storage:set_string(pname.."_tag", tagname)
				return true, "Added tag "..tagname.." to "..pname
			end
			return false, "Tag not found."
		end
		if command == "tagcolor" then
			local tagname = iter()
			if tagname == nil then
				return false, "Please provide a tag."
			end
			if tags[tagname] then
				local color = iter()
				if color == nil then
					return false, "Please provide a color."
				end
				tags[tagname] = color
				storage:set_string("tag_list", minetest.serialize(tags))
				return true, "Set tag "..tag.." color to "..minetest.colorize(color, color)
			end
			return false, "Tag not found."
		end
		if command == "namecolor" then
			local tag = iter()
			if tag == nil then
				return false, "Please provide a tag."
			end
			if tags[tag] then
				local color = iter()
				if color == nil then
					return false, "Please provide a color."
				end
				tag_namecolor[tag] = color
				storage:set_string("tag_namecolor_list", minetest.serialize(tag_namecolor))
				return true, "Set tag "..tag.." name color to "..minetest.colorize(color, color)
			end
			return false, "Tag not found."
		end
		if command == "add" then
			local what = iter()
			local ident = iter()
			if ident == nil then
				return false, "Incorrect usage. Check /msg_color help"
			end
			if what == "tag" then
				if tags[ident] then
					return false, "Tag "..ident.." already exists."
				end
				tags[ident] = "#FFFFFF"
				tag_namecolor[ident] = "#FFFFFF"
				storage:set_string("tag_list", minetest.serialize(tags))
				storage:set_string("tag_namecolor_list", minetest.serialize(tag_namecolor))
				return true, "Tag "..ident.." added."
			end
			if what == "color" then
				if algorithms.table_contains(colors, ident) then
					return false, "Color "..ident.." already exists."
				end
				table.insert(colors, ident)
				storage:set_string("color_list", minetest.serialize(colors))
				return true, "Color "..ident.." added."
			end
			return false, "First argument must be \"tag\" or \"color\""
		end
		if command == "rm" then
			local what = iter()
			local ident = iter()
			if ident == nil then
				return false, "Incorrect usage. Check /msg_color help"
			end
			if what == "tag" then
				if not tags[ident] then
					return false, "Tag "..ident.." doesn't exist."
				end
				tags[ident] = nil
				storage:set_string("tag_list", minetest.serialize(tags))
				if tag_namecolor[ident] then
					tag_namecolor[ident] = nil
					storage:set_string("tag_namecolor_list", minetest.serialize(tag_namecolor))
				end
				return true, "Tag "..ident.." removed."
			end
			if what == "color" then
				if not algorithms.table_contains(colors, ident) then
					return false, "Color "..ident.." doesn't exist."
				end
				table.remove(colors, ident)
				storage:set_string("color_list", minetest.serialize(colors))
				return true, "Color "..ident.." removed."
			end
			return false, "First argument must be \"tag\" or \"color\""
		end
		return false, "Please provide an argument. View all arguments with /msg_color help"
	end
})

local function get_color_index()
	i = i + 1
	if i > #colors then
		i = 1
	end
	return i
end

function msg_color.get_color(name)
	local tag = player_tags[name]
	if not tags[tag] then
		player_tags[name] = nil
		tag = nil
		player_colors[name] = colors[get_color_index()]
	end
	if not tag then
		return player_colors[name]
	end
	return tag_namecolor[tag]
end

minetest.register_on_joinplayer(
	function(player)
		local name = player:get_player_name()
		local tag = storage:get_string(name.."_tag")
		if not tags[tag] then
			storage:set_string(name.."_tag", "")
			tag = ""
		end
		if tag ~= "" then
			player_tags[name] = tag
			return
		end

		-- Continue for normal players
		player_colors[name] = colors[get_color_index()]
	end
)

minetest.register_on_leaveplayer(
	function(player, timed_out)
		local name = player:get_player_name()
		player_colors[name] = nil
		player_tags[name] = nil
	end
)

function minetest.format_chat_message(name, message)
	if filter_caps then
		message = filter_caps.parse(name, message)
	end
	local namecolor = msg_color.get_color(name)	-- Also update player_tags for this name
	local tag = player_tags[name]
	if tag then
		tag = minetest.colorize(tags[tag], tag).." "
	else
		tag = ""
	end

	return tag .. minetest.colorize(namecolor, '<' .. name .. '> ') .. message
end