package mmo.fbteam.fbsuolide
{
   public class FbSuolideConfig
   {
      
      private static var stepConfig:Array = null;
      
      private static var sceneConfig:Array = null;
      
      public function FbSuolideConfig()
      {
         super();
      }
      
      public static function get SceneConfig() : Array
      {
         if(null == sceneConfig)
         {
            sceneConfig = ["fbsuolide1","fbsuolide2","fbsuolide3","fbsuolide4","fbsuolide5","fbsuolide6","fbsuolide7","fbsuolide8","fbsuolide9","fbsuolide10"];
         }
         return sceneConfig;
      }
      
      public static function get StepConfig() : Array
      {
         if(null == stepConfig)
         {
            stepConfig = [];
            stepConfig["fbsuolide1"] = [];
            stepConfig["fbsuolide1"][0] = "movie:fb1_suolide_npc16_come";
            stepConfig["fbsuolide1"][1] = "talk:fbsuolide1_afterCatPrinceAppear";
            stepConfig["fbsuolide1"][2] = "movie:fb1_suolide_npc132_out_from_wall";
            stepConfig["fbsuolide1"][3] = "talk:fbsuolide1_afterAnubisAppear";
            stepConfig["fbsuolide1"][4] = "movie:fb1_suolide_npc132_call_enemy";
            stepConfig["fbsuolide1"][5] = "talk:fbsuolide1_fightWin";
            stepConfig["fbsuolide1"][6] = "movie:fb1_suolide_npc132_disappear";
            stepConfig["fbsuolide1"][7] = "talk:fbsuolide1_afterAnubisDisappear";
            stepConfig["fbsuolide1"][8] = "movie:fb1_suolide_npc133_appear";
            stepConfig["fbsuolide1"][9] = "talk:fbsuolide1_afterLanDingAppear";
            stepConfig["fbsuolide1"][10] = "movie:fb1_suolide_arrowhead_change";
            stepConfig["fbsuolide1"][11] = "talk:fbsuolide1_afterDirect";
            stepConfig["fbsuolide2"] = [];
            stepConfig["fbsuolide2"][0] = "movie:fb2_suolide_arrowhead_change";
            stepConfig["fbsuolide2"][1] = "talk:fbsuolide2_accessfbsuolide2";
            stepConfig["fbsuolide2"][2] = "movie:fb2_suolide_flagstome_game";
            stepConfig["fbsuolide2"][3] = "talk:fbsuolide2_afterDirect";
            stepConfig["fbsuolide3"] = [];
            stepConfig["fbsuolide3"][0] = "movie:fb3_suolide_npc133_appear";
            stepConfig["fbsuolide3"][1] = "talk:fbsuolide3_accessfbsuolide3";
            stepConfig["fbsuolide3"][2] = "movie:fb3_suolide_5mummy_game";
            stepConfig["fbsuolide3"][3] = "talk:fbsuolide3_leaveWay";
            stepConfig["fbsuolide3"][4] = "movie:fb3_suolide_leave";
            stepConfig["fbsuolide4"] = [];
            stepConfig["fbsuolide4"][0] = "movie:fb4_suolide_npc132_appear";
            stepConfig["fbsuolide4"][1] = "talk:fbsuolide4_afterAnubisAppear";
            stepConfig["fbsuolide4"][2] = "movie:fb4_fbsuolide4_fightwithanubis";
            stepConfig["fbsuolide4"][3] = "talk:fbsuolide4_fightWin";
            stepConfig["fbsuolide4"][4] = "movie:fb4_suolide_npc132_gift";
            stepConfig["fbsuolide5"] = [];
            stepConfig["fbsuolide5"][0] = "movie:fb5_suolide_npc133_appear";
            stepConfig["fbsuolide5"][1] = "talk:fbsuolide5_afterLanDingAppearThreeTimes";
            stepConfig["fbsuolide5"][2] = "movie:fb5_suolide_arrowhead_change";
            stepConfig["fbsuolide5"][3] = "movie:fb5_suolide_balance";
            stepConfig["fbsuolide6"] = [];
            stepConfig["fbsuolide6"][0] = "movie:fb6_suolide_init_scene";
            stepConfig["fbsuolide6"][1] = "talk:fbsuolide6_clickWood:stop";
            stepConfig["fbsuolide6"][2] = "talk:fbsuolide6_clickSoil";
            stepConfig["fbsuolide6"][3] = "movie:fb6_suolide_woodenpet_to_enemy";
            stepConfig["fbsuolide6"][4] = "movie:fb6_suolide_soilpet_to_enemy";
            stepConfig["fbsuolide6"][5] = "movie:fb6_fbsuolide6_notHelpWoodFiveTimes";
            stepConfig["fbsuolide6"][6] = "movie:fb6_fbsuolide6_notHelpSoilFiveTimes";
            stepConfig["fbsuolide6"][7] = "movie:fb6_suolide_exit_appear";
            stepConfig["fbsuolide7"] = [];
            stepConfig["fbsuolide7"][0] = "movie:fb7_suolide_flowerOfSuolide";
            stepConfig["fbsuolide7"][1] = "talk:fbsuolide7_appearMzsh";
            stepConfig["fbsuolide7"][2] = "movie:fb7_suolide_fightWithMzsh";
            stepConfig["fbsuolide7"][3] = "talk:fbsuolide7_leave";
            stepConfig["fbsuolide7"][4] = "movie:fb7_suolide_leave";
            stepConfig["fbsuolide8"] = [];
            stepConfig["fbsuolide8"][0] = "talk:fbsuolide8_afterAccessSuolide8";
            stepConfig["fbsuolide8"][1] = "movie:fb8_suolide_mummy_appaer";
            stepConfig["fbsuolide8"][2] = "talk:fbsuolide8_afterOpenTheBier";
            stepConfig["fbsuolide8"][3] = "movie:fb8_suolide_android_appear";
            stepConfig["fbsuolide8"][4] = "movie:fb8_suolide_npc133_appear";
            stepConfig["fbsuolide8"][5] = "talk:fbsuolide8_fightWin";
            stepConfig["fbsuolide8"][6] = "movie:fb8_suolide_android_destroy";
            stepConfig["fbsuolide8"][7] = "talk:fbsuolide8_talklanding";
            stepConfig["fbsuolide8"][8] = "movie:fb8_suolide_npc133_disappear";
            stepConfig["fbsuolide8"][9] = "movie:fb8_suolide_findexit";
            stepConfig["fbsuolide8"][10] = "movie:fb8_suolide_exit_appear";
            stepConfig["fbsuolide9"] = [];
            stepConfig["fbsuolide9"][0] = "movie:fb9_suolide_npc136_boss_appear";
            stepConfig["fbsuolide9"][1] = "talk:fbsuolide9_begin";
            stepConfig["fbsuolide9"][2] = "movie:fb9_suolide_fightwith";
            stepConfig["fbsuolide9"][3] = "talk:fbsuolide9_fightWithRabbiWin";
            stepConfig["fbsuolide9"][4] = "movie:fb9_suolide_npc133_appear";
            stepConfig["fbsuolide9"][5] = "talk:fbsuolide9_afterLanDingAppearFouthTimes";
            stepConfig["fbsuolide9"][6] = "movie:fb9_suolide_fight_win";
            stepConfig["fbsuolide9"][7] = "movie:fb9_suolide_cat_appear";
            stepConfig["fbsuolide9"][8] = "talk:fbsuolide9_cat_appear";
            stepConfig["fbsuolide9"][9] = "movie:fb9_suolide_present";
            stepConfig["fbsuolide9"][10] = "movie:fb9_suolide_exti_appear";
            stepConfig["fbsuolide10"] = [];
            stepConfig["fbsuolide10"][0] = "movie:fb10_suolide_init_scene";
            stepConfig["fbsuolide10"][1] = "talk:577_fbsuolide10_afterSoilPrinceFallDown";
            stepConfig["fbsuolide10"][2] = "movie:fb10_suolide_save_prince";
            stepConfig["fbsuolide10"][3] = "talk:577_fbsuolide10_afterSaveSoilPrince";
            stepConfig["fbsuolide10"][4] = "movie:fb10_suolide_princehelpus";
            stepConfig["fbsuolide10"][5] = "talk:577_fbsuolide10_afterSoilPrinceShowTreasure";
            stepConfig["fbsuolide10"][6] = "movie:fb9_suolide_npc136_boss_appear";
         }
         return stepConfig;
      }
   }
}

