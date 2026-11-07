package mmo.activity130221.wolfandnightking
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * One king's panel (index 0 狼王, 1 夜王): the three 剑魂 / 封印 won in its trials, 星币力量,
    * and 召唤 once all three are got (SynthesizeExtension 57_8, ids 337 and 367).
    * The surviving copy (2016) is cut back to January 2013's: its 至尊秘籍 (the third frame of
    * buyorsuper), 快速挑战, 领取夜王, buff view, 星钻 task and the 2014 scene link (btngo) are
    * later additions and are left out.
    */
   public class WNKingChallengePanel extends WNKingPanelBase
   {
      private static const EGGEVENTIDS:Array = [4159, 4163];
      private static const PANLEEVENTIDS:Array = [4145, 4146];

      private var index:int;
      private var panel:Sprite;
      private var isEnoughItem:Boolean = false;
      private var isCall:Boolean = false;
      private var btnReturnHide:Boolean = false;
      private var btngBuyOrSuper:MovieClip;

      public function WNKingChallengePanel(index:int, btnReturnHide:Boolean = true)
      {
         super();
         this.index = index;
         this.btnReturnHide = btnReturnHide;
         this.getState();
      }

      private function getState():void
      {
         SocketClient.instance.addEventListener("nwk0219-1", this.onGetState);
         SocketClient.instance.sendXtMessage("HolidayExtension", "nwk0219-1", {});
      }

      private function onGetState(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener("nwk0219-1", this.onGetState);
         this.isCall = Boolean(e.params["got" + (1 - this.index).toString()]);
         this.initPanel();
      }

      private function initPanel():void
      {
         var obj:Object = WNKingConfig.challengePanelArr[this.index];
         ProgressFullSprite.show();
         ResScheduler.getTempResource(obj.pathName, function(res:Sprite, params:Object = null):void
         {
            ProgressFullSprite.close();
            panel = res;
            addChild(panel);
            var call:Sprite = panel.getChildByName("spCall") as Sprite;
            call.visible = isCall;
            SimpleButton(panel["btnReturn"]).visible = !btnReturnHide;
            var go:SimpleButton = panel.getChildByName("btngo") as SimpleButton;
            if (go) go.visible = false;
            btngBuyOrSuper = panel.getChildByName("buyorsuper") as MovieClip;
            updateItemState();
         }, obj.className);
         SundriesClient.logEvent(PANLEEVENTIDS[this.index]);
      }

      private function updateItemState():void
      {
         this.isEnoughItem = true;
         var ids:Array = WNKingConfig.challengeItemIdArr[this.index];
         var items:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         for (var i:int = 0; i < ids.length; i++)
         {
            var btn:SimpleButton = this.panel.getChildByName("btnItem" + i) as SimpleButton;
            var got:Sprite = this.panel.getChildByName("spGet" + i) as Sprite;
            var item:UserItem = items.getMyItemById(int(ids[i]));
            if (this.isCall || item != null && item.quantity != 0)
            {
               btn.mouseEnabled = false;
               got.visible = true;
            }
            else
            {
               this.isEnoughItem = false;
               got.visible = false;
            }
         }
         var call:SimpleButton = this.panel.getChildByName("btnCall") as SimpleButton;
         if (this.isEnoughItem)
         {
            if (this.isCall)
            {
               call.visible = false;
            }
            else
            {
               DisplayUtil.clearFilters(call);
               TipsManager.getInstance().removeTips(call);
            }
            // The second frame is empty (the third, 至尊秘籍, is later).
            this.btngBuyOrSuper.gotoAndStop(2);
         }
         else
         {
            DisplayUtil.applyGray(call);
            TipsManager.getInstance().addTips(call, WNKingConfig.challengeCallTipsArr[this.index]);
            this.btngBuyOrSuper.gotoAndStop(1);
         }
      }

      override protected function clickBtn(evt:MouseEvent):void
      {
         var name:String = evt.target.name as String;
         if (name == null || name == "")
         {
            return;
         }
         if (name == "btnClose")
         {
            this.closePanel();
         }
         else if (name == "btnReturn")
         {
            this.closePanel();
            new WNKingChallengeMainPanel().showPanel();
         }
         else if (name == "btnCure" || name == "btncure")
         {
            WNKingPets.tryCure();
         }
         else if (name == "btnCall" && this.isEnoughItem && !this.isCall)
         {
            this.tryCall();
         }
         else if (name == "btnStar")
         {
            SundriesClient.logOpen(WNKingConfig.challengeLogArr[this.index]);
            new WNKingStarPanel(this.index, this.updateItemState).showPanel();
         }
         else if (name.indexOf("btnItem") == 0)
         {
            this.showItemFightPanel(parseInt(name.substr(7)));
         }
         else if (name == "btnpackage")
         {
            WNKingPets.openPetPackage();
         }
         else if (name == "btnstore")
         {
            WNKingPets.tryOpenPetStore();
         }
      }

      private function showItemFightPanel(id:int):void
      {
         this.closePanel();
         new WNKingItemFightPanel(this.index, id, this.btnReturnHide).showPanel();
      }

      private function tryCall():void
      {
         var obj:Object = WNKingConfig.challengeCallMovieArr[this.index];
         ProgressFullSprite.show();
         ResScheduler.getTempResource(obj.pathName, function(mc:MovieClip, params:Object = null):void
         {
            var ended:Boolean = false;
            var onEnd:Function = function():void
            {
               if (ended) return;
               ended = true;
               mc.stop();
               ModalDialogManager.getInstance().removeModalDialog(mc);
               SimpleButton(panel.getChildByName("btnCall")).visible = false;
               Sprite(panel.getChildByName("spCall")).visible = true;
               goCall();
            };
            ProgressFullSprite.close();
            mc.addFrameScript(mc.totalFrames - 1, function():void
            {
               onEnd();
            });
            mc.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               if (e.target.name == "btnclose") onEnd();
            });
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc, AlignType.NONE);
            mc.gotoAndPlay(1);
         }, obj.className);
      }

      private function goCall():void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener("57_8", this.onCall);
         SocketClient.instance.sendXtMessage("SynthesizeExtension", "57_8", {
            "id": WNKingConfig.challengeCallIdArr[this.index],
            "num": 1
         });
      }

      private function onCall(e:SocketClientEvent):void
      {
         if (e.params.id != WNKingConfig.challengeCallIdArr[this.index])
         {
            return;
         }
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener("57_8", this.onCall);
         var get:IMaterialGetPanel = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
         get.showPanel(MaterialTypes.PET_EGG, WNKingConfig.challengePetIdArr[this.index], 1, this.afterCallSucc);
         SundriesClient.logEvent(EGGEVENTIDS[this.index]);
      }

      private function afterCallSucc():void
      {
         this.closePanel();
      }
   }
}
