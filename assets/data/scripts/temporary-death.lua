local ok, time
function gameOverCreate()
	ok, time = false, 0
	if state.boyfriend.char ~= "bf" and GameOverSubstate.characterName == "bf-dead" then
		game.camera.visible = false
		GameOverSubstate.characterName = state.boyfriend.char
		ok = true
	end
end

function gameOverUpdate(dt)
	if ok and not state.substate.isEnding then
		time = time + dt
		if time > 2.5 then
			ok = false
			state.substate.boyfriend.curAnim, state.substate.boyfriend.animFinished = {name = "firstDeath"}, true
		end
	end
end