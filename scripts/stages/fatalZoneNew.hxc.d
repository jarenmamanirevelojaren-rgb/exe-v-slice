import flixel.FlxG;
import flixel.math.FlxBasePoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import funkin.graphics.FunkinSprite;
import funkin.Paths;
import funkin.play.PlayState;
import funkin.play.stage.Stage;
import funkin.play.song.Song;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import funkin.modding.module.ModuleHandler;

class FatalZone extends Stage
{
	var statix:FunkinSprite;
	var leftBorder:FlxSprite;
	var rightBorder:FlxSprite;
	var fatalCursor:FlxSprite;

	var popups:Array<FlxSprite>;
	var popupsBeingDestroyed:Array<FlxSprite>;
	public var popupTimer:FlxTimer;
	public var popup = FunkinSprite.create(FlxG.random.float(0, FlxG.width - 300), FlxG.random.float(0, FlxG.height - 300));
	
	var originalPlayerStrumlineX:Float;
	var originalOpponentStrumlineX:Float;
	var originalOpponentStrumlineVisible:Bool = true;
	
	var doFatalPopups:Bool = false;
	var screenRatioEdit:Bool = false;
	var modChartsEnabled:Bool = false;
	var game:PlayState;

	public function new()
	{
		super("fatalZone");
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
		
		screenRatioEdit = ModuleHandler.getModule("EXEOptions").scriptGet("screenratio");
		modChartsEnabled = ModuleHandler.getModule("EXEOptions").scriptGet("modcharts");
		doFatalPopups = ModuleHandler.getModule("EXEOptions").scriptGet("fatalpopups");

		FunkinSprite.cacheTexture(Paths.image('fatal/domain'));
		FunkinSprite.cacheTexture(Paths.image('fatal/domain2'));
		FunkinSprite.cacheTexture(Paths.image('fatal/truefatalstage'));
		FunkinSprite.cacheTexture(Paths.image('error_popups'));

		statix = FunkinSprite.create(0, 0);
		statix.frames = Paths.getSparrowAtlas('statix');
		statix.animation.addByPrefix('static', 'statixx', 44, false);
		statix.animation.play('static');
		statix.scale.set(5.5, 5.5);
		statix.cameras = [PlayState.instance.camHUD];
		PlayState.instance.add(statix);
		statix.visible = false;
		statix.animation.finishCallback = function() {
			if (statix != null) {
				statix.visible = false;
			}
		};

		if (screenRatioEdit) {
			leftBorder = new FlxSprite(0, 0).makeGraphic(50, FlxG.height, 0xFF000000);
			leftBorder.scrollFactor.set(0, 0);
			leftBorder.scale.set(5, 3);
			leftBorder.cameras = [PlayState.instance.camHUD];
			PlayState.instance.add(leftBorder);

			rightBorder = new FlxSprite(FlxG.width - 50, 0).makeGraphic(50, FlxG.height, 0xFF000000);
			rightBorder.scrollFactor.set(0, 0);
			rightBorder.scale.set(5, 3);
			rightBorder.cameras = [PlayState.instance.camHUD];
			PlayState.instance.add(rightBorder);
		}
	}

	function onCountdownStart()
	{
		if (PlayState.instance.opponentStrumline != null && PlayState.instance.playerStrumline != null) {
			originalPlayerStrumlineX = PlayState.instance.playerStrumline.x;
			originalOpponentStrumlineX = PlayState.instance.opponentStrumline.x;
			originalOpponentStrumlineVisible = PlayState.instance.opponentStrumline.visible;
			
			if (screenRatioEdit && !FlxG.onMobile) {
				PlayState.instance.opponentStrumline.x = 150;
				PlayState.instance.playerStrumline.x = 692;
			}
		}
	}

	override function buildStage()
	{
		super.buildStage();
	}

	function onStepHit(event:SongTimeScriptEvent):Void
	{
		var phase2 = getNamedProp('fatalityBg2');
		var phase2bg = getNamedProp('fatalityBg3');
		var phase3bg = getNamedProp('fatalityBg4');

		if (!PlayState.instance.currentSong.id.toLowerCase() == 'fatality') return;

		if (event.step == 257)
		{
			statix.visible = true;
			statix.animation.play('static');

			if (statix != null) {
				var timer = new FlxTimer();
				timer.start(0.12, function(timer:FlxTimer):Void {
					statix.visible = false;
				});
			}
			
			phase2bg.zIndex = 11;
			phase2.zIndex = 12;
			PlayState.instance.currentStage.refresh();

		}

		if (event.step == 1984)
		{
			statix.visible = true;
			statix.animation.play('static');

			if (statix != null) {
				var timer2 = new FlxTimer();
				timer2.start(0.12, function(timer:FlxTimer):Void {
					statix.visible = false;
				});
			}

			if (modChartsEnabled && !FlxG.onMobile) {
			    PlayState.instance.playerStrumline.x = FlxG.width / 2 - PlayState.instance.playerStrumline.width / 2;
			    PlayState.instance.opponentStrumline.visible = false;
			}
			
			phase3bg.zIndex = 20;
			PlayState.instance.currentStage.refresh(); // Apply Z-Index.

		}
	}

	override function onSongRetry(event:ScriptEvent):Void {
		super.onSongRetry(event);

		if (PlayState.instance != null && PlayState.instance.opponentStrumline != null && PlayState.instance.playerStrumline != null) {
			PlayState.instance.playerStrumline.x = originalPlayerStrumlineX;
			PlayState.instance.opponentStrumline.x = originalOpponentStrumlineX;
			PlayState.instance.opponentStrumline.visible = originalOpponentStrumlineVisible;
		}
		
		if (statix != null) {
			statix.visible = false;
		}
		var phase1 = getNamedProp('fatalityBg1');
		var phase2 = getNamedProp('fatalityBg2');
		var phase2bg = getNamedProp('fatalityBg3');
		var phase3bg = getNamedProp('fatalityBg4');

		if (phase1 != null) {
			phase1.zIndex = 10;
		}
		if (phase2 != null) {
			phase2.zIndex = 9;
		}
		if (phase2bg != null) {
			phase2bg.zIndex = 8;
		}
		if (phase3bg != null) {
			phase3bg.zIndex = 7;
		}
		PlayState.instance.currentStage.refresh();
	}
}
