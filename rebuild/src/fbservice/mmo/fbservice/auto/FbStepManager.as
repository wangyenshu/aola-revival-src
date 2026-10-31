package mmo.fbservice.auto
{
   import mmo.fbservice.fbsuolide.FbSuolideStep;
   
   public class FbStepManager
   {
      
      private static var _instence:FbStepManager = null;
      
      private var config:Array = [];
      
      private var _step:int = -1;
      
      public function FbStepManager()
      {
         super();
         this.configInit();
      }
      
      public static function get instence() : FbStepManager
      {
         if(null == _instence)
         {
            _instence = new FbStepManager();
         }
         return _instence;
      }
      
      private function configInit() : void
      {
         this.config["fbsuolide"] = FbSuolideStep.Config;
      }
      
      public function getCurrentStepInfo(param1:String, param2:String, param3:int) : String
      {
         return this.config[param1][param2][param3];
      }
   }
}

