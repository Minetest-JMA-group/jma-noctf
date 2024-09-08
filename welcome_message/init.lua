local storage = algorithms.get_mod_storage()
local hide = algorithms.getconfig("to_hide", {})

function core.send_join_message(player_name) end

local old_send_leave_message = core.send_leave_message
function core.send_leave_message(player_name, timed_out)
	if hide[player_name] then
		return
	end
	old_send_leave_message(player_name, timed_out)
end

local function checkPlural(timeNum, timeStr)
	if timeNum == 1 then
		return timeStr
	end
	return timeStr .. "s"
end

minetest.register_on_joinplayer(
	function(player, last_login)
		local name = player:get_player_name()
		if hide[name] then
			return true
		end
		if last_login == nil then
			minetest.chat_send_all(minetest.colorize(msg_color.get_color(player), "[" .. name .. "]") .. minetest.colorize("#3B633D", " has joined the game for the first time! Welcome!"))
		else
			local last_login_msg = algorithms.time_to_string(os.time() - last_login)
			minetest.chat_send_all(minetest.colorize("#3B633D", "Welcome back, ") .. minetest.colorize(msg_color.get_color(player), "<" .. name .. ">") .. minetest.colorize("#3B633D", "! Last login: " .. last_login_msg))
		end
		
		return true	-- Prevent regular welcome message from being displayed
	end
)
