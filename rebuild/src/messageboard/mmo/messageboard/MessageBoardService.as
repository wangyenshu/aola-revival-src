package mmo.messageboard
{
   import flash.display.Sprite;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.messageboard.IMessageBoardService;
   import mmo.messageboard.panel.MessageBoardPanel;
   
   public class MessageBoardService extends Sprite implements IMessageBoardService
   {
      
      public function MessageBoardService()
      {
         super();
      }
      
      public function showMessageBoard(param1:String) : void
      {
         ModalDialogManager.getInstance().addModalDialog(new MessageBoardPanel(param1),AlignType.NONE,PanelEffect.NONE,true,0,0);
      }
   }
}

