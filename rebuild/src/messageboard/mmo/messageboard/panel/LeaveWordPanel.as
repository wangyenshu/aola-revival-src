package mmo.messageboard.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DateUtil;
   import mmo.common.Text;
   import mmo.common.dialog.NewDialog;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.words.InputChecker;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.user.IUserNameManager;
   import mmo.messageboard.client.MessageBoardClient;
   import mmo.messageboard.data.MessageBoardData;
   
   public class LeaveWordPanel extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var btn_leaveword:SimpleButton;
      
      public var btn_quickword:SimpleButton;
      
      public var container:MovieClip;
      
      public var mc1:MovieClip;
      
      public var mc2:MovieClip;
      
      public var mc3:MovieClip;
      
      public var mc4:MovieClip;
      
      public var mc5:MovieClip;
      
      public var mc6:MovieClip;
      
      public var scratch1:MovieClip;
      
      public var scratch2:MovieClip;
      
      public var scratch3:MovieClip;
      
      public var scratch4:MovieClip;
      
      public var scratch5:MovieClip;
      
      public var scratch6:MovieClip;
      
      private var leaveWordContainer:Sprite;
      
      private var inputPanel:ScratchpadInputPanel;
      
      private var currentScratchpad:int = 1;
      
      private var scratchpadNum:int = 6;
      
      private const defaultWord:String = "将你想说的话写在这里吧 ^_^";
      
      private var userName:String;
      
      private var onClose:Function;
      
      private var userNameManager:IUserNameManager;
      
      public function LeaveWordPanel(param1:String, param2:Function)
      {
         super();
         this.userName = param1;
         this.onClose = param2;
         this.init();
         this.initListener();
      }
      
      private function init() : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:MovieClip = null;
         this.leaveWordContainer = Sprite(this.container);
         var _loc1_:int = 1;
         while(_loc1_ <= this.scratchpadNum)
         {
            _loc2_ = this.getChildByName("scratch" + _loc1_) as Sprite;
            _loc2_.mouseEnabled = false;
            _loc3_ = this.getChildByName("mc" + _loc1_) as MovieClip;
            _loc3_.addEventListener(MouseEvent.CLICK,this.onClickScratchpad);
            TipsManager.getInstance().addTips(_loc3_,"要将留言写在这张便签贴上么？");
            _loc1_++;
         }
         this.userNameManager = ServiceContainer.getService(IUserNameManager) as IUserNameManager;
         this.currentScratchpad = int(Math.random() * this.scratchpadNum) + 1;
         MovieClip(this.getChildByName("mc" + this.currentScratchpad)).gotoAndStop(2);
         this.addScratchpadToContainer(this.currentScratchpad,"");
      }
      
      private function initListener() : void
      {
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         SimpleButton(this.btn_leaveword).addEventListener(MouseEvent.CLICK,this.onClickLeaveWord);
         SimpleButton(this.btn_quickword).addEventListener(MouseEvent.CLICK,this.onClickQuickWord);
      }
      
      private function addScratchpadToContainer(param1:int, param2:String) : void
      {
         while(this.leaveWordContainer.numChildren > 0)
         {
            this.leaveWordContainer.removeChildAt(0);
         }
         this.inputPanel = new ScratchpadInputPanel(param1,param2,this.defaultWord);
         this.leaveWordContainer.addChild(this.inputPanel);
      }
      
      private function onClickScratchpad(param1:MouseEvent) : void
      {
         var _loc6_:String = null;
         var _loc2_:DisplayObject = param1.currentTarget as DisplayObject;
         var _loc3_:String = _loc2_.name;
         var _loc4_:String = "mc";
         var _loc5_:int = parseInt(_loc3_.slice(_loc4_.length));
         if(_loc5_ != this.currentScratchpad)
         {
            MovieClip(this.getChildByName("mc" + this.currentScratchpad)).gotoAndStop(1);
            MovieClip(this.getChildByName("mc" + _loc5_)).gotoAndStop(2);
            this.currentScratchpad = _loc5_;
            _loc6_ = Text.trim(this.inputPanel.getText());
            this.addScratchpadToContainer(_loc5_,_loc6_);
         }
      }
      
      private function onClickLeaveWord(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         tryLeaveWord();
      }
      
      private function tryLeaveWord() : void
      {
         var txt:String = null;
         txt = this.inputPanel.getText();
         if(Text.trim(txt) == "" || txt.indexOf(this.defaultWord) != -1)
         {
            NewDialog.showFailMessage("你还没有输入留言哦！");
            return;
         }
         if(txt.length > 26)
         {
            NewDialog.showFailMessage("不能超过26个字符哦");
            return;
         }
         leaveWord(txt);
      }
      
      private function leaveWord(param1:String) : void
      {
         var _loc2_:int = int(InputChecker.check(param1,[InputChecker.RESULT_BAN,InputChecker.RESULT_RUMOR]));
         if(_loc2_ == InputChecker.RESULT_OK)
         {
            SocketClient.instance.addEventListener(MessageBoardClient.cmdLeaveMsg,this.onLeaveMsg);
            MessageBoardClient.getInstance().leaveMessage(this.userName,param1,this.currentScratchpad);
         }
         else if(_loc2_ == InputChecker.RESULT_BAN)
         {
            NewDialog.showFailMessage("很抱歉，由于你多次使用非法语言，已被禁言。\n文明言行，共同关爱大家的奥拉星！");
         }
         else
         {
            NewDialog.showFailMessage("请不要使用非法语言");
         }
      }
      
      private function onLeaveMsg(param1:SocketClientEvent) : void
      {
         var _loc2_:Date = null;
         var _loc3_:MessageBoardData = null;
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdLeaveMsg,this.onLeaveMsg);
         if(param1.params.suc)
         {
            ModalDialogManager.getInstance().removeModalDialog(this);
            if(this.onClose != null)
            {
               _loc2_ = DateUtil.getServerTime();
               _loc3_ = new MessageBoardData(param1.params.id,this.currentScratchpad,this.inputPanel.getText(),UserInfo.userName,this.userNameManager.getNickName(UserInfo.userName),_loc2_.month + 1,_loc2_.date);
               this.onClose.apply(null,[true,_loc3_]);
            }
         }
         else
         {
            NewDialog.showFailMessage("你今天已经给很多朋友留言过了，明天再来留言吧！");
         }
      }
      
      private function onClickQuickWord(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         var target:SimpleButton = evt.currentTarget as SimpleButton;
         var quickTalkPanel:QuickTalkPanel = new QuickTalkPanel(function(param1:String):void
         {
            if(param1 != null)
            {
               inputPanel.setText(param1);
            }
         });
         quickTalkPanel.x = target.x;
         quickTalkPanel.y = target.y;
         this.addChild(quickTalkPanel);
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         if(this.onClose != null)
         {
            this.onClose.apply(null,[false,null]);
         }
      }
      
      private function dispose() : void
      {
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdLeaveMsg,this.onLeaveMsg);
      }
   }
}

