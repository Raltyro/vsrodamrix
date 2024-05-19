function create()
	function state.generateNote(state, n, s)
		if s.gfSection then n[4], n[2] = "GF Sing", n[2] % 4 end
		PlayState.generateNote(state, n, s)
	end
end

function postCreate()
	local n, gf = state.enemyNotefield, state.gf
	local midx, midy = gf:getGraphicMidpoint()
	local gfn = Notefield(midx, midy, n.keys, n.skin.skin, gf, n.vocals)
	gfn.vocalVolume, gfn.speed, gfn.canSpawnSplash, gfn.bot = n.vocalVolume, n.speed, false, true
	gfn.alpha = .3

	for i = #n.notes, 1, -1 do
		local note = n.notes[i]
		if note and note.type == "GF Sing" then
			n:removeNotefromIndex(i)
			gfn:addNote(note)
		end
	end
	table.sort(gfn.notes, Conductor.sortByTime)

	state.gfNotefield = gfn
	table.insert(state.notefields, gfn)
	state:add(gfn)

	state.healthBar.iconP2:changeIcon('purplepink')
	close()
end