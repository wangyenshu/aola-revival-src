package mmo.play.scene
{
   import flash.display.DisplayObject;

   /**
    * REBUILT. Base class of the instance (副本) rooms: the plain scene, and
    * addFBEntrances, a door to another room of the same instance (the era
    * 黑星堡垒 viparena1-7 and the 2012 副本 rooms call it), which enters it
    * by SceneManager.loadFB so it stays an FBSceneInfo with that fbName.
    */
   public class FBSceneBase extends SceneBase
   {
      public function FBSceneBase(x:int = 480, y:int = 400)
      {
         super(x, y);
      }

      protected function addFBEntrances(area:DisplayObject, sceneName:String, fbName:String, locationKey:String = "default", teamKey:String = "", button:DisplayObject = null):void
      {
         if (area == null) return;
         addEntranceAction(area, function():void
         {
            SceneManager.getInstance().loadFB(sceneName, fbName, "", teamKey, locationKey);
         }, button);
      }
   }
}
