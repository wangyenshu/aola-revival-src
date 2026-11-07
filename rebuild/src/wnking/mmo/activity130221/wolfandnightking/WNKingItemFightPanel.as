package mmo.activity130221.wolfandnightking
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.loader.scheduler.ResScheduler;
   
   public class WNKingItemFightPanel extends WNKingPanelBase
   {
      
      private static const PANELEVENTIDS:Array = [4148,4149];
      
      private var index:int;
      
      private var id:int;
      
      private var panel:Sprite;
      
      private var btnReturnHide:Boolean = false;
      
      public function WNKingItemFightPanel(param1:int, param2:int, param3:Boolean)
      {
         super();
         this.index = param1;
         this.id = param2;
         this.btnReturnHide = param3;
         this.initPanel();
      }
      
      private function initPanel() : void
      {
         var arr:Array = WNKingConfig.challengeItemFightArr[this.index];
         var obj:Object = arr[this.id];
         ResScheduler.getTempResource(obj.pathName,function(param1:Sprite, param2:Object = null):void
         {
            panel = param1;
            if(id == 0)
            {
               getStarState();
            }
            else
            {
               addChild(panel);
            }
         },obj.className);
      }
      
      private function getStarState() : void
      {
         SocketClient.instance.addEventListener("nwk0219-2",this.onState);
         SocketClient.instance.sendXtMessage("HolidayExtension","nwk0219-2",{"type":1 - this.index});
      }
      
      private function onState(param1:SocketClientEvent) : void
      {
         var _loc4_:Sprite = null;
         this.addChild(this.panel);
         SocketClient.instance.removeEventListener("nwk0219-2",this.onState);
         var _loc2_:int = int(param1.params.cnt);
         var _loc3_:int = 0;
         while(_loc3_ < 3)
         {
            _loc4_ = this.panel.getChildByName("spStar" + _loc3_.toString()) as Sprite;
            if(_loc2_ <= _loc3_)
            {
               DisplayUtil.applyGray(_loc4_);
            }
            _loc3_++;
         }
      }
      
      override protected function clickBtn(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         var name:String = evt.target.name as String;
         switch(name)
         {
            case "btnClose":
               this.closePanel();
               break;
            case "btnReturn":
               this.closePanel();
               new WNKingChallengePanel(this.index).showPanel();
               break;
            case "btnCure":
            case "btncure":
               this.tryCure();
               break;
            case "btnTips":
               this.showTipsPanel();
               break;
            case "btnFight":
               this.tryFight();
               break;
            case "btnpackage":
               WNKingPets.openPetPackage();
               break;
            case "btnstore":
               WNKingPets.tryOpenPetStore();
         }
      }
      
      private function tryFight() : void
      {
         new WNKingFightHandler(1 - this.index,this.id,this.showBonus,this.showBonus).handleFight();
         SundriesClient.logEvent(4147);
         SundriesClient.logEvent(PANELEVENTIDS[this.index]);
      }
      
      private function showBonus() : void
      {
         var _loc5_:IMaterialGetPanel = null;
         var _loc1_:Array = WNKingConfig.challengeItemIdArr[this.index];
         var _loc2_:int = int(_loc1_[this.id]);
         var _loc3_:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         var _loc4_:UserItem = _loc3_.getMyItemById(_loc2_);
         if(_loc4_ != null && _loc4_.quantity > 0)
         {
            new WNKingChallengePanel(this.index,this.btnReturnHide).showPanel();
            _loc5_ = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
            _loc5_.showPanel(MaterialTypes.ITEM,_loc2_,1);
         }
         else
         {
            new WNKingItemFightPanel(this.index,this.id,this.btnReturnHide).showPanel();
         }
      }
      
      private function showTipsPanel() : void
      {
         new WNKingChallengeTipsPanel(this.index,this.id + 1).showPanel();
      }
      
      private function tryCure() : void
      {
         var _loc1_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         if(_loc1_.checkPetIsEmpty())
         {
            NewDialog.showMessage("你的背包里没有亚比哦！");
            return;
         }
         if(Boolean(_loc1_.checkAllPetHPIsFull()) && Boolean(_loc1_.checkAllPetPPIsFull()))
         {
            NewDialog.showMessage("你背包里的亚比已经充满活力，不需要治疗哦！");
            return;
         }
         _loc1_.recureAllPet();
      }
   }
}

