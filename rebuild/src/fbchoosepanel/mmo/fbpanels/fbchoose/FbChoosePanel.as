package mmo.fbpanels.fbchoose
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbpanels.fbchoose.sweep.FbSweepConfirm;
   import mmo.fbpanels.fbchoose.sweep.FbSweepEndPanel;
   import mmo.fbpanels.fbchoose.sweep.FbSweepNoMemberLevel;
   import mmo.fbpanels.fbchoose.sweep.FbSweepRefuseTeam;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fb.FbID;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.fbteam.IFBLoaderService;
   import mmo.interfaces.team.ITeamService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   
   /**
    * LATER fbservice/fbchoosepanel (2016) on the 2013 libraries (aola-revival):
    * the 四大副本's entry panel, its three modes (简单, 困难, 传奇), the entries
    * left today and the best rating of each mode. Changed: the 扫荡 (sweep,
    * a later feature with a later FbClient command and 蓝宝 honour levels) is
    * hidden; the daily entries are MAX_TIMES (FbID.getMaxEnterTimes is later).
    */
   public class FbChoosePanel extends Sprite implements IShowDataPanel
   {
      /** Entries a day (RECONSTRUCTED; the later FbID.getMaxEnterTimes is not in the 2013 library). */
      public static const MAX_TIMES:int = 5;

      
      public var container:MovieClip;
      
      public var btnGo:SimpleButton;
      
      public var btnClose:SimpleButton;
      
      public var mctips:MovieClip;
      
      public var txttimes:TextField;
      
      public var mcfirstget:MovieClip;
      
      public var btnbuytime:SimpleButton;
      
      public var detailmc:MovieClip;
      
      public var mcselect_2:MovieClip;
      
      public var mcstate:MovieClip;
      
      public var btnSweep:SimpleButton;
      
      public var mcselect_1:MovieClip;
      
      public var mcselect_0:MovieClip;
      
      private var _fbId:int;
      
      private var _leftT:int;
      
      private var _buyTimes:int;
      
      private var _myAward:String;
      
      private var _diff:int;
      
      public function FbChoosePanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         if(this.btnSweep != null)
         {
            this.btnSweep.visible = false;
         }
         this.addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         switch(param1.target.name)
         {
            case "btnClose":
               this.close();
               break;
            case "btnGo":
               this.startJoinFb();
               break;
            case "btnbuytime":
               this.showBuy();
               break;
            case "btnSweep":
               this.checkCanSweep();
               break;
            case "btnselect":
               _loc2_ = int(param1.target.parent.name.split("_")[1]);
               this._diff = _loc2_;
               this.setDiff();
               break;
            case "btngoscene":
         }
      }
      
      private function checkCanSweep() : void
      {
      }

      private function startJoinFb(param1:int = 1) : void
      {
         var _loc2_:IFBLoaderService = ServiceContainer.getService(IFBLoaderService) as IFBLoaderService;
         _loc2_.addEventListener(FbEvent.ENTER_FB,this.onJoinFb);
         _loc2_.joinFb(this._fbId,FbID.getFbNameById(this._fbId),this._diff,{"sceneNum":param1});
      }
      
      private function onJoinFb(param1:FbEvent) : void
      {
         (param1.target as EventDispatcher).removeEventListener(FbEvent.ENTER_FB,this.onJoinFb);
         if(param1.param.succ)
         {
            this.close();
         }
         if(!param1.param.succ)
         {
            if(this._leftT <= 0)
            {
               this.showBuy();
               return;
            }
            if(param1.param.nn != null)
            {
               NewDialog.showFailMessage("玩家#" + param1.param.nn + "#已经没有进入次数了！不能一起进入哦！");
            }
            else
            {
               NewDialog.showFailMessage("进入失败！");
            }
         }
      }
      
      private function showBuy() : void
      {
         var _loc1_:IFbService = ServiceContainer.getService(IFbService) as IFbService;
         Object(_loc1_).showBuyTimePanel(this._fbId,this.afterBuyT,this._buyTimes);
      }
      
      private function afterBuyT() : void
      {
         ++this._leftT;
         ++this._buyTimes;
         this.setTxt();
      }
      
      public function showPanelByData(param1:Object) : void
      {
         this._fbId = param1.id;
         this.loadRes();
      }
      
      private function loadRes() : void
      {
         SimpleCustomLoader.loadSingleResource(FbChooseResConfig.BackGroundRes[this._fbId][0],FbChooseResConfig.BackGroundRes[this._fbId][1],LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"加载中，请稍候……",function(param1:MovieClip):void
         {
            while(container.numChildren > 0)
            {
               container.removeChildAt(0);
            }
            container.addChild(param1);
            getInfo();
         });
      }
      
      private function getInfo() : void
      {
         var ser:IFbService = null;
         ProgressFullSprite.show();
         ser = ServiceContainer.getService(IFbService) as IFbService;
         ser.addEventListener("onGetPanelInfo",function onGetInfo(param1:FbEvent):void
         {
            ProgressFullSprite.close();
            ser.removeEventListener("onGetPanelInfo",onGetInfo);
            setFirstGet(param1.param.g);
            _leftT = param1.param.lt;
            _buyTimes = param1.param.bt;
            _myAward = param1.param.gr;
            setPanel();
            addPanel();
         });
         Object(ser).getPanelInfo(this._fbId);
      }
      
      private function addPanel() : void
      {
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function setPanel() : void
      {
         this.mctips.gotoAndStop(this._fbId + 1);
         this.setDiff();
         this.setTxt();
      }
      
      private function setDiff() : void
      {
         var _loc2_:MovieClip = null;
         this.detailmc.gotoAndStop(this._diff + 1);
         var award:String = String((this._myAward || "#;#;#").split(";")[this._diff] || "#");
         try
         {
            this.mcstate.gotoAndStop("_" + award);
         }
         catch(noLabel:Error)
         {
            this.mcstate.gotoAndStop(1);
         }
         var _loc1_:int = 0;
         while(_loc1_ < 3)
         {
            _loc2_ = this.getChildByName("mcselect_" + _loc1_) as MovieClip;
            _loc2_.gotoAndStop(this._diff == _loc1_ ? 2 : 1);
            _loc1_++;
         }
      }
      
      private function setTxt() : void
      {
         this.btnbuytime.visible = this._leftT < MAX_TIMES;
         this.txttimes.text = this._leftT + "/" + MAX_TIMES;
      }
      
      private function setFirstGet(param1:Boolean) : void
      {
         this.mcfirstget.visible = param1;
      }
      
      public function dispose() : void
      {
      }
   }
}

