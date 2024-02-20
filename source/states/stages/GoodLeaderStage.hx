package states.stages;

class GoodLeaderStage extends BaseStage
{
	override function create()
	{
		var bg:BGSprite = new BGSprite('good-leader-bg', -163, -103, 0.7, 0.7);
		add(bg);
	}

	override function createPost()
	{
		var table:BGSprite = new BGSprite('good-leader-table', -202, 547, 1.08, 1.08);
		add(table);

		remove(gf);
		add(gf);
		gf.scrollFactor.set(1.08, 1.08);

		var viewbarrier:BGSprite = new BGSprite('good-leader-line', 552, -34, ["viewbarrier instance 1"], true);
		add(viewbarrier);
	}
}