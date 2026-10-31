package mmo.play.scene
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * REBUILT stand-in for the lost January 2013 战斗星域 (scene
    * spacetimechallenge, 银河冠军擂台): game/ only has its 2025 rework, of
    * another look and with other doors, which the 2013 engine cannot run.
    * Going there (the map's 战斗星域, the 星战空间 doors of 试炼平台 and 挑战平台)
    * offers the rooms of the area in the January 2013 config.xml instead:
    * 试炼平台, 挑战平台, 亚比精英赛场, 时空隧道 and 堡垒外沿, the way to
    * 黑星堡垒 (模拟空间, fightlab, is entered through the lost virtualfight
    * panels, which set its floor first, so it is left out).
    */
   public class BattleZoneHub extends Sprite
   {
      public static const SCENE:String = "spacetimechallenge";
      private static const ROOMS:Array = [
         ["spacetimechallenge2", "试炼平台"], ["spacetimechallenge3", "挑战平台"], ["outstandingyabiarena", "亚比精英赛场"],
         ["spacetime", "时空隧道"], ["arenaexterior", "堡垒外沿"]
      ];
      private static var current:BattleZoneHub;

      public static function show():void
      {
         if (current != null && current.parent != null) current.parent.removeChild(current);
         current = new BattleZoneHub();
         LayerManager.getBaseTop().addChild(current);
      }

      public function BattleZoneHub()
      {
         super();
         name = "battleZoneHub";
         var W:int = 420;
         var H:int = 150 + Math.ceil(ROOMS.length / 2) * 46;
         addChild(RUI.dim(close));
         var box:Sprite = RUI.panel(W, H, "战斗星域", close, "battleZoneClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 20;
         addChild(box);
         var said:TextField = RUI.text(13, RUI.BLUE, false, W - 40);
         said.x = 20;
         said.y = 56;
         said.text = "欢迎来到战斗星域！要去哪里呢？";
         box.addChild(said);
         for (var i:int = 0; i < ROOMS.length; i++)
         {
            var b:Sprite = RUI.button(ROOMS[i][1], go(ROOMS[i][0]), 180, 34, 0x9FD8FF, 0x3A8FD8, "battleZone_" + ROOMS[i][0]);
            b.x = 20 + (i % 2) * 200;
            b.y = 92 + int(i / 2) * 46;
            box.addChild(b);
         }
      }

      private function go(scene:String):Function
      {
         return function():void
         {
            close();
            SceneManager.getInstance().loadScene(scene, "default");
         };
      }

      private function close():void
      {
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
