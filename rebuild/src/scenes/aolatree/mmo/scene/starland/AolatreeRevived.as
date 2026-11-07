package mmo.scene.starland
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.play.scene.SceneBase;

   /**
    * REBUILT 奥拉之树 (room "aolatree"). The January 2013 scene is lost: the
    * live scene/aolatree is a 2025 redrawing (a realistic tree among towers,
    * with the activities of 2025). The oldest art that survives is the copy
    * of the stylized tree in scene/aolatreefb (2021): the purple tree with the
    * 奥拉 mark on its trunk, its round platform, the rainbow stairs and the
    * robots on their pillars, as the 100bt guides of 2014–15 show the scene
    * (without the 大电影 and 奖励兑换 stands of those years, which were not
    * in the scene's art). Its walkable area is kept.
    *
    * The ways out are those of 2013, on the copy's three hotspots, as the
    * later scene's arrival points still place them: the road on the left to
    * 奥拉广场 ("fromstarland"), the rainbow stairs to 主题公园
    * ("fromthemepark"), the road on the right to 十字大道 ("fromcrossroad"),
    * named by their tips (the copy's arrows are blank).
    * The 2012 map's 奥拉星历史漫画 is the copy's threeHerosBtn (the comic of
    * the three heroes, taskres/threeHeros of March 2012; ScenePatches shows
    * it), its 星愿气球 balloons drawn anew. 萨鲁奇, the task NPCs and the
    * bosses come from their services.
    */
   public class AolatreeRevived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      /** [hotspot, tip, scene, location key, face]. */
      private static const WAYS:Array = [
         ["et1", "奥拉广场", "starland", "fromaolatree", "lu"],
         ["et2", "主题公园", "themepark", "fromaolatree", "ld"],
         ["et3", "十字大道", "crossroad", "fromaolatree", "ru"]
      ];

      public function AolatreeRevived()
      {
         super(480, 470);
         addInitLocation("fromstarland", new Point(300, 330));
         addInitLocation("fromthemepark", new Point(255, 430));
         addInitLocation("fromcrossroad", new Point(730, 335));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         for each (var w:Array in WAYS)
         {
            var et:DisplayObject = foreground != null ? foreground.getChildByName(w[0]) : null;
            addEntrances(et, w[2], w[3], null, w[4]);
            if (et is InteractiveObject) TipsManager.getInstance().addTips(InteractiveObject(et), w[1]);
         }
         var comic:InteractiveObject = find(this, "threeHerosBtn") as InteractiveObject;
         if (comic != null) TipsManager.getInstance().addTips(comic, "奥拉星历史漫画");
         var wish:Sprite = balloons();
         (background || this).addChild(wish);
         TipsManager.getInstance().addTips(wish, "星愿气球");
      }

      /**
       * 星愿气球 (the 2012 map's function of the place; its picture in the 2013
       * scene is lost): three balloons tied to a post by the tree, drawn anew
       * (RECONSTRUCTED). ScenePatches opens the BallWishService's wish panel on
       * a click of btnBallWish.
       */
      private static function balloons():Sprite
      {
         var b:Sprite = new Sprite();
         b.name = "btnBallWish";
         b.buttonMode = true;
         b.useHandCursor = true;
         b.mouseChildren = false;
         var g:flash.display.Graphics = b.graphics;
         // the whole of it answers a click, strings included
         g.beginFill(0xFFFFFF, 0);
         g.drawRect(-36, -132, 72, 146);
         g.endFill();
         var tops:Array = [[-20, -96, 0xFF7FB6, 0xFFD3E6], [2, -112, 0xFFD23F, 0xFFF3B8], [22, -92, 0x5FB8F5, 0xD3EEFF]];
         g.lineStyle(1, 0x8A6A9E, 0.8);
         for each (var t:Array in tops)
         {
            g.moveTo(0, -30);
            g.curveTo((t[0] as Number) * 0.4, -50, t[0], (t[1] as Number) + 20);
         }
         for each (t in tops)
         {
            g.lineStyle(2, 0x6B4C8A, 0.9);
            g.beginFill(t[2]);
            g.drawEllipse((t[0] as Number) - 14, (t[1] as Number) - 18, 28, 36);
            g.endFill();
            g.lineStyle(0, 0, 0);
            g.beginFill(t[3], 0.9);
            g.drawEllipse((t[0] as Number) - 8, (t[1] as Number) - 12, 7, 11);
            g.endFill();
            g.beginFill(t[2]);
            g.moveTo((t[0] as Number) - 3, (t[1] as Number) + 21);
            g.lineTo((t[0] as Number) + 3, (t[1] as Number) + 21);
            g.lineTo(t[0], (t[1] as Number) + 17);
            g.endFill();
            star(g, (t[0] as Number) + 2, (t[1] as Number) + 2, 5, 0xFFFFFF);
         }
         // the post
         g.lineStyle(2, 0x2E86C8);
         g.beginFill(0x8ED0FA);
         g.drawRect(-3, -30, 6, 34);
         g.endFill();
         b.x = 668;
         b.y = 268;
         return b;
      }

      private static function star(g:flash.display.Graphics, cx:Number, cy:Number, r:Number, c:uint):void
      {
         g.beginFill(c, 0.95);
         for (var i:int = 0; i <= 10; i++)
         {
            var a:Number = -Math.PI / 2 + i * Math.PI / 5;
            var rr:Number = i % 2 == 0 ? r : r * 0.45;
            if (i == 0) g.moveTo(cx + rr * Math.cos(a), cy + rr * Math.sin(a));
            else g.lineTo(cx + rr * Math.cos(a), cy + rr * Math.sin(a));
         }
         g.endFill();
      }

      private static function find(d:DisplayObject, name:String):DisplayObject
      {
         if (d == null) return null;
         if (d.name == name) return d;
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         for (var i:int = 0; c != null && i < c.numChildren; i++)
         {
            var f:DisplayObject = find(c.getChildAt(i), name);
            if (f != null) return f;
         }
         return null;
      }
   }
}
