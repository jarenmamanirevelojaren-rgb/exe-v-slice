import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.play.PlayState;
import funkin.play.event.ScriptedSongEvent;
import funkin.Paths;
import funkin.graphics.FunkinSprite;
import funkin.modding.module.Module;
import funkin.modding.module.ModuleHandler;

/*
  Remade using patterns from scripts/events/fatalZoneNew.hxc
  - Uses EXEOptions toggle for popups
  - HUD-bound cursor that replaces system mouse while active
  - Popups array with timed removal and bye animation
  - Safe zIndex ordering + stage refresh
*/

class FatalPopupEvent extends ScriptedSongEvent {
  public function new() {
    super('Fatality Popup'); // keep the same eventKind used in charts
  }

  public override function handleEvent(data) {
    var position:String = 'random';
    var timeout:Float = 0.0;
    if (data != null && data.value != null) {
      if (data.value.position != null) position = data.value.position;
      if (data.value.timeout != null) timeout = data.value.timeout;
    }

    var mod = ModuleHandler.getModule("FatalPopupHandler");
    if (mod != null) {
      // Follow common pattern used by other events (e.g., NoteSwapEvent)
      mod.scriptCall('createPopup', [position, timeout]);
      return;
    }

    // Fallback if the module isn't registered
    var h:FatalPopupHandler = new FatalPopupHandler();
    h.onCreate();
    h.createPopup(position, timeout);
  }

  public override function getEventSchema() {
    return [
      {
        name: "position",
        title: "Popup Position",
        type: "enum",
        defaultValue: "random",
        keys: [
          "Random" => "random",
          "Center" => "center",
          "Top Left" => "topleft",
          "Top Right" => "topright",
          "Bottom Left" => "bottomleft",
          "Bottom Right" => "bottomright"
        ]
      },
      {
        name: "timeout",
        title: "Auto-dismiss (seconds)",
        type: "float",
        defaultValue: 0.0,
        min: 0.0,
        max: 10.0
      }
    ];
  }

  public override function getTitle() {
    return "Add Fatal Popup";
  }
}

class FatalPopupHandler extends Module {
  var fatalCursor:FlxSprite;
  var popups:Array<FlxSprite> = [];
  var doFatalPopups:Bool = true;

  public function new() {
    super("FatalPopupHandler");
  }

  override function onCreate():Void {
    try {
      var opts = ModuleHandler.getModule("EXEOptions");
      if (opts != null) doFatalPopups = cast opts.scriptGet("fatalpopups");
    } catch (e:Dynamic) {}

    FunkinSprite.cacheTexture(Paths.image('error_popups'));
    FunkinSprite.cacheTexture(Paths.image('fatal_mouse_cursor'));
  }

  function ensureCursor():Void {
    if (PlayState.instance == null || !doFatalPopups) return;
    if (fatalCursor != null && fatalCursor.exists) return;

    if (fatalCursor == null) fatalCursor = new FlxSprite();
    fatalCursor.loadGraphic(Paths.image('fatal_mouse_cursor'));
    fatalCursor.scrollFactor.set(0, 0);
    fatalCursor.setGraphicSize(Std.int(fatalCursor.width * 1.5), Std.int(fatalCursor.height * 1.5));
    fatalCursor.updateHitbox();
    fatalCursor.antialiasing = false;
    fatalCursor.zIndex = 9999;
    fatalCursor.cameras = [PlayState.instance.camHUD];
    fatalCursor.visible = true;

    if (!fatalCursor.exists) PlayState.instance.add(fatalCursor);
    FlxG.mouse.visible = false;

    if (PlayState.instance.currentStage != null) PlayState.instance.currentStage.refresh();
  }

