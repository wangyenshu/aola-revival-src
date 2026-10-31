package mmo.game.parkour.game.config
{
   import flash.display.DisplayObject;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.game.parkour.config.ParkourResConfig;
   
   public class ParkourGameResConfig
   {
      
      private static const PreClsName:String = ParkourResConfig.PreClsName + "game.";
      
      public static const PreNameOfGameSceneResObj:String = ParkourResConfig.PreResPath + "field/parkourfield";
      
      private static const DifferenceItemViewsOfField:Array = [ParkourGameMapConfig.Barrier0,ParkourGameMapConfig.Road];
      
      public static const ClsNameOfUI:String = PreClsName + "GameUI";
      
      public static const ResPathOfTeachMovie:String = ParkourResConfig.PreResPath + "parkourteachmovie";
      
      public static const PreClsNameOfTeachMovie:String = PreClsName + "TeachMovie_";
      
      public static const PreClsNameOfBackGround:String = PreClsName + "BackGround_";
      
      public static const ClsNameOfStartMovie:String = PreClsName + "StartMovie";
      
      public static const ClsNameOfFullPowerMovie:String = PreClsName + "FullPowerMovie";
      
      public function ParkourGameResConfig()
      {
         super();
      }
      
      public static function createViewOfMapItemByType(param1:int, param2:int) : DisplayObject
      {
         if(ApplicationDomain.currentDomain.hasDefinition(getDifferItemClsNameByType(param1,param2)))
         {
            return createDisplayObj(getDifferItemClsNameByType(param1,param2));
         }
         return createDisplayObj(getItemClsNameByType(param2));
      }
      
      public static function createDisplayObj(param1:String) : DisplayObject
      {
         var _loc2_:Class = getDefinitionByName(param1) as Class;
         return new _loc2_() as DisplayObject;
      }
      
      private static function getDifferItemClsNameByType(param1:int, param2:int) : String
      {
         return PreClsName + "MapItem_" + param1 + "_" + param2;
      }
      
      private static function getItemClsNameByType(param1:int) : String
      {
         return PreClsName + "MapItem_" + param1;
      }
   }
}

