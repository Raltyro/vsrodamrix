function postStartCountdown()
	state.doCountdownAtBeats = 60
	state.conductor.time = -0.2

	state.countdown.data = {
		{sound = "gameplay/intro3roda",  image = nil},
		{sound = "gameplay/intro2roda",  image = "skins/default/ready"},
		{sound = "gameplay/intro1roda",  image = "skins/default/set"},
		{sound = "gameplay/introGoroda", image = "skins/default/go"}
	}
	close()
end