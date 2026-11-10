package mmo.superevolution
{
   /**
    * REBUILT pet/superevolution's table (its copy of 2015, SuperEvolutionConfig), cut to the 亚比 of
    * 2013: the 超进化 of the 超进化手册 (catalog/superevolution1–5) and of the 2013 material data. The
    * 2015 table's first four (断罪天使莱特 2267, 辉月巨灵 2255, 星云斗战神 2051, 麦斗元帅 2052) are of
    * later years, and 金银尊者 (1451) needs 风色佩剑 (item 702), which the 2013 items do not have.
    */
   public class SuperEvolutionConfig
   {
      /** The order of the 2015 table: the frames of the 超进化机's selectPetMC (frame = index + 1). */
      public static const ART_ORDER:Array = [2267, 2255, 2051, 2052, 502, 500, 501, 506, 1159, 1380, 505, 1134, 209, 1451];

      /** The 超进化 of 2013, in the 2015 table's order. */
      public static const ERA:Array = [502, 500, 501, 506, 1159, 1380, 505, 1134, 209];

      /** What each takes: [{id, num}] (item ids; 265 次级进化水晶, 266 进化水晶). */
      public static const EVO_ITEM_MATCH:Object = {
         500: [{num: 30, id: 265}, {num: 10, id: 266}, {num: 1, id: 88}, {num: 1, id: 213}],
         501: [{num: 30, id: 265}, {num: 10, id: 266}, {num: 1, id: 93}, {num: 1, id: 200}],
         502: [{num: 30, id: 265}, {num: 10, id: 266}, {num: 1, id: 91}, {num: 1, id: 133}],
         506: [{num: 1, id: 335}],
         1159: [{num: 10, id: 265}, {num: 4, id: 266}, {num: 1, id: 91}, {num: 1, id: 86}],
         1380: [{num: 10, id: 265}, {num: 4, id: 266}, {num: 1, id: 87}, {num: 1, id: 124}],
         505: [{num: 10, id: 265}, {num: 4, id: 266}, {num: 1, id: 86}, {num: 1, id: 200}],
         1134: [{num: 10, id: 265}, {num: 4, id: 266}, {num: 1, id: 133}, {num: 1, id: 200}],
         209: [{num: 10, id: 265}, {num: 4, id: 266}, {num: 1, id: 88}, {num: 1, id: 200}]
      };

      /** The 亚比 each comes from and the kind sent with it (54e_1's t: 2 for 烈焰鸟's 炎之结晶). */
      private static const FROM:Object = {
         500: [3, 1], 501: [6, 1], 502: [9, 1], 506: [278, 2], 1159: [566, 1],
         1380: [487, 1], 505: [12, 1], 1134: [54, 1], 209: [24, 1]
      };

      public static function getEovlutionIDArr():Array
      {
         return ERA;
      }

      /** The race a 超进化 starts from. */
      public static function fromRace(evoId:int):int
      {
         return FROM[evoId] ? int(FROM[evoId][0]) : 0;
      }

      public static function evoType(evoId:int):int
      {
         return FROM[evoId] ? int(FROM[evoId][1]) : 1;
      }

      public static function getEvoNeedPetIdMatch(evoId:int):Array
      {
         return FROM[evoId] ? [int(FROM[evoId][0])] : [];
      }
   }
}
