package mmo.messageboard.panel
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TextEvent;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.Text;
   import mmo.common.dialog.NewDialog;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.words.InputChecker;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.LoaderContainer;
   import mmo.messageboard.client.MessageBoardClient;
   import mmo.messageboard.data.MessageBoardData;
   import mmo.messageboard.data.MessageCache;
   
   public class MessageBoardPanel extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var btnL:SimpleButton;
      
      public var btnR:SimpleButton;
      
      public var container:MovieClip;
      
      public var mcLeaveWord:MovieClip;
      
      public var mcMainWord:MovieClip;
      
      public var txtPage:TextField;
      
      public var txt_num:TextField;
      
      private var userName:String;
      
      private var isMaster:Boolean = false;
      
      private var reportNum:int;
      
      private var totalNum:int;
      
      private var currentPage:int = 1;
      
      private var currentPageNum:int;
      
      private var pageNum:int = 8;
      
      private var totalPage:int;
      
      private var maxItemNum:int = 100;
      
      private var txtMasterWord:TextField;
      
      private var mcMasterWord:MovieClip;
      
      private var editBtn:MovieClip;
      
      private var mainWord:String = "";
      
      private const defaultMainWord:String = "这家伙很懒，什么都没留下";
      
      private var scratchHeight:int = 160;
      
      private var scratchWidth:int = 165;
      
      private var scratchContainer:Sprite;
      
      public function MessageBoardPanel(param1:String)
      {
         super();
         this.userName = param1;
         this.init();
         this.initListener();
      }
      
      private function init() : void
      {
         this.isMaster = this.userName == UserInfo.userName ? true : false;
         this.scratchContainer = Sprite(this.container);
         this.mcMasterWord = MovieClip(this.mcMainWord);
         if(this.isMaster)
         {
            this.mcMasterWord.gotoAndStop(1);
            this.txtMasterWord = this.mcMasterWord.getChildByName("txt_word") as TextField;
            this.editBtn = this.mcMasterWord.getChildByName("Mc_edit") as MovieClip;
         }
         else
         {
            this.mcMasterWord.gotoAndStop(2);
            this.txtMasterWord = this.mcMasterWord.getChildByName("txt_word") as TextField;
         }
         SocketClient.instance.addEventListener(MessageBoardClient.cmdGetFirstPage,this.onGetFirstPage);
         MessageBoardClient.getInstance().getFirstPageMessage(this.userName);
      }
      
      private function onGetFirstPage(param1:SocketClientEvent) : void
      {
         var _loc5_:MessageBoardData = null;
         var _loc6_:MessageBoardData = null;
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdGetFirstPage,this.onGetFirstPage);
         this.mainWord = param1.params.main;
         this.reportNum = param1.params.msgCount;
         this.totalNum = param1.params.recordCount;
         if(this.mainWord == null || this.mainWord == "")
         {
            this.txtMasterWord.text = this.defaultMainWord;
         }
         else
         {
            this.txtMasterWord.text = this.mainWord;
         }
         var _loc2_:Array = param1.params.msg;
         var _loc3_:Array = new Array();
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc5_ = new MessageBoardData(_loc2_[_loc4_].id,_loc2_[_loc4_].type,_loc2_[_loc4_].content,_loc2_[_loc4_].dd,_loc2_[_loc4_].nn,_loc2_[_loc4_].month,_loc2_[_loc4_].day);
            _loc3_.push(_loc5_);
            _loc4_++;
         }
         if(this.totalNum <= 7)
         {
            ++this.totalNum;
            _loc6_ = new MessageBoardData(-1,6,"奥拉星是一个充满快乐、幸福的地方，希望你在这过得开心。",null,"小南姐姐",1,1);
            _loc3_.push(_loc6_);
         }
         MessageCache.getInstance().updateMessage(0,0,_loc3_);
         this.updatePanel();
      }
      
      private function initListener() : void
      {
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         if(this.isMaster)
         {
            this.editBtn.buttonMode = true;
            this.addTips(this.editBtn,"修改我的寄语");
            MovieClip(this.editBtn).addEventListener(MouseEvent.CLICK,this.onClickEdit);
            MovieClip(this.mcLeaveWord).buttonMode = true;
            MovieClip(this.mcLeaveWord).visible = false;
         }
         else
         {
            this.addTips(this.mcLeaveWord,"有话想对我说？赶快给我留言吧^_^");
            MovieClip(this.mcLeaveWord).addEventListener(MouseEvent.CLICK,this.onClickLeaveWord);
         }
         SimpleButton(this.btnL).addEventListener(MouseEvent.CLICK,this.onClickPrePage);
         SimpleButton(this.btnR).addEventListener(MouseEvent.CLICK,this.onClickNextPage);
      }
      
      private function onClickPrePage(param1:MouseEvent) : void
      {
         --this.currentPage;
         this.updatePanel();
      }
      
      private function onClickNextPage(param1:MouseEvent) : void
      {
         ++this.currentPage;
         this.updatePanel();
      }
      
      private function updatePanel() : void
      {
         this.totalNum = this.totalNum > this.maxItemNum ? this.maxItemNum : this.totalNum;
         this.totalPage = (this.totalNum - 1) / this.pageNum + 1;
         this.totalPage = this.totalPage == 0 ? 1 : this.totalPage;
         var _loc1_:Array = MessageCache.getInstance().getMessage((this.currentPage - 1) * this.pageNum,this.pageNum);
         this.currentPageNum = this.totalPage != this.currentPage ? this.pageNum : int((this.totalNum - 1) % this.pageNum + 1);
         if(_loc1_.length < this.pageNum && this.currentPageNum > _loc1_.length)
         {
            ProgressFullSprite.show();
            SocketClient.instance.addEventListener(MessageBoardClient.cmdGetPage,this.onGetPage);
            MessageBoardClient.getInstance().getPageMessage(this.userName,this.currentPage);
         }
         else
         {
            this.updatePageMessage();
            this.updateMessage(_loc1_,this.currentPageNum);
         }
      }
      
      private function onGetPage(param1:SocketClientEvent) : void
      {
         var _loc5_:MessageBoardData = null;
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdGetPage,this.onGetPage);
         var _loc2_:Array = param1.params.msg;
         var _loc3_:Array = new Array();
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc5_ = new MessageBoardData(_loc2_[_loc4_].id,_loc2_[_loc4_].type,_loc2_[_loc4_].content,_loc2_[_loc4_].dd,_loc2_[_loc4_].nn,_loc2_[_loc4_].month,_loc2_[_loc4_].day);
            _loc3_.push(_loc5_);
            _loc4_++;
         }
         MessageCache.getInstance().updateMessage((this.currentPage - 1) * this.pageNum,this.pageNum,_loc3_);
         if(this.currentPageNum != _loc3_.length)
         {
            this.totalNum = (this.currentPage - 1) * this.pageNum + _loc3_.length;
         }
         if(_loc3_.length == 0 && this.currentPage > 1)
         {
            --this.currentPage;
         }
         this.updatePanel();
         ProgressFullSprite.close();
      }
      
      private function updatePageMessage() : void
      {
         this.enableBtn(SimpleButton(this.btnL));
         this.enableBtn(SimpleButton(this.btnR));
         TextField(this.txtPage).text = this.currentPage + "/" + this.totalPage;
         if(this.reportNum >= this.totalNum)
         {
            TextField(this.txt_num).text = this.reportNum.toString();
         }
         else
         {
            TextField(this.txt_num).text = this.totalNum.toString();
         }
         if(this.currentPage == 1)
         {
            this.forbiddenBtn(SimpleButton(this.btnL),"已经是第一页了哦！");
         }
         if(this.totalPage <= this.currentPage)
         {
            this.forbiddenBtn(SimpleButton(this.btnR),"已经是最后一页了哦！");
         }
      }
      
      private function updateMessage(param1:Array, param2:int) : void
      {
         var rowNum:int;
         var showNum:int;
         var i:int;
         var messageBoardData:MessageBoardData = null;
         var tempPanel:ScratchpadPanel = null;
         var mes:Array = param1;
         var len:int = param2;
         while(this.scratchContainer.numChildren > 0)
         {
            this.scratchContainer.removeChildAt(0);
         }
         rowNum = 4;
         showNum = mes.length > len ? len : int(mes.length);
         i = 0;
         while(i < showNum)
         {
            messageBoardData = mes[i] as MessageBoardData;
            tempPanel = new ScratchpadPanel(messageBoardData.type,this.pageNum * (this.currentPage - 1) + i,this.userName,this.isMaster,function(param1:int):void
            {
               --totalNum;
               MessageCache.getInstance().deleteMessage(param1);
               if(totalNum > 0 && totalNum % pageNum == 0 && currentPage > totalNum / pageNum)
               {
                  --currentPage;
               }
               updatePanel();
            });
            tempPanel.setInfo(messageBoardData);
            tempPanel.x = this.scratchWidth * int(i % rowNum);
            tempPanel.y = this.scratchHeight * int(i / rowNum);
            this.scratchContainer.addChild(tempPanel);
            i++;
         }
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         this.dispose();
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function onClickLeaveWord(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().addModalDialog(new LeaveWordPanel(this.userName,this.closeLeaveWord),AlignType.NONE,PanelEffect.NONE,true,0,0);
      }
      
      private function closeLeaveWord(param1:Boolean, param2:MessageBoardData) : void
      {
         if(param1)
         {
            this.currentPage = 1;
            ++this.totalNum;
            MessageCache.getInstance().updateMessage(0,0,[param2]);
            this.updatePanel();
         }
      }
      
      private function onClickEdit(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         this.txtMasterWord.addEventListener(TextEvent.TEXT_INPUT,this.onChangeText);
         if(_loc2_.currentFrame == 1)
         {
            _loc2_.gotoAndStop(2);
            LoaderContainer.instance.stage.focus = this.txtMasterWord;
            this.setTextFieldEdit(this.txtMasterWord);
            this.addTips(_loc2_,"保存");
         }
         else
         {
            this.tryModifyMyMessage();
         }
      }
      
      private function tryModifyMyMessage() : void
      {
         if(Text.trim(this.txtMasterWord.text).length < 1)
         {
            NewDialog.showFailMessage("输入不能为空哦!");
            return;
         }
         if(this.txtMasterWord.text.length > 90)
         {
            NewDialog.showFailMessage("不能超过90个字符哦!");
            return;
         }
         this.modifyMyMessage();
      }
      
      private function modifyMyMessage() : void
      {
         var _loc1_:String = this.txtMasterWord.text;
         var _loc2_:int = int(InputChecker.check(_loc1_,[InputChecker.RESULT_BAD_WORD,InputChecker.RESULT_BAN,InputChecker.RESULT_RUMOR]));
         if(_loc2_ == InputChecker.RESULT_OK)
         {
            this.editBtn.gotoAndStop(1);
            this.setTextFieldUnedit(this.txtMasterWord);
            this.addTips(this.editBtn,"修改我的寄语");
            if(this.mainWord != _loc1_)
            {
               SocketClient.instance.addEventListener(MessageBoardClient.cmdModifiMyMessage,this.onModifimyMessage);
               MessageBoardClient.getInstance().modifiMyMessage(_loc1_);
            }
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
      
      private function onModifimyMessage(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdModifiMyMessage,this.onModifimyMessage);
         if(param1.params.suc)
         {
            this.mainWord = this.txtMasterWord.text;
         }
         else
         {
            this.txtMasterWord.text = this.mainWord;
            NewDialog.showFailMessage("请不要使用非法语言");
         }
      }
      
      private function setTextFieldEdit(param1:TextField) : void
      {
         param1.type = TextFieldType.INPUT;
         param1.selectable = true;
         param1.background = true;
         param1.backgroundColor = 16777215;
         param1.textColor = 39167;
         param1.mouseWheelEnabled = false;
         param1.scrollV = 0;
         param1.setSelection(0,param1.text.length);
      }
      
      private function setTextFieldUnedit(param1:TextField) : void
      {
         param1.type = TextFieldType.DYNAMIC;
         param1.selectable = false;
         param1.setSelection(0,0);
         param1.border = false;
         param1.background = false;
         param1.textColor = 16776960;
         param1.scrollV = 0;
      }
      
      private function addTips(param1:InteractiveObject, param2:String) : void
      {
         TipsManager.getInstance().removeTips(param1);
         TipsManager.getInstance().addTips(param1,param2);
      }
      
      private function forbiddenBtn(param1:SimpleButton, param2:String = null) : void
      {
         DisplayUtil.applyGray(param1);
         param1.mouseEnabled = false;
         TipsManager.getInstance().removeTips(param1);
         if(param2 != null)
         {
            TipsManager.getInstance().addTips(param1,param2);
         }
      }
      
      private function enableBtn(param1:SimpleButton, param2:String = null) : void
      {
         DisplayUtil.clearFilters(param1);
         param1.mouseEnabled = true;
         TipsManager.getInstance().removeTips(param1);
         if(param2 != null)
         {
            TipsManager.getInstance().addTips(param1,param2);
         }
      }
      
      private function onChangeText(param1:TextEvent) : void
      {
         var _loc2_:String = param1.text;
         if(_loc2_ == "\n" || _loc2_ == "\t")
         {
            param1.preventDefault();
            return;
         }
      }
      
      private function dispose() : void
      {
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdModifiMyMessage,this.onModifimyMessage);
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdGetFirstPage,this.onGetFirstPage);
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdGetPage,this.onGetPage);
         MessageCache.dispose();
      }
   }
}

