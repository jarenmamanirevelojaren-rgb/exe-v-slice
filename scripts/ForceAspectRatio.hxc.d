import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxTimer;
import funkin.ui.mainmenu.MainMenuState;
import funkin.play.PlayState;
import funkin.Paths;
import funkin.util.ReflectUtil;
import funkin.util.Constants;
import funkin.Preferences;
import funkin.modding.module.Module;
import funkin.modding.events.ScriptEvent;

class ForceAspectRatio extends Module
{
  private static final targetAspectRatio:Float = 19.01 / 9.0; // Modify the ratio as needed, like 16.0 and 9.0 for 16:9, etc
  
  public function new()
  {
    super('ForceMobileAspect');
  }
  
  public override function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);
    
    forceAspectRatio();

    Preferences.autoFullscreen = false;
  }
  
  private function forceAspectRatio():Void
  {
    var currentWidth:Int = FlxG.stage.stageWidth;
    var currentHeight:Int = FlxG.stage.stageHeight;
    var currentAspectRatio:Float = currentWidth / currentHeight;
    
    if (Math.abs(currentAspectRatio - targetAspectRatio) > 0.01)
    {
      var newWidth:Int;
      var newHeight:Int;
      
      if (currentAspectRatio > targetAspectRatio)
      {
        newWidth = Math.round(currentHeight * targetAspectRatio);
        newHeight = currentHeight;
      }
      else
      {
        newWidth = currentWidth;
        newHeight = Math.round(currentWidth / targetAspectRatio);
      }
      
      FlxG.resizeWindow(newWidth, newHeight);
      
      FlxG.stage.window.x = Math.round((FlxG.stage.window.display.bounds.width - newWidth) / 2);
      FlxG.stage.window.y = Math.round((FlxG.stage.window.display.bounds.height - newHeight) / 2);
    }
  }
}