package mmo.shoot.players.effects
{
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class CompositeEffect extends PlayerEffectBase
   {
      
      private var playerEffectArray:Array = [];
      
      public function CompositeEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
         this.init();
      }
      
      private function init() : void
      {
         var _loc2_:String = null;
         var _loc3_:PlayerEffectBase = null;
         var _loc1_:Array = this.parse(this.params["compositeEffect"].toString());
         for each(_loc2_ in _loc1_)
         {
            _loc3_ = EffectFactory.getSingleEffect(this.player,int(_loc2_));
            this.playerEffectArray.push(_loc3_);
         }
      }
      
      private function parse(param1:String) : Array
      {
         return param1.split("_");
      }
      
      override public function apply() : void
      {
         var _loc1_:PlayerEffectBase = null;
         for each(_loc1_ in this.playerEffectArray)
         {
            _loc1_.apply();
         }
      }
      
      override public function get excludeKey() : String
      {
         return "CompositeEffect_" + this.params["targetEffect"].toString();
      }
      
      override public function dispose() : void
      {
         var _loc1_:PlayerEffectBase = null;
         for each(_loc1_ in this.playerEffectArray)
         {
            _loc1_.clear();
         }
         super.dispose();
      }
   }
}

