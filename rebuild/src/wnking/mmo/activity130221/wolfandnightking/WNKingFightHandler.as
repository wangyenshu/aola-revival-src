package mmo.activity130221.wolfandnightking
{
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.team.ITeamService;
   
   public class WNKingFightHandler
   {
      
      private var index:int;
      
      private var id:int;
      
      private var winCallBack:Function;
      
      private var failCallBack:Function;
      
      public function WNKingFightHandler(param1:int, param2:int, param3:Function = null, param4:Function = null)
      {
         super();
         this.index = param1;
         this.id = param2;
         this.winCallBack = param3;
         this.failCallBack = param4;
      }
      
      public function handleFight() : void
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         if(_loc1_.getMyTeam() != null)
         {
            NewDialog.showMessage("组队状态下不能挑战哦！");
            return;
         }
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.enterFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.startFight(99,false,{
            "handler":"holiday.NWKChallenge",
            "t":this.index,
            "id":this.id
         });
      }
      
      private function enterFail(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.enterFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
      }
      
      private function fightEnd(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.enterFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         if(param1.isWin)
         {
            if(this.winCallBack != null)
            {
               this.winCallBack.apply();
            }
         }
         else if(this.failCallBack != null)
         {
            this.failCallBack.apply();
         }
      }
   }
}

