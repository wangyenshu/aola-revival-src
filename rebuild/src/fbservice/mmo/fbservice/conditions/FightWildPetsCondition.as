package mmo.fbservice.conditions
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IClearCondition;
   import mmo.interfaces.fb.IFbService;
   
   public class FightWildPetsCondition implements IClearCondition
   {
      
      private var context:Object;
      
      private var callback:Function;
      
      private var pets:Array;
      
      private var killall:Boolean;
      
      private var killpet:Array = [];
      
      private var fbservice:IFbService;
      
      public function FightWildPetsCondition(param1:Array, param2:Function, param3:Object, param4:Boolean = false)
      {
         super();
         this.callback = param2;
         this.pets = param1;
         this.context = param3;
         this.killall = param4;
      }
      
      public function handleFbEvent(param1:Object) : Boolean
      {
         var _loc2_:Boolean = false;
         if(!(param1 is int) || this.pets == null)
         {
            return _loc2_;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.pets.length)
         {
            if(this.pets[_loc3_] == param1)
            {
               this.pets.splice(_loc3_,1);
               this.killpet.push(param1);
               _loc2_ = true;
               break;
            }
            _loc3_++;
         }
         if(this.isClear)
         {
            this.callback.apply(this.context,[]);
         }
         return _loc2_;
      }
      
      public function hasPet(param1:int) : Boolean
      {
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         while(_loc3_ < this.pets.length)
         {
            if(this.pets[_loc3_] == param1)
            {
               _loc2_ = true;
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function handleResetPet() : void
      {
         this.fbservice = ServiceContainer.getService(IFbService) as IFbService;
         var _loc1_:* = 0;
         while(_loc1_ < this.killpet.length)
         {
            this.pets.push(this.killpet[_loc1_]);
            _loc1_++;
         }
         this.fbservice.addCurrentWildPets(this.killpet);
         this.killpet = [];
         this.fbservice = null;
      }
      
      public function get isClear() : Boolean
      {
         return this.pets == null || this.pets.length == 0;
      }
      
      public function get isKillAll() : Boolean
      {
         return this.killall;
      }
   }
}

