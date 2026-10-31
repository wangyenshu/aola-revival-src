package mmo.fbteam.configure
{
   import flash.system.ApplicationDomain;
   import mmo.fbteam.fbaixi.FbAixiConfig;
   import mmo.fbteam.fbsiwude.FbSiwudeConfig;
   import mmo.fbteam.fbsuolide.FbSuolideConfig;
   import mmo.fbteam.fbyishuzhidu.FbYishuzhiduConfig;
   import mmo.play.scene.SceneManager;
   
   public class FBConfig
   {
      
      private static var _instence:FBConfig;
      
      private var _stepConfig:Array = [];
      
      private var _sceneConfig:Array = [];
      
      private var fbHelloTalkMap:Array = null;
      
      private var _namespace:Object = null;
      
      public function FBConfig()
      {
         super();
         this.sceneConfig();
         this.stepConfig();
         this.helloTalkConfig();
         this.namespaceConfig();
      }
      
      public static function get instence() : FBConfig
      {
         if(null == _instence)
         {
            _instence = new FBConfig();
         }
         return _instence;
      }
      
      private function helloTalkConfig() : void
      {
         this.fbHelloTalkMap = ["fbyishuzhidu1","fbaixi1","fbsiwude1"];
      }
      
      private function stepConfig() : void
      {
         this._stepConfig["fbyishuzhidu"] = FbYishuzhiduConfig.StepConfig;
         this._stepConfig["fbaixi"] = FbAixiConfig.StepConfig;
         this._stepConfig["fbsiwude"] = FbSiwudeConfig.StepConfig;
         this._stepConfig["fbsuolide"] = FbSuolideConfig.StepConfig;
      }
      
      private function sceneConfig() : void
      {
         this._sceneConfig = this._sceneConfig.concat(FbYishuzhiduConfig.SceneConfig);
         this._sceneConfig = this._sceneConfig.concat(FbAixiConfig.SceneConfig);
         this._sceneConfig = this._sceneConfig.concat(FbSiwudeConfig.SceneConfig);
         this._sceneConfig = this._sceneConfig.concat(FbSuolideConfig.SceneConfig);
      }
      
      private function namespaceConfig() : void
      {
         this._namespace = {
            "fbyishuzhidu":"mmo.fbteam.fbyishuzhidu.sceneplayer.YishuzhiduScenePlayer",
            "fbaixi":"mmo.fbteam.fbaixi.sceneplayer.FBAixiScenePlayer",
            "fbsiwude":"mmo.fbteam.fbsiwude.sceneplayer.FBSiwudeScenePlayer",
            "fbsuolide":"mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayer"
         };
      }
      
      public function get namespace() : Object
      {
         return this._namespace;
      }
      
      public function getClass(param1:String) : Class
      {
         if(ApplicationDomain.currentDomain.hasDefinition(param1))
         {
            return ApplicationDomain.currentDomain.getDefinition(param1) as Class;
         }
         var _loc2_:ApplicationDomain = this.getSceneApplicationDomain();
         if(_loc2_.hasDefinition(param1))
         {
            return _loc2_.getDefinition(param1) as Class;
         }
         return null;
      }
      
      public function getSceneApplicationDomain() : ApplicationDomain
      {
         return SceneManager.getInstance().loadedSceneInfo.applicationDomain;
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
      
      public function getCurrentStepInfo(param1:String, param2:String, param3:int) : String
      {
         return this._stepConfig[param1][param2][param3];
      }
      
      public function isTeamFBScene(param1:String) : Boolean
      {
         var _loc2_:String = null;
         for each(_loc2_ in this._sceneConfig)
         {
            if(_loc2_ == param1)
            {
               return true;
            }
         }
         return false;
      }
   }
}

