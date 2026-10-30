package mmo.play.bigscene
{
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.revival;

   /**
    * REBUILT. Base of the scrolling ("big") scenes: bigscene/happyark,
    * bigscene/starlandcopy and others call super(x, y), startVisionService()
    * and the SceneBase hooks. The camera that scrolls them lives in SceneBase;
    * a big scene not listed in config.xml's <bigScene> is measured from its art.
    */
   public class BigSceneBase extends SceneBase
   {
      /** Scene lighting helper of the 2013 engine; scenes call _visionHelper.setSwitchOn(on, fade). */
      protected var _visionHelper:VisionHelper = new VisionHelper();

      public function BigSceneBase(x:int, y:int)
      {
         super(x, y);
      }

      override revival function get measuresOwnWidth():Boolean
      {
         return true;
      }

   }
}
