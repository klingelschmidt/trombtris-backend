local nk = require("nakama")

local M = {}

function M.match_join(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = presence
	end

	if #state.presences >= 2 then
		state.started = true
		dispatcher.broadcast_message(101, nk.json_encode(state.seed), nil, nil)
		nk.logger_info("Match was started")
	end

	return state
end


function M.match_init(context, initial_state)
	local state = {
		presences = {},
		empty_ticks = 0,
		started = false,
		seed = nk.time(),
	}
	nk.logger_info("Match was intitialized")
	local tick_rate = 1 -- 1 tick per second = 1 MatchLoop func invocations per second
	local label = ""

	return state, tick_rate, label
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end

	return state
end

function match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	if state.presences >= 2 then
		return state, false, "Match is full"
	end
	return state, true
end

-- 101 game start
-- 102 game over for someone
-- 103 boardstate

function M.match_loop(context, dispatcher, tick, state, messages)
	-- Get the count of presences in the match
	local totalPresences = 0
	for k, v in pairs(state.presences) do
	  totalPresences = totalPresences + 1
	end

	-- If we have no presences in the match according to the match state, increment the empty ticks count
	if totalPresences == 0 then
		state.empty_ticks = state.empty_ticks + 1
	end

	-- If the match has been empty for more than 100 ticks, end the match by returning nil
	if state.empty_ticks > 100 then
		return nil
	end

	for m in messages do
		local json = nk.json_decode(m)
		if json.opcode == 102 then
			return nil --Game over
		end
		local opponents
		for _,p in pairs(state.presences) do
			if p.session_id == json.sender.session_id then
				break
			end
			table.insert(opponents, p)
		end
		dispatcher.broadcast_message(103, m.data, opponents, nil)
	end

	return state
end

return M
