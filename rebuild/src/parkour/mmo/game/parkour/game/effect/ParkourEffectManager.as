package mmo.game.parkour.game.effect
{
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   
   public class ParkourEffectManager
   {
      
      private var propEffects:Array = [];
      
      public function ParkourEffectManager()
      {
         super();
      }
      
      private function getEffctByClass(param1:Class) : IParkourEffect
      {
         var _loc2_:IParkourEffect = null;
         for each(_loc2_ in this.propEffects)
         {
            if(_loc2_ is param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public function runEffectCount() : void
      {
         var _loc1_:IParkourEffect = null;
         for each(_loc1_ in this.propEffects)
         {
            _loc1_.run();
         }
      }
      
      public function excuteEffect(param1:Class, param2:Object) : void
      {
         var _loc3_:IParkourEffect = this.getEffctByClass(param1);
         if(_loc3_ == null)
         {
            _loc3_ = new param1() as IParkourEffect;
            if(_loc3_.excute(param2))
            {
               this.propEffects.push(_loc3_);
            }
         }
         else
         {
            _loc3_.reset(param2);
         }
      }
      
      public function checkDispose() : void
      {
         var _loc2_:IParkourEffect = null;
         var _loc1_:* = int(this.propEffects.length - 1);
         while(_loc1_ >= 0)
         {
            _loc2_ = this.propEffects[_loc1_] as IParkourEffect;
            if(_loc2_.canDispose())
            {
               _loc2_.dispose();
               this.propEffects.splice(_loc1_,1);
            }
            _loc1_--;
         }
      }
      
      public function stopAndDelEffect(param1:Class) : void
      {
         var _loc3_:IParkourEffect = null;
         var _loc2_:* = int(this.propEffects.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = this.propEffects[_loc2_] as IParkourEffect;
            if(_loc3_ is param1)
            {
               _loc3_.dispose();
               this.propEffects.splice(_loc2_,1);
            }
            _loc2_--;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:IParkourEffect = null;
         for each(_loc1_ in this.propEffects)
         {
            _loc1_.dispose();
         }
         this.propEffects = [];
      }
   }
}