  public function createPopup(position:String = 'random', timeout:Float = 0.0):Void {
    if (PlayState.instance == null || !doFatalPopups) return;

    ensureCursor();

    // Determine spawn position
    var posX:Float = 0;
    var posY:Float = 0;
    switch(position) {
      case 'random':
        posX = FlxG.random.float(0, FlxG.width - 400);
        posY = FlxG.random.float(0, FlxG.height - 300);
      case 'center':
        posX = (FlxG.width - 300) / 2;
        posY = (FlxG.height - 300) / 2;
      case 'topleft':
        posX = 50; posY = 50;
      case 'topright':
        posX = FlxG.width - 350; posY = 50;
      case 'bottomleft':
        posX = 50; posY = FlxG.height - 350;
      case 'bottomright':
        posX = FlxG.width - 350; posY = FlxG.height - 350;
      default:
        posX = FlxG.random.float(0, FlxG.width - 400);
        posY = FlxG.random.float(0, FlxG.height - 300);
    }

    var popup = FunkinSprite.create(posX, posY);
    popup.frames = Paths.getSparrowAtlas('error_popups');
    if (popup.frames != null) {
      popup.animation.addByPrefix('popup_anim', 'idle', 24, false);
      popup.animation.addByPrefix('bye', 'bye', 24, false);
      popup.animation.play('popup_anim');
    }
    popup.scrollFactor.set(0, 0);
    popup.cameras = [PlayState.instance.camHUD];
    popup.scale.set(1.6, 1.6);
    popup.zIndex = 8000;
    popup.updateHitbox();
    popup.antialiasing = false;

    // Add above HUD elements consistently
    PlayState.instance.add(popup);
    popups.push(popup);

    // Ensure z-order is applied
    if (PlayState.instance.currentStage != null) PlayState.instance.currentStage.refresh();

    if (timeout > 0) {
      var t = new FlxTimer();
      t.start(timeout, function(_:FlxTimer):Void {
        removePopup(popup);
      });
    }
  }

  function removePopup(popup:FlxSprite):Void {
    if (popup == null) return;
    if (popup.animation != null) {
      popup.animation.play('bye');
      popup.animation.finishCallback = function() {
        if (PlayState.instance != null) PlayState.instance.remove(popup);
        popups.remove(popup);
        popup.destroy();
      };
    } else {
      if (PlayState.instance != null) PlayState.instance.remove(popup);
      popups.remove(popup);
      popup.destroy();
    }
  }

  function clearPopups():Void {
    for (p in popups) {
      if (PlayState.instance != null) PlayState.instance.remove(p);
      p.destroy();
    }
    popups = [];
  }

  function clearPopupsQuickly():Void {
    var delay:Float = 0;
    for (p in popups) {
      if (p != null) {
        var tm = new FlxTimer();
        tm.start(delay, function(_:FlxTimer):Void {
          removePopup(p);
        });
        delay += 0.07; // staggered removal like fatalZoneNew
      }
    }
  }

  override function update(elapsed:Float) {
    if (PlayState.instance == null || !doFatalPopups) return;

    // Ensure cursor exists and follows HUD mouse
    ensureCursor();

    if (fatalCursor != null) {
      var mousePos = FlxG.mouse.getWorldPosition(PlayState.instance.camHUD);
      if (mousePos != null) {
        fatalCursor.x = mousePos.x - (fatalCursor.width / 2);
        fatalCursor.y = mousePos.y - (fatalCursor.height / 2);
      }

      // Small pulse, referenced from fatalZoneNew
      fatalCursor.scale.set(
        1 + 0.05 * Math.sin(FlxG.game.ticks / 10),
        1 + 0.05 * Math.sin(FlxG.game.ticks / 10)
      );
    }

    if (FlxG.mouse.justPressed) {
      var mousePos = FlxG.mouse.getWorldPosition(PlayState.instance.camHUD);

      for (i in 0...popups.length) {
        var idx = popups.length - 1 - i;
        var p = popups[idx];
        if (p != null && p.overlapsPoint(mousePos, true)) {
          removePopup(p);
          break;
        }
      }
    }

    for (p in popups) {
      if (p != null && p.animation != null && p.animation.curAnim != null && p.animation.curAnim.name == 'bye' && p.animation.curAnim.finished) {
        if (PlayState.instance != null) PlayState.instance.remove(p);
        popups.remove(p);
        p.destroy();
      }
    }
  }
}