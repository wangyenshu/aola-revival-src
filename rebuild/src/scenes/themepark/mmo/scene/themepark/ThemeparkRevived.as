package mmo.scene.themepark
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.play.scene.SceneBase;

   /**
    * REBUILT 主题公园 (room "themepark") on the 2012 主题公园's art. The January
    * 2013 scene is lost and the live file is a 2024 redrawing. The 2012 one
    * survives as scene/memory/memory2 (re-uploaded in 2024 among the "memories"
    * of the park): the round stage with the sun, the rainbow, the whale of the
    * 奇妙零食屋 and the balloons, as at 儿童节 2012 (its banner is part of the
    * picture; the 2012 guides of 100bt show the same stage and whale). Its own
    * walkable area is kept. The ways out are RECONSTRUCTED: 奥拉之树 (whose
    * 2013 scene takes "fromthemepark") and 星光游乐场. The bosses and NPCs come
    * from their services as before.
    */
   public class ThemeparkRevived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      /** [tip, scene, location key, x, y, width, height]. */
      private static const WAYS:Array = [
         ["奥拉之树", "aolatree", "fromthemepark", 0, 300, 70, 190],
         ["星光游乐场", "amusementpark", "default", 900, 260, 90, 200]
      ];

      public function ThemeparkRevived()
      {
         super(630, 350);
         addInitLocation("fromaolatree", new Point(200, 470));
         addInitLocation("fromamusementpark", new Point(800, 420));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         for each (var w:Array in WAYS)
         {
            var s:Sprite = new Sprite();
            s.graphics.beginFill(0xFFFFFF, 1);
            s.graphics.drawRect(0, 0, w[5], w[6]);
            s.graphics.endFill();
            s.x = w[3];
            s.y = w[4];
            s.name = "way_" + w[1];
            (background || this).addChild(s);
            addEntrances(s, w[1], w[2]);
            TipsManager.getInstance().addTips(s, w[0]);
         }
      }
   }
}
