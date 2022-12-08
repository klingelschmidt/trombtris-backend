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

	local week = nk.time() - 604800000
	
	local users = nk.users_get_random(100)
	local query = string.format([[
		SELECT user_id
		FROM users
		WHERE display_name = NULL
		ORDER BY create_time DESC
	]])

	local parameters = {}

	local rows = nk.sql_query(query, parameters)
	local removeUsers = {}

	for i, row in ipairs(rows) do
		nk.logger_info(string.format("Username %q with ID %q", row.username, row.user_id))
		removeUsers.insert(removeUsers, row.user_id)
	end


	local message = nk.json_encode(removeUsers)

    return message
end

nk.register_matchmaker_matched(function(context, matched_users)
    local match_id = nk.match_create("matchHandler")
    return match_id
end)

nk.register_rpc(leaderboard_rpc, "Create leaderboard")
nk.register_rpc(purge_rpc, "Remove inactive accounts")
