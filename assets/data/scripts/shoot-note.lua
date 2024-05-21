function postCreate()
	local yeah
	for _, notefield in pairs(state.notefields) do
		for _, note in ipairs(notefield.notes) do
			if note.type == "Shoot Note" then
				yeah = true
				note.priority = 1

				note:play("shoot")
				note.angle = 0

				if note.shader then
					note.shader = nil
				end
			end
		end
	end

	if not yeah then close() end
end

local function susAnim()
	state.dad:playAnim("attack", true)
	state.dad.lastHit = state.conductor.time

	util.playSfx(paths.getSound('gameplay/gunfire'), .8)
end

function onNoteHit(e)
	if e.notefield == state.playerNotefield and e.note.type == "Shoot Note" then
		susAnim()

		e.cancelledAnim = true
		e.notefield.character:playAnim("dodge", true)
		e.notefield.character.lastHit = state.conductor.time
	--[[else
		local char = e.notefield.character
		if char and char.curAnim and char.curAnim.name == "attack" and not char.animFinished then
			e.cancelledAnim = true
		end]]
	end
end

local die
function onMiss(e)
	if e.notefield == state.playerNotefield and e.note and e.note.type == "Shoot Note" then
		susAnim()
		state.health = state.health - 0.3
		if state.health <= 0 then die, state.health = true, state.health + 0.25 end
		util.playSfx(paths.getSound('gameplay/damagesfx'), .9)
	end
end

function update()
	if die then state.health, die = -1 end
end