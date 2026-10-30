package mmo.shoot.effect.beam
{
   import flash.geom.Point;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class BeamDisplayerFactory
   {
      
      public function BeamDisplayerFactory()
      {
         super();
      }
      
      public static function getDisplayer(param1:PlayerBase, param2:Point, param3:BeamInfo, param4:IShootEffectTarget, param5:int) : BeamDisplayerBase
      {
         switch(param3.beamType)
         {
            case BeamInfo.BEAM_TYPE_DOUBLE_MOVIE:
               return new DoubleMoveDisplayer(param1,param2,param3,param4,param5);
            case BeamInfo.BEAM_TYPE_MOVIECLIP:
               return new MovieClipDisplayer(param1,param2,param3,param4,param5);
            case BeamInfo.BEAM_TYPE_COLLECT_MOVIE:
               return new CollectMoveDisplayer(param1,param2,param3,param4,param5);
            default:
               return null;
         }
      }
   }
}

