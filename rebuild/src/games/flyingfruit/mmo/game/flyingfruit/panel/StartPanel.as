package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.flyingfruit.FlyingFruitManager;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.loader.SimpleCLParam;
   import mmo.loader.SimpleCLLoader;
   
   public class StartPanel extends MovieClip
   {
      
      public var icon:MovieClip;
      
      public var txtnum:TextField;
      
      public var btnexchange:SimpleButton;
      
      public var mTips_2_2298:MovieClip;
      
      public var btnClose:SimpleButton;
      
      public var btnStart:SimpleButton;
      
      public function StartPanel()
      {
         super();
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         // REVIVAL: the later praise-and-feedback stamp and material tips (later services) left out.
         SundriesClient.logEvent(16712);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:ITeamService = null;
         switch(param1.target.name)
         {
            case "btnClose":
               DisplayUtil.stopAndRemove(this);
               FlyingFruitManager.instance.disposeGame();
               break;
            case "btnStart":
               SundriesClient.logButton(467);
               _loc2_ = ServiceContainer.getService(ITeamService) as ITeamService;
               if(_loc2_.getMyTeam() != null)
               {
                  NewDialog.showFailMessage("组队状态不能进行此游戏哦！");
                  return;
               }
               _loc2_.refuseInvite(true);
               DisplayUtil.stopAndRemove(this);
               FlyingFruitManager.instance.startGame();
               break;
            case "btnexchange":
               this.onExchange();
         }
      }
      
      private function refuse() : void
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         _loc1_.refuseInvite(true);
      }
      
      private function onExchange() : void
      {
         var url:String = "vip/bluehonor/bluehonorexchange";
         var cls:String = "mmo.vip.bluehonorexchange.panel.BlueHonorExchange";
         SimpleCLLoader.loadSingleRes(SimpleCLParam.create(url,cls,function(param1:IShowPanel, param2:ApplicationDomain):void
         {
            param1.showPanel();
         }));
      }
      
      public function setYabizhiHun(param1:int) : void
      {
         var _loc2_:TextField = this.getChildByName("txtnum") as TextField;
         _loc2_.text = param1 + "/20";
      }
   }
}

