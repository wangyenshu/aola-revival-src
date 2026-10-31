package mmo.play.scene
{
   import flash.system.ApplicationDomain;

   /** REBUILT. What SceneManager.loadedSceneInfo exposes to scenes and modules. */
   public class SceneInfo
   {
      public var sceneName:String;
      public var roomName:String;
      public var swf:String;
      public var scene:SceneBase;
      public var doc:DocSceneBase;
      public var locationKey:String;
      /** Homes (house/houseloader): the scene is a house SWF (furniture/b<id>) in the owner's room. */
      public var inHouse:Boolean;
      public var inMyHouse:Boolean;
      /** Shown while loading ("正在进入<desc>……") when set. */
      public var sceneDesc:String;
      public var faceDirection:String = "ld";
      public var extInfo:Object;

      public function SceneInfo(sceneName:String = null, roomName:String = null, swf:String = null)
      {
         this.sceneName = sceneName;
         this.roomName = roomName;
         this.swf = swf;
      }

      /** An instance (副本) room, entered by SceneManager.loadFB (FBSceneInfo). */
      public function get isFB():Boolean
      {
         return false;
      }

      /** The 2013 name of roomName. */
      public function get serverRoom():String
      {
         return roomName;
      }

      public function set serverRoom(v:String):void
      {
         roomName = v;
      }

      public function get sceneSwf():String
      {
         return swf;
      }

      public function set sceneSwf(v:String):void
      {
         swf = v;
      }

      public function get locationName():String
      {
         return locationKey;
      }

      public function set locationName(v:String):void
      {
         locationKey = v;
      }

      /** Scene SWFs and the furniture they use are loaded into the main domain. */
      public function get applicationDomain():ApplicationDomain
      {
         return ApplicationDomain.currentDomain;
      }

      public function dispose():void
      {
         scene = null;
         doc = null;
      }
   }
}
