package mmo.fbservice.auto
{
   import mmo.play.scene.SceneManager;
   
   public class FBHelloTalkMap
   {
      
      private static var _instence:FBHelloTalkMap = null;
      
      private var fbHelloTalkMap:Array = null;
      
      public function FBHelloTalkMap()
      {
         super();
         this.initMap();
      }
      
      public static function get instence() : FBHelloTalkMap
      {
         if(null == _instence)
         {
            _instence = new FBHelloTalkMap();
         }
         return _instence;
      }
      
      private function initMap() : void
      {
         this.fbHelloTalkMap = ["fbsuolide1","fbsiwude1"];
      }
      
      public function checkCanHelloTalk() : Boolean
      {
         var _loc2_:String = null;
         var _loc1_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         for each(_loc2_ in this.fbHelloTalkMap)
         {
            if(_loc2_ == _loc1_)
            {
               return true;
            }
         }
         return false;
      }
   }
}

