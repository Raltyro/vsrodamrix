package states.stages;

class DoubleAttackStage extends BaseStage
{
	override function create()
	{
		var bg:BGSprite = new BGSprite('double-attack-bg', -293, -361, 0.97, 0.97);
		add(bg);
	}

	override function createPost()
	{
		gf.scrollFactor.set(0.98, 0.98);
	}
}