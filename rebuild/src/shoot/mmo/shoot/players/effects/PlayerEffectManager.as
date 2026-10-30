package mmo.shoot.players.effects
{
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class PlayerEffectManager
   {
      
      public static const instance:PlayerEffectManager = new PlayerEffectManager();
      
      private static const EffectPropertyKey:String = "shootEffecs";
      
      public function PlayerEffectManager()
      {
         super();
      }
      
      public function applyEffect(param1:PlayerBase, param2:int) : void
      {
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc8_:PlayerEffectBase = null;
         var _loc3_:Object = param1.getProperty(EffectPropertyKey);
         if(_loc3_ == null)
         {
            _loc3_ = {};
         }
         var _loc4_:PlayerEffectBase = EffectFactory.getEffect(param1,param2);
         if(_loc4_ == null)
         {
            return; // REBUILT: an effect this client has no picture for (the later code assumed every one known)
         }
         var _loc5_:Array = [];
         for(_loc6_ in _loc3_)
         {
            _loc8_ = _loc3_[_loc6_];
            if(_loc8_.excludeKey == _loc4_.excludeKey)
            {
               _loc5_.push(_loc6_);
               _loc8_.dispose();
            }
         }
         for each(_loc7_ in _loc5_)
         {
            delete _loc3_[_loc7_];
         }
         _loc4_.apply();
         _loc3_[param2.toString()] = _loc4_;
         param1.setProperty(EffectPropertyKey,_loc3_);
      }
      
      public function clearEffect(param1:PlayerBase, param2:int) : void
      {
         var _loc4_:PlayerEffectBase = null;
         var _loc3_:Object = param1.getProperty(EffectPropertyKey);
         if(_loc3_ != null && _loc3_.hasOwnProperty(param2))
         {
            _loc4_ = _loc3_[param2] as PlayerEffectBase;
            _loc4_.dispose();
            delete _loc3_[param2];
         }
         param1.setProperty(EffectPropertyKey,_loc3_);
      }
      
      public function clearAllEffect(param1:PlayerBase) : void
      {
         var _loc3_:PlayerEffectBase = null;
         var _loc2_:Object = param1.getProperty(EffectPropertyKey);
         if(_loc2_ == null)
         {
            return;
         }
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_ != null)
            {
               _loc3_.dispose();
            }
         }
         param1.setProperty(EffectPropertyKey,null);
      }
   }
}

