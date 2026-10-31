package mmo.scene.feier
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gather.IGatherService;
   import mmo.play.scene.SceneBase;

   /**
    * LATER scene/feier4 (火山口, where 烈焰鸟 the 守护者 sleeps): the January
    * 2013 scene is lost and the live one (2026) asks for a later date helper
    * and the gathering spots of a 2026 activity, and stopped as it was
    * entered. Its code cut down to the 2013 engine, on its own art: the way
    * back to 火山山口 (feier3) and the 闪光石 to gather (material 93). The file
    * places its obstruction twice; the second is hidden here.
    */
   public class Feier4Revived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      public function Feier4Revived()
      {
         super(500, 500);
         addInitLocation("feier3tofeier4", new Point(780, 350));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         // The later file places its obstruction (and background) twice; the second
         // obstruction lay drawn over the scene.
         var seen:Object = {};
         for (var k:int = 0; k < numChildren; k++)
         {
            var layer:DisplayObject = getChildAt(k);
            if (layer.name == "obstruction")
            {
               layer.alpha = 0;
               if (layer is InteractiveObject) InteractiveObject(layer).mouseEnabled = false;
            }
            // A second copy of a layer (the same picture again) would lie over the players.
            if ((layer.name == "background" || layer.name == "obstruction") && seen[layer.name] && layer != getChildByName(layer.name)) layer.visible = false;
            seen[layer.name] = true;
         }
         var et1:DisplayObject = foreground.getChildByName("et1");
         if (et1 != null)
         {
            TipsManager.getInstance().addTips(et1 as InteractiveObject, "火山山口");
            addEntrances(et1, "feier3", "feier4tofeier3");
         }
         try
         {
            var stone:MovieClip = container.getChildByName("flashStone") as MovieClip;
            var g:IGatherService = ServiceContainer.getService(IGatherService) as IGatherService;
            if (stone != null && g != null) g.registerGatherMaterial(93, stone);
         }
         catch (e:Error) {}
         // The 2026 activity's gathering spots stay hidden.
         for (var i:int = 0; i < 3; i++)
         {
            var act:DisplayObject = container.getChildByName("mcActGather" + i);
            if (act != null) act.visible = false;
         }
      }
   }
}
