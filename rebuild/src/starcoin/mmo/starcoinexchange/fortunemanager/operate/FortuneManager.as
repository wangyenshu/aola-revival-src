package mmo.starcoinexchange.fortunemanager.operate
{
   public class FortuneManager
   {
      
      private static var _instance:FortuneManager;
      
      private var fortuneArr:Array = new Array(5);
      
      public function FortuneManager()
      {
         super();
         if(_instance != null)
         {
            throw new Error("FortuneManager error");
         }
      }
      
      public static function getInstance() : FortuneManager
      {
         if(_instance == null)
         {
            _instance = new FortuneManager();
         }
         return _instance;
      }
      
      public function get myStoreFortune() : Array
      {
         return this.fortuneArr;
      }
      
      public function set myStoreFortune(param1:Array) : void
      {
         this.fortuneArr = param1;
      }
      
      public function clearFortuneArr() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < 5)
         {
            this.fortuneArr[_loc1_] = null;
            _loc1_++;
         }
      }
      
      public function returnMyStore(param1:int) : void
      {
         if(this.fortuneArr[param1] != null)
         {
            this.fortuneArr[param1] = null;
            return;
         }
         throw new Error("error:This store fortune is not exit!");
      }
      
      public function storeFortune(param1:int, param2:Object) : void
      {
         if(this.fortuneArr[param1] == null)
         {
            this.fortuneArr[param1] = param2;
            return;
         }
         throw new Error("rror:This store fortune is exit!");
      }
      
      public function storeFortuneOfMes(param1:int, param2:int, param3:Date, param4:int) : void
      {
         var _loc5_:Object = new Object();
         var _loc6_:Date = new Date(param3.fullYear,param3.month,param3.date + param4,param3.hours,param3.minutes,param3.seconds);
         _loc5_["money"] = param2;
         _loc5_["storeDate"] = param3;
         _loc5_["endDate"] = _loc6_;
         _loc5_["day"] = param4;
         this.storeFortune(param1,_loc5_);
      }
      
      public function checkForEmptyStore() : Boolean
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.fortuneArr.length)
         {
            if(this.fortuneArr[_loc1_] != null)
            {
               return false;
            }
            _loc1_++;
         }
         return true;
      }
   }
}

