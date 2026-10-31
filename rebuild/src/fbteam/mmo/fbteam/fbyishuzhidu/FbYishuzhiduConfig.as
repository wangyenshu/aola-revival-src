package mmo.fbteam.fbyishuzhidu
{
   public class FbYishuzhiduConfig
   {
      
      private static var stepConfig:Array = null;
      
      private static var sceneConfig:Array = null;
      
      public function FbYishuzhiduConfig()
      {
         super();
      }
      
      public static function get SceneConfig() : Array
      {
         if(null == sceneConfig)
         {
            sceneConfig = ["fbyishuzhidu1","fbyishuzhidu2","fbyishuzhidu3","fbyishuzhidu4"];
         }
         return sceneConfig;
      }
      
      public static function get StepConfig() : Array
      {
         if(null == stepConfig)
         {
            stepConfig = [];
            stepConfig["fbyishuzhidu1"] = [];
            stepConfig["fbyishuzhidu1"][0] = "movie:fb1_1_openlight";
            stepConfig["fbyishuzhidu1"][1] = "movie:fb1_2_dragon2real";
            stepConfig["fbyishuzhidu1"][2] = "talk:fbyishuzhidu1_1_hello";
            stepConfig["fbyishuzhidu1"][3] = "movie:fb1_3_dragon2sham";
            stepConfig["fbyishuzhidu1"][4] = "movie:fb1_3_opendoor";
            stepConfig["fbyishuzhidu2"] = [];
            stepConfig["fbyishuzhidu2"][0] = "movie:fb2_1_openbackground";
            stepConfig["fbyishuzhidu2"][1] = "movie:fb2_2_dragonfight";
            stepConfig["fbyishuzhidu2"][2] = "movie:fb2_3_chipscomm";
            stepConfig["fbyishuzhidu2"][3] = "talk:fbyishuzhidu2_1_nextscene";
            stepConfig["fbyishuzhidu2"][4] = "movie:fb2_4_opendoor";
            stepConfig["fbyishuzhidu3"] = [];
            stepConfig["fbyishuzhidu3"][0] = "movie:fb3_1_clickGrass";
            stepConfig["fbyishuzhidu3"][1] = "talk:fb3_2_helloTalk";
            stepConfig["fbyishuzhidu3"][2] = "movie:fb3_3_fightDinosaur";
            stepConfig["fbyishuzhidu4"] = [];
            stepConfig["fbyishuzhidu4"][0] = "movie:fb4_1_showarcher";
            stepConfig["fbyishuzhidu4"][1] = "movie:fb4_2_fightarcher";
            stepConfig["fbyishuzhidu4"][2] = "movie:fb4_3_toxophily_history";
            stepConfig["fbyishuzhidu4"][3] = "movie:fb4_4_tryfinish";
         }
         return stepConfig;
      }
   }
}

