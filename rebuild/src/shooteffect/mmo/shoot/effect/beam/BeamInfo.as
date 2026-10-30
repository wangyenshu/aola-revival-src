package mmo.shoot.effect.beam
{
   public class BeamInfo
   {
      
      public static const BEAM_TYPE_DOUBLE_MOVIE:int = 1;
      
      public static const BEAM_TYPE_MOVIECLIP:int = 2;
      
      public static const BEAM_TYPE_COLLECT_MOVIE:int = 3;
      
      public var type:String;
      
      public var beamType:int;
      
      public var length:int;
      
      public function BeamInfo(param1:String, param2:int, param3:int)
      {
         super();
         this.type = param1;
         this.beamType = param2;
         this.length = param3;
      }
   }
}

