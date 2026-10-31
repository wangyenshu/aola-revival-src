package mmo.fbservice.fbsuolide
{
   public class FbSuolideStep
   {
      
      private static var config:Array = null;
      
      public function FbSuolideStep()
      {
         super();
      }
      
      public static function get Config() : Array
      {
         if(null == config)
         {
            config = [];
            config["fbsuolide1"] = [];
            config["fbsuolide1"][0] = "movie:fb1_suolide_npc16_come";
            config["fbsuolide1"][1] = "talk:fbsuolide1_afterCatPrinceAppear";
            config["fbsuolide1"][2] = "movie:fb1_suolide_npc132_out_from_wall";
            config["fbsuolide1"][3] = "talk:fbsuolide1_afterAnubisAppear";
            config["fbsuolide1"][4] = "movie:fb1_suolide_npc132_call_enemy";
            config["fbsuolide1"][5] = "talk:fbsuolide1_fightWin";
            config["fbsuolide1"][6] = "movie:fb1_suolide_npc132_disappear";
            config["fbsuolide1"][7] = "talk:fbsuolide1_afterAnubisDisappear";
            config["fbsuolide1"][8] = "movie:fb1_suolide_npc133_appear";
            config["fbsuolide1"][9] = "talk:fbsuolide1_afterLanDingAppear";
            config["fbsuolide1"][10] = "movie:fb1_suolide_arrowhead_change";
            config["fbsuolide1"][11] = "talk:fbsuolide1_afterDirect";
            config["fbsuolide2"] = [];
            config["fbsuolide2"][0] = "movie:fb2_suolide_arrowhead_change";
            config["fbsuolide2"][1] = "talk:fbsuolide2_accessfbsuolide2";
            config["fbsuolide2"][2] = "movie:fb2_suolide_flagstome_game";
            config["fbsuolide2"][3] = "talk:fbsuolide2_afterDirect";
            config["fbsuolide3"] = [];
            config["fbsuolide3"][0] = "movie:fb3_suolide_npc133_appear";
            config["fbsuolide3"][1] = "talk:fbsuolide3_accessfbsuolide3";
            config["fbsuolide3"][2] = "movie:fb3_suolide_5mummy_game";
            config["fbsuolide3"][3] = "talk:fbsuolide3_rewardWay";
            config["fbsuolide3"][4] = "talk:fbsuolide3_leaveWay";
            config["fbsuolide3"][5] = "movie:fb3_suolide_leave";
            config["fbsuolide4"] = [];
            config["fbsuolide4"][0] = "movie:fb4_suolide_npc132_appear";
            config["fbsuolide4"][1] = "talk:fbsuolide4_afterAnubisAppear";
            config["fbsuolide4"][2] = "movie:fb4_fbsuolide4_fightwithanubis";
            config["fbsuolide4"][3] = "talk:fbsuolide4_fightWin";
            config["fbsuolide4"][4] = "movie:fb4_suolide_npc132_gift";
            config["fbsuolide5"] = [];
            config["fbsuolide5"][0] = "movie:fb5_suolide_npc133_appear";
            config["fbsuolide5"][1] = "talk:fbsuolide5_afterLanDingAppearThreeTimes";
            config["fbsuolide5"][2] = "movie:fb5_suolide_arrowhead_change";
            config["fbsuolide5"][3] = "movie:fb5_suolide_balance";
            config["fbsuolide6"] = [];
            config["fbsuolide6"][0] = "movie:fb6_suolide_init_scene";
            config["fbsuolide6"][1] = "talk:fbsuolide6_clickWood";
            config["fbsuolide6"][2] = "talk:fbsuolide6_clickSoil";
            config["fbsuolide6"][3] = "movie:fb6_suolide_woodenpet_to_enemy";
            config["fbsuolide6"][4] = "movie:fb6_suolide_soilpet_to_enemy";
            config["fbsuolide6"][5] = "movie:fb6_fbsuolide6_notHelpWoodFiveTimes";
            config["fbsuolide6"][6] = "movie:fb6_fbsuolide6_notHelpSoilFiveTimes";
            config["fbsuolide6"][7] = "talk:fbsuolide6_fightWithSoilWin";
            config["fbsuolide6"][8] = "talk:fbsuolide6_fightWithWoodWin";
            config["fbsuolide6"][9] = "talk:fbsuolide6_notHelpWoodFiveTimes";
            config["fbsuolide6"][10] = "talk:fbsuolide6_notHelpSoilFiveTimes";
            config["fbsuolide6"][11] = "movie:fb6_suolide_exit_appear";
            config["fbsuolide7"] = [];
            config["fbsuolide7"][0] = "movie:fb7_suolide_flowerOfSuolide";
            config["fbsuolide7"][1] = "talk:fbsuolide7_appearMzsh";
            config["fbsuolide7"][2] = "movie:fb7_suolide_fightWithMzsh";
            config["fbsuolide7"][3] = "talk:fbsuolide7_leave";
            config["fbsuolide7"][4] = "movie:fb7_suolide_leave";
            config["fbsuolide8"] = [];
            config["fbsuolide8"][0] = "talk:fbsuolide8_afterAccessSuolide8";
            config["fbsuolide8"][1] = "movie:fb8_suolide_mummy_appaer";
            config["fbsuolide8"][2] = "talk:fbsuolide8_afterOpenTheBier";
            config["fbsuolide8"][3] = "movie:fb8_suolide_android_appear";
            config["fbsuolide8"][4] = "movie:fb8_suolide_npc133_appear";
            config["fbsuolide8"][5] = "talk:fbsuolide8_fightWin";
            config["fbsuolide8"][6] = "movie:fb8_suolide_android_destroy";
            config["fbsuolide8"][7] = "talk:fbsuolide8_talklanding";
            config["fbsuolide8"][8] = "movie:fb8_suolide_npc133_disappear";
            config["fbsuolide8"][9] = "movie:fb8_suolide_findexit";
            config["fbsuolide8"][10] = "movie:fb8_suolide_exit_appear";
            config["fbsuolide9"] = [];
            config["fbsuolide9"][0] = "movie:fb9_suolide_npc136_boss_appear";
            config["fbsuolide9"][1] = "talk:fbsuolide9_begin";
            config["fbsuolide9"][2] = "movie:fb9_suolide_fightwith";
            config["fbsuolide9"][3] = "talk:fbsuolide9_fightWithRabbiWin";
            config["fbsuolide9"][4] = "movie:fb9_suolide_npc133_appear";
            config["fbsuolide9"][5] = "talk:fbsuolide9_afterLanDingAppearFouthTimes";
            config["fbsuolide9"][6] = "movie:fb9_suolide_fight_win";
            config["fbsuolide9"][7] = "movie:fb9_suolide_cat_appear";
            config["fbsuolide9"][8] = "talk:fbsuolide9_cat_appear";
            config["fbsuolide9"][9] = "movie:fb9_suolide_present";
            config["fbsuolide9"][10] = "talk:fbsuolide9_afterDistoryRabbiPower";
            config["fbsuolide9"][11] = "movie:fb9_suolide_stelae_distroy";
            config["fbsuolide9"][12] = "talk:fb9_suolide_stelae_distroy_end";
            config["fbsuolide9"][13] = "movie:fb9_suolide_exti_appear";
            config["fbsuolide10"] = [];
            config["fbsuolide10"][0] = "movie:fb10_suolide_init_scene";
            config["fbsuolide10"][1] = "talk:577_fbsuolide10_afterSoilPrinceFallDown";
            config["fbsuolide10"][2] = "movie:fb10_suolide_save_prince";
            config["fbsuolide10"][3] = "talk:577_fbsuolide10_afterSaveSoilPrince";
            config["fbsuolide10"][4] = "movie:fb10_suolide_princehelpus";
            config["fbsuolide10"][5] = "talk:577_fbsuolide10_afterSoilPrinceShowTreasure";
            config["fbsuolide10"][6] = "movie:fb9_suolide_npc136_boss_appear";
         }
         return config;
      }
   }
}

