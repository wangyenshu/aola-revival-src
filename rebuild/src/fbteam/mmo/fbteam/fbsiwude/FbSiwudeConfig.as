package mmo.fbteam.fbsiwude
{
   public class FbSiwudeConfig
   {
      
      private static var stepConfig:Array = null;
      
      private static var sceneConfig:Array = null;
      
      public function FbSiwudeConfig()
      {
         super();
      }
      
      public static function get SceneConfig() : Array
      {
         if(null == sceneConfig)
         {
            sceneConfig = ["fbsiwude1","fbsiwude2","fbsiwude3","fbsiwude4","fbsiwude5","fbsiwude6","fbsiwude9","fbsiwude10","fbsiwude11"];
         }
         return sceneConfig;
      }
      
      public static function get StepConfig() : Array
      {
         if(null == stepConfig)
         {
            stepConfig = [];
            stepConfig["fbsiwude1"] = [];
            stepConfig["fbsiwude1"][0] = "movie:" + FbSiwudeCommandConst.FB1_1_INIT;
            stepConfig["fbsiwude1"][1] = "movie:" + FbSiwudeCommandConst.FB1_2_SHOWARROWHEAD;
            stepConfig["fbsiwude1"][2] = "movie:" + FbSiwudeCommandConst.FB1_3_GAME;
            stepConfig["fbsiwude2"] = [];
            stepConfig["fbsiwude2"][0] = "movie:" + FbSiwudeCommandConst.FB2_0_INIT;
            stepConfig["fbsiwude2"][1] = "movie:" + FbSiwudeCommandConst.FB2_1_SHOW_ARROWHEAD;
            stepConfig["fbsiwude2"][2] = "movie:" + FbSiwudeCommandConst.FB2_2_GAME;
            stepConfig["fbsiwude2"][3] = "movie:" + FbSiwudeCommandConst.FB2_3_SWITCH;
            stepConfig["fbsiwude3"] = [];
            stepConfig["fbsiwude3"][0] = "movie:" + FbSiwudeCommandConst.FB3_1SHOWARROW;
            stepConfig["fbsiwude3"][1] = "movie:" + FbSiwudeCommandConst.FB3_2GAME;
            stepConfig["fbsiwude4"] = [];
            stepConfig["fbsiwude4"][0] = "movie:" + FbSiwudeCommandConst.FB4_1GAME;
            stepConfig["fbsiwude4"][1] = "movie:" + FbSiwudeCommandConst.FB4_2GOGO;
            stepConfig["fbsiwude4"][2] = "movie:" + FbSiwudeCommandConst.FB4_3GETBOX;
            stepConfig["fbsiwude5"] = [];
            stepConfig["fbsiwude5"][0] = "movie:" + FbSiwudeCommandConst.FB5_0_INIT;
            stepConfig["fbsiwude5"][1] = "movie:" + FbSiwudeCommandConst.FB5_1_FIGHTANT;
            stepConfig["fbsiwude5"][2] = "movie:" + FbSiwudeCommandConst.FB5_2_GOGO;
            stepConfig["fbsiwude6"] = [];
            stepConfig["fbsiwude6"][0] = "movie:" + FbSiwudeCommandConst.FB6_1_FIGHTANT;
            stepConfig["fbsiwude6"][1] = "talk:" + "fbsiwude6_fightend_1";
            stepConfig["fbsiwude6"][2] = "movie:" + FbSiwudeCommandConst.FB6_2_GOGO;
            stepConfig["fbsiwude9"] = [];
            stepConfig["fbsiwude9"][0] = "talk:" + "fbsiwude9_hellotalk";
            stepConfig["fbsiwude9"][1] = "movie:" + FbSiwudeCommandConst.FB9_1_INIT;
            stepConfig["fbsiwude9"][2] = "movie:" + FbSiwudeCommandConst.FB9_2_GAME;
            stepConfig["fbsiwude9"][3] = "movie:" + FbSiwudeCommandConst.FB9_3_OPENDOOR;
            stepConfig["fbsiwude9"][4] = "movie:" + FbSiwudeCommandConst.FB9_4_GOGO;
            stepConfig["fbsiwude10"] = [];
            stepConfig["fbsiwude10"][0] = "movie:" + FbSiwudeCommandConst.FB10_1_INIT;
            stepConfig["fbsiwude10"][1] = "talk:" + "fbsiwude10_step1";
            stepConfig["fbsiwude10"][2] = "movie:" + FbSiwudeCommandConst.FB10_2_FIGHT4;
            stepConfig["fbsiwude10"][3] = "talk:" + "fbsiwude10_step3";
            stepConfig["fbsiwude10"][4] = "movie:" + FbSiwudeCommandConst.FB10_3_OPENDOORGOGO;
            stepConfig["fbsiwude11"] = [];
            stepConfig["fbsiwude11"][0] = "talk:" + "fbsiwude11_step0";
            stepConfig["fbsiwude11"][1] = "movie:" + FbSiwudeCommandConst.FB11_1_FOURATTACKMOVIE;
            stepConfig["fbsiwude11"][2] = "talk:" + "fbsiwude11_step2";
            stepConfig["fbsiwude11"][3] = "movie:" + FbSiwudeCommandConst.FB11_2_FIGHTWITHLITTLE;
            stepConfig["fbsiwude11"][4] = "talk:" + "fbsiwude11_step4";
            stepConfig["fbsiwude11"][5] = "movie:" + FbSiwudeCommandConst.FB11_3_FIGHTWITHBOSS;
            stepConfig["fbsiwude11"][6] = "talk:" + "fbsiwude11_step6";
            stepConfig["fbsiwude11"][7] = "movie:" + FbSiwudeCommandConst.FB11_4_ABERRANCE;
            stepConfig["fbsiwude11"][8] = "talk:" + "fbsiwude11_step8";
            stepConfig["fbsiwude11"][9] = "movie:" + FbSiwudeCommandConst.FB11_5_FIGHTWITHABERRANCE;
            stepConfig["fbsiwude11"][10] = "movie:" + FbSiwudeCommandConst.FB11_6_AFTERFIGHT;
            stepConfig["fbsiwude11"][11] = "talk:" + "fbsiwude11_step11";
            stepConfig["fbsiwude11"][12] = "movie:" + FbSiwudeCommandConst.FB11_7_HELPQUEUE;
            stepConfig["fbsiwude11"][13] = "talk:" + "fbsiwude11_step13";
            stepConfig["fbsiwude11"][14] = "movie:" + FbSiwudeCommandConst.FB11_8_GETBONUS;
         }
         return stepConfig;
      }
   }
}

