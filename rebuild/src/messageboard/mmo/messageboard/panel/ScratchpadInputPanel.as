package mmo.messageboard.panel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.FocusEvent;
   import flash.events.TextEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import mmo.common.Text;
   import mmo.common.user.UserInfo;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.user.IUserNameManager;
   
   public class ScratchpadInputPanel extends Sprite
   {
      
      private var type:int;
      
      private var sp:Sprite;
      
      private var txtInput:TextField;
      
      private var content:String;
      
      private var defaultWord:String;
      
      private const preName:String = "mmo.messageboard.panel.Scratchpad";
      
      public function ScratchpadInputPanel(param1:int, param2:String = null, param3:String = null)
      {
         super();
         this.type = param1;
         this.content = param2;
         this.defaultWord = param3;
         this.init();
      }
      
      private function init() : void
      {
         var _loc1_:Class = ApplicationDomain.currentDomain.getDefinition(this.preName + this.type) as Class;
         this.sp = new _loc1_() as Sprite;
         this.addChild(this.sp);
         SimpleButton(this.sp.getChildByName("btnClose")).visible = false;
         SimpleButton(this.sp.getChildByName("btn_record")).visible = false;
         this.txtInput = TextField(this.sp.getChildByName("txt_content"));
         this.txtInput.addEventListener(FocusEvent.FOCUS_IN,this.onTxtFocusIn);
         this.txtInput.addEventListener(FocusEvent.FOCUS_OUT,this.onTxtFocusOut);
         this.txtInput.addEventListener(TextEvent.TEXT_INPUT,this.onChangeTxt);
         if(this.content == null || this.content == "" || this.content == this.defaultWord)
         {
            this.txtInput.textColor = 10066329;
            this.txtInput.text = this.defaultWord;
         }
         else
         {
            this.txtInput.text = this.content;
         }
         this.txtInput.type = TextFieldType.INPUT;
         this.txtInput.mouseWheelEnabled = false;
         this.txtInput.selectable = true;
         var _loc2_:IUserNameManager = ServiceContainer.getService(IUserNameManager) as IUserNameManager;
         var _loc3_:String = _loc2_.getNickName(UserInfo.userName);
         TextField(this.sp.getChildByName("txt_message")).text = _loc3_;
      }
      
      private function onTxtFocusIn(param1:FocusEvent) : void
      {
         var _loc2_:TextField = param1.currentTarget as TextField;
         if(Text.trim(_loc2_.text) == this.defaultWord)
         {
            _loc2_.textColor = 75356;
            _loc2_.text = "";
         }
      }
      
      private function onTxtFocusOut(param1:FocusEvent) : void
      {
         var _loc2_:TextField = param1.currentTarget as TextField;
         if(Text.trim(_loc2_.text) == "")
         {
            _loc2_.textColor = 10066329;
            _loc2_.text = this.defaultWord;
         }
      }
      
      private function onChangeTxt(param1:TextEvent) : void
      {
         var _loc2_:String = param1.text;
         if(_loc2_ == "\n" || _loc2_ == "\t")
         {
            param1.preventDefault();
            return;
         }
      }
      
      public function getText() : String
      {
         return this.txtInput.text;
      }
      
      public function setText(param1:String) : void
      {
         this.txtInput.text = param1;
      }
   }
}

