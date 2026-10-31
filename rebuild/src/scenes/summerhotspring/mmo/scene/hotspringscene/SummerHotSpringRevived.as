package mmo.scene.hotspringscene
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneBase;
   import mmo.revival.RNotice;

   /**
    * LATER scene/summerhotspring (欢乐岛): the January 2013 scene is lost;
    * the live one (2020) needs the hot-spring services and effects of later
    * years (HotSpringSeason, BitmapMovieCacher, scene commands) and could not
    * be built at all. This is its code cut down to the 2013 engine, on its
    * own art: the island to walk on, reached by the map as before (it has no
    * doors). Its 更衣室 and 增效道具 (the hot-spring service, a later copy)
    * say they are not rebuilt yet; flying stays allowed.
    */
   public class SummerHotSpringRevived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      public function SummerHotSpringRevived()
      {
         super(750, 390);
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         notYet(backGround.getChildByName("btnChangeClothes"), "更衣室");
         notYet(background ? background.getChildByName("btnSale") : null, "增效道具");
      }

      private static function notYet(d:*, tip:String):void
      {
         var io:InteractiveObject = d as InteractiveObject;
         if (io == null) return;
         TipsManager.getInstance().addTips(io, tip);
         io.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            RNotice.show(LayerManager.getBaseTop(), tip + "还在修复中哦！");
         });
      }
   }
}
