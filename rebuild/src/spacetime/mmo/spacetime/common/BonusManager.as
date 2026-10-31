package mmo.spacetime.common
{
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.SpacetimeClient;
   import mmo.framework.comm.SpacetimeTClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class BonusManager
   {
      
      private static var _instance:BonusManager = null;
      
      private var bonus:Array = [];
      
      private var panelService:IMaterialGetPanel = null;
      
      public function BonusManager()
      {
         super();
      }
      
      public static function get instance() : BonusManager
      {
         if(null == _instance)
         {
            _instance = new BonusManager();
         }
         return _instance;
      }
      
      public function init() : void
      {
         this.panelService = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
         SocketClient.instance.addEventListener(SpacetimeClient.cmdGainEnemyBonus,this.onlistenEnemyBonus);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdGainEnemyBonus,this.onlistenEnemyBonus);
      }
      
      private function onlistenEnemyBonus(param1:SocketClientEvent) : void
      {
         this.bonus = param1.params.bonus;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onShowBonus);
      }
      
      private function onShowBonus(param1:PetFightEvent) : void
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onShowBonus);
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < this.bonus.length)
         {
            _loc5_ = int(this.bonus[_loc4_].id);
            if(-1 == _loc5_)
            {
               _loc6_ = int(this.bonus[_loc4_].type);
               if(_loc6_ == 101)
               {
                  _loc3_ = int(this.bonus[_loc4_].num);
               }
               else if(_loc6_ == 100)
               {
                  _loc2_ = int(this.bonus[_loc4_].num);
               }
            }
            else
            {
               this.panelService.showTips(this.bonus[_loc4_].type,this.bonus[_loc4_].id,this.bonus[_loc4_].num);
            }
            _loc4_++;
         }
         if(_loc2_ != 0 && _loc3_ != 0)
         {
            this.panelService.showGetMoneyAndExpPanel(_loc2_,_loc3_);
         }
         else if(_loc2_ != 0)
         {
            this.panelService.showGettedMoneyPanel(_loc2_);
         }
         else if(_loc3_ != 0)
         {
            this.panelService.showGettedExpPanel(_loc3_);
         }
      }
   }
}

