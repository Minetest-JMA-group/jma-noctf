mail = {
	-- version
	version = 3,

	-- mod storage
	storage = minetest.get_mod_storage(),

	-- ui theme prepend
	theme = "",

	-- ui forms
	ui = {},

	-- per-user ephemeral data
	selected_idxs = {
		inbox = {},
		outbox = {},
		drafts = {},
		trash = {},
		message = {},
		contacts = {},
		maillists = {},
		to = {},
		cc = {},
		bcc = {},
		boxtab = {},
		sortfield = {},
		sortdirection = {},
		filter = {},
		multipleselection = {},
		optionstab = {},
		settings_group = {},
		contributor_grouping = {},
	},

	message_drafts = {}
}

if minetest.get_modpath("default") then
	mail.theme = default.gui_bg .. default.gui_bg_img
end

-- sub files
local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP .. "/util/init.lua")
dofile(MP .. "/chatcommands.lua")
dofile(MP .. "/migrate.lua")
dofile(MP .. "/hud.lua")
dofile(MP .. "/storage.lua")
dofile(MP .. "/api.lua")
dofile(MP .. "/gui.lua")
dofile(MP .. "/onjoin.lua")
dofile(MP .. "/player_recipients.lua")
-- sub directories
dofile(MP .. "/ui/init.lua")

-- migrate storage
mail.migrate()

if minetest.get_modpath("mtt") then
	dofile(MP .. "/mtt.lua")
	dofile(MP .. "/api.spec.lua")
	dofile(MP .. "/migrate.spec.lua")
	dofile(MP .. "/util/uuid.spec.lua")
	dofile(MP .. "/util/normalize.spec.lua")
end

-- Feed composed mail into the AI moderator's context (if present);
-- optional_depends guarantees ai_filter_watcher is loaded before this mod.
if minetest.global_exists("ai_filter_watcher") then
	mail.register_on_send(function(m)
		local recipients, seen = {}, {}
		for _, field in ipairs({"to", "cc", "bcc"}) do
			if m[field] and m[field] ~= "" and not seen[m[field]] then
				seen[m[field]] = true
				table.insert(recipients, m[field])
			end
		end
		local subject = m.subject:match("^%s*(.-)%s*$")
		local content = subject ~= "" and (subject .. ": " .. m.body) or m.body
		ai_filter_watcher.add_message(m.from, content, "MAIL to " .. table.concat(recipients, ", "))
	end)
end
