package mmo.spacetime.pet
{
   public class PetsConfig
   {
      
      private static const RES_PREFIX:String = "spacetime/spacetimepet";
      
      private static const CLS_PREFIX:String = "mmo.spacetime.SpacetimePet";
      
      private static const SPECIAL_PET_CONFIG:Object = {};
      
      public function PetsConfig()
      {
         super();
      }
      
      private static function checkSpecialKeyByPetId(param1:int) : Boolean
      {
         return SPECIAL_PET_CONFIG.hasOwnProperty("" + param1);
      }
      
      private static function getSpecialKeyByPetId(param1:int) : String
      {
         return SPECIAL_PET_CONFIG[param1 + ""];
      }
      
      private static function getSimpleKeyByPetId(param1:int) : String
      {
         var _loc2_:int = param1 % 10000;
         return _loc2_.toString();
      }
      
      private static function getKeyByPetId(param1:int) : String
      {
         if(checkSpecialKeyByPetId(param1))
         {
            return getSpecialKeyByPetId(param1);
         }
         return getSimpleKeyByPetId(param1);
      }
      
      public static function getPetResPath(param1:int) : String
      {
         var _loc2_:String = getKeyByPetId(param1).toString();
         if(int(_loc2_) < 10)
         {
            return RES_PREFIX + "0";
         }
         return RES_PREFIX + _loc2_.charAt(_loc2_.length - 2);
      }
      
      public static function getPetClsName(param1:int) : String
      {
         return CLS_PREFIX + getKeyByPetId(param1);
      }
      
      private function doc() : void
      {
         var _loc1_:Array = [2,3,5,6,8,9,102,105,108,201,203,204,207,208,301,302,303,304,305,408,503,504,509,601,608,701,704,1000];
         var _loc2_:Array = [11,12,14,15,16,17,18,111,114,218,219,317,411,414,418,512,514,516,612,615,618,619,710,711,715];
         var _loc3_:Array = [20,21,23,24,27,29,123,126,129,220,221,222,223,224,225,227,322,325,328,329,424,427,522,526,620,621,622];
         var _loc4_:Array = [30,31,32,33,35,36,39,132,135,138,230,232,233,238,339,430,433,436,439,533,633,639];
         var _loc5_:Array = [41,42,44,45,47,48,141,144,147,240,241,242,243,249,340,343,346,349,442,445,542,545,548,641,643,644];
         var _loc6_:Array = [51,54,57,59,150,153,155,156,158,159,255,258,355,358,457,551,554,557,650,653,654,655,656];
         var _loc7_:Array = [60,62,63,66,67,68,69,162,165,168,261,265,266,267,268,364,366,367,368,460,463,469,566,569,662,665];
         var _loc8_:Array = [71,72,75,78,171,174,177,271,278,370,371,372,373,374,375,472,475,571,574,577,672,673,678];
         var _loc9_:Array = [81,84,87,180,183,185,189,284,287,382,383,484,487,580,583,682];
         var _loc10_:Array = [90,93,96,99,192,195,198,293,296,299,393,394,397,398,493,499,598,697,699];
      }
   }
}

