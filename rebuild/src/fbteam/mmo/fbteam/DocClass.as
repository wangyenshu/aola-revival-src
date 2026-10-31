package mmo.fbteam
{
   import flash.display.Sprite;
   import mmo.fbteam.auto.FBSceneAdmin;
   import mmo.fbteam.auto.FBStepAdmin;
   import mmo.fbteam.common.FBButtonManager;
   import mmo.fbteam.common.FbWildPetManager;
   import mmo.fbteam.common.HitObjectHelper;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.configure.FB_ScenePlayerCompiler;
   import mmo.fbteam.service.FBLoaderService;
   import mmo.fbteam.service.FBTeamService;
   
   public class DocClass extends Sprite
   {
      
      public function DocClass()
      {
         super();
      }
      
      private function complime() : void
      {
         var _loc1_:FBTeamService = null;
         var _loc2_:FBLoaderService = null;
         var _loc3_:FBConfig = null;
         var _loc4_:HitObjectHelper = null;
         var _loc5_:SceneHelper = null;
         var _loc6_:TeamHelper = null;
         var _loc7_:FBSceneAdmin = null;
         var _loc8_:FBStepAdmin = null;
         var _loc9_:FB_ScenePlayerCompiler = null;
         var _loc10_:FbWildPetManager = null;
         var _loc11_:FBButtonManager = null;
         var _loc12_:FBTeamSynchronizedClient = null;
         var _loc13_:FBTeamSynchronizedEvent = null;
         var _loc14_:FBTeamSynchronizedEventDispatcher = null;
      }
   }
}

