local nk = require("nakama")
nk.logger_info("Hello World!")

local function leaderboard_rpc(context, payload)
	local json = nk.json_decode(payload)
	local id = json.name
	local authoritative = false
	local sort = "desc"
	local operator = "best"
	nk.leaderboard_create(id, authoritative, sort, operator)
	return nk.json_encode({["success"] = true})
end

local purge_rpc = function(context, payload)
    if context.user_id and not context.user_id == "" then
        nk.logger_error("rpc was called by a user")
        return nil
    end

	local users = nk.users_get_random(100)
	local userIds = {}

	for _, u in ipairs(users) do
		local message = string.format("id: %q, displayname: %q", u.user_id, u.display_name)
		table.insert(userIds, u.user_id)
		nk.logger_info(message)
	end

	local utc_msec = nk.time()
	local message = nk.json_encode({["time"] = utc_msec})

    return message
end

nk.register_rpc(leaderboard_rpc, "Create leaderboard")
nk.register_rpc(purge_rpc, "Remove inactive accounts")
