package mmo.play.scene
{
   /** REBUILT. The scene info of an instance (副本) scene, as SceneManager.loadFB sets it. */
   public class FBSceneInfo extends SceneInfo
   {
      public var fbId:int;
      public var fbName:String;
      public var teamKey:String;
      public var step:int;

      public function FBSceneInfo(sceneName:String = null, roomName:String = null, swf:String = null)
      {
         super(sceneName, roomName, swf);
      }
   }
}
