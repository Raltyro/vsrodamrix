function create()
	game.sound.music:reset(true)
	if state.vocals then state.vocals:stop() end
	if state.dadVocals then state.dadVocals:stop() end

	state.currentTransition = Transition(State.defaultTransOut, "out", state, function()
		state.currentTransition = Transition(State.defaultTransIn, "in", state)

		state.camNotes.visible = false
		state.camHUD.visible = false
		game.camera.visible = false

		local video = SkippableVideo(paths.getVideo('Cutscene2'), true, function()
			state:endSong(true)
		end):fitToScreen()
		video.cameras = {state.camOther}
		state:add(video)

		video:play()
	end)
end