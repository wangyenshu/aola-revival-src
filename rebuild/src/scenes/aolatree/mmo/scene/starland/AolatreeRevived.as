package mmo.scene.starland
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFormat;
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
    * ("fromthemepark"), the road on the right to 十字大道 ("fromcrossroad").
    * The signs of the roads are drawn again (the copy's arrows are blank).
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

      /** [text, x, y, points left]. */
      private static const SIGNS:Array = [
         ["奥拉\n广场", 112, 168, true],
         ["主题\n公园", 150, 400, true],
         ["十字\n大道", 806, 168, false]
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
         for each (var s:Array in SIGNS) (background || this).addChild(sign(s[0], s[1], s[2], s[3]));
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
         // the post and its little board
         g.lineStyle(2, 0x2E86C8);
         g.beginFill(0x8ED0FA);
         g.drawRect(-3, -30, 6, 34);
         g.endFill();
         g.beginFill(0xFFFFFF);
         g.drawRoundRect(-30, -8, 60, 20, 8, 8);
         g.endFill();
         var t2:TextField = new TextField();
         t2.defaultTextFormat = new TextFormat("SimHei", 12, 0xD9408C, true, null, null, null, null, "center");
         t2.selectable = false;
         t2.mouseEnabled = false;
         t2.width = 60;
         t2.height = 18;
         t2.x = -30;
         t2.y = -7;
         t2.text = "星愿气球";
         b.addChild(t2);
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

      /** A road sign as those of the 2014 scene: a white board pointing the way, blue lettering. */
      private static function sign(text:String, x:Number, y:Number, left:Boolean):Sprite
      {
         var w:int = 58, h:int = 44, tip:int = 12;
         var s:Sprite = new Sprite();
         s.mouseEnabled = false;
         s.mouseChildren = false;
         s.graphics.lineStyle(3, 0x36B4E6);
         s.graphics.beginFill(0xFFFFFF);
         if (left)
         {
            s.graphics.moveTo(0, h / 2);
            s.graphics.lineTo(tip, 0);
            s.graphics.lineTo(w, 0);
            s.graphics.lineTo(w, h);
            s.graphics.lineTo(tip, h);
         }
         else
         {
            s.graphics.moveTo(0, 0);
            s.graphics.lineTo(w - tip, 0);
            s.graphics.lineTo(w, h / 2);
            s.graphics.lineTo(w - tip, h);
            s.graphics.lineTo(0, h);
         }
         s.graphics.lineTo(left ? 0 : 0, left ? h / 2 : 0);
         s.graphics.endFill();
         // the post
         s.graphics.lineStyle(0, 0, 0);
         s.graphics.beginFill(0x36B4E6);
         s.graphics.drawRect(w / 2 - 3 + (left ? tip / 2 : -tip / 2), h, 6, 14);
         s.graphics.endFill();
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimHei", 13, 0x1B6DB3, true, null, null, null, null, "center", null, null, null, -1);
         t.selectable = false;
         t.mouseEnabled = false;
         t.width = w - tip;
         t.height = h;
         t.x = left ? tip : 0;
         t.y = 4;
         t.text = text;
         s.addChild(t);
         s.x = x;
         s.y = y;
         s.name = "sign_" + text.replace("\n", "");
         return s;
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
