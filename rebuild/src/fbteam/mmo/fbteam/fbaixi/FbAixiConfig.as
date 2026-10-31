package mmo.fbteam.fbaixi
{
   public class FbAixiConfig
   {
      
      private static var stepConfig:Array = null;
      
      private static var sceneConfig:Array = null;
      
      public function FbAixiConfig()
      {
         super();
      }
      
      public static function get SceneConfig() : Array
      {
         if(null == sceneConfig)
         {
            sceneConfig = ["fbaixi1","fbaixi2","fbaixi3","fbaixi4","fbaixi5","fbaixi6","fbaixi7","fbaixi8","fbaixi9"];
         }
         return sceneConfig;
      }
      
      public static function get StepConfig() : Array
      {
         if(null == stepConfig)
         {
            stepConfig = [];
            stepConfig["fbaixi1"] = [];
            stepConfig["fbaixi2"] = [];
            stepConfig["fbaixi2"][0] = "movie:" + FbAixiCommandConst.FB2_0_1_ADDSHADOW;
            stepConfig["fbaixi2"][1] = "movie:" + FbAixiCommandConst.FB2_0_CAPTAINSCENARIO;
            stepConfig["fbaixi2"][2] = "movie:" + FbAixiCommandConst.FB2_1_OPENDOOR;
            stepConfig["fbaixi3"] = [];
            stepConfig["fbaixi3"][0] = "movie:" + FbAixiCommandConst.FB3_1_OPENDOOR;
            stepConfig["fbaixi3"][1] = "movie:" + FbAixiCommandConst.FB3_2_ADDARROW;
            stepConfig["fbaixi4"] = [];
            stepConfig["fbaixi4"][0] = "movie:" + FbAixiCommandConst.FB4_1_BOSSAPPEAR;
            stepConfig["fbaixi4"][1] = "movie:" + FbAixiCommandConst.FB4_3_BOSSFIGHT;
            stepConfig["fbaixi4"][2] = "movie:" + FbAixiCommandConst.FB4_4_BOSSDISAPPEAR;
            stepConfig["fbaixi4"][3] = "movie:" + FbAixiCommandConst.FB4_5_OPENDOOR;
            stepConfig["fbaixi4"][4] = "movie:" + FbAixiCommandConst.FB4_6_ROAD;
            stepConfig["fbaixi5"] = [];
            stepConfig["fbaixi5"][0] = "movie:" + FbAixiCommandConst.FB5_1_CASEBOX;
            stepConfig["fbaixi6"] = [];
            stepConfig["fbaixi6"][0] = "movie:" + FbAixiCommandConst.FB6_1_OPENLIGHT;
            stepConfig["fbaixi6"][1] = "movie:" + FbAixiCommandConst.FB6_2_OPENDOOR;
            stepConfig["fbaixi7"] = [];
            stepConfig["fbaixi7"][0] = "movie:" + FbAixiCommandConst.FB7_1_GAME;
            stepConfig["fbaixi7"][1] = "movie:" + FbAixiCommandConst.FB7_2_OPENDOOR;
            stepConfig["fbaixi8"] = [];
            stepConfig["fbaixi8"][0] = "movie:" + FbAixiCommandConst.FB8_2_BOSSINIT;
            stepConfig["fbaixi8"][1] = "movie:" + FbAixiCommandConst.FB8_3_WINMOVIE;
            stepConfig["fbaixi9"] = [];
            stepConfig["fbaixi9"][0] = "movie:" + FbAixiCommandConst.FB9_1_BOSSAPPEAR;
            stepConfig["fbaixi9"][1] = "movie:" + FbAixiCommandConst.FB9_2_BOSSFIGHT;
            stepConfig["fbaixi9"][2] = "movie:" + FbAixiCommandConst.FB9_3_GETBONUS;
         }
         return stepConfig;
      }
   }
}

