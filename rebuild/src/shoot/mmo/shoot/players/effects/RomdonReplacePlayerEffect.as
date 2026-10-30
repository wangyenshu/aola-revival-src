package mmo.shoot.players.effects
{
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class RomdonReplacePlayerEffect extends PlayerEffectBase
   {
      
      private var selectedEffect:PlayerEffectBase;
      
      public function RomdonReplacePlayerEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.selectedEffect = this.setRomdonEffect();
         this.selectedEffect.apply();
      }
      
      public function setRomdonEffect() : PlayerEffectBase
      {
         var _loc1_:Array = params.toString().split(";");
         var _loc2_:Array = _loc1_[0].toString().split(",");
         var _loc3_:Array = _loc1_[1].toString().split(",");
         var _loc4_:int = int(Math.random() * 100);
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         while(_loc6_ < _loc3_.length)
         {
            if(_loc4_ <= _loc3_[_loc6_])
            {
               _loc5_ = _loc6_;
               break;
            }
            _loc6_++;
         }
         return new ReplaceEffect(this.player,{
            "clothes":_loc2_[_loc5_],
            "targetEffect":0
         });
      }
      
      override public function get excludeKey() : String
      {
         return "RomdonReplacePlayerEffect";
      }
      
      override public function clear() : void
      {
         if(this.selectedEffect != null)
         {
            this.selectedEffect.dispose();
         }
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

