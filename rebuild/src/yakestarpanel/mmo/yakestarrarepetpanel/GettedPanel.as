package mmo.yakestarrarepetpanel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.user.IUserNameManager;
   public class GettedPanel extends Sprite implements IDispose, IShowPanel
   {
      
      public var btnclose:SimpleButton;
      
      public var txtname:TextField;
      
      private var txtName:TextField = null;
      
      private var btnClose:SimpleButton = null;
      
      public function GettedPanel()
      {
         super();
         this.txtName = this.txtname as TextField;
         this.btnClose = this.btnclose as SimpleButton;
         ServiceContainer.instance.tryGetService(IUserNameManager,function(param1:IUserNameManager, param2:Object):void
         {
            txtName.text = param1.getNickName(SocketClient.instance.myUserName);
         });
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onClose);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         var _loc2_:IMaterialGetPanel = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
         _loc2_.showPanel(MaterialTypes.PET_EGG,832,1);
      }
      
      public function showPanel() : void
      {
         ModalDialogManager.getInstance().addModalDialog(this,AlignType.NONE,0,true,0,0,true);
      }
      
      public function dispose() : void
      {
         this.btnClose.removeEventListener(MouseEvent.CLICK,this.onClose);
      }
   }
}

