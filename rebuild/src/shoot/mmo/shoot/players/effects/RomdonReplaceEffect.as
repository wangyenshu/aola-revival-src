package mmo.shoot.players.effects
{
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class RomdonReplaceEffect extends PlayerEffectBase
   {
      
      private var selectedEffect:PlayerEffectBase;
      
      public function RomdonReplaceEffect(param1:PlayerBase, param2:Object)
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
         var _loc1_:Array = [29978,29979,29980];
         var _loc2_:Array = [35,55,100];
         var _loc3_:int = int(Math.random() * 100);
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         while(_loc5_ < _loc2_.length)
         {
            if(_loc3_ <= _loc2_[_loc5_])
            {
               _loc4_ = _loc5_;
               break;
            }
            _loc5_++;
         }
         return new ReplaceEffect(this.player,{
            "clothes":_loc1_[_loc4_],
            "targetEffect":0
         });
      }
      
      override public function get excludeKey() : String
      {
         return "RomdonReplaceEffect";
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

