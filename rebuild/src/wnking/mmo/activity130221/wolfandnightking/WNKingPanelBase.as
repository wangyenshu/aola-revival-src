package mmo.activity130221.wolfandnightking
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.play.activity.RefuseInviteHelper;
   
   public class WNKingPanelBase extends Sprite implements IShowPanel, IDispose
   {
      
      public function WNKingPanelBase()
      {
         super();
         this.addEventListener(MouseEvent.CLICK,this.clickBtn);
      }
      
      protected function clickBtn(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name as String;
         switch(_loc2_)
         {
            case "btnClose":
               this.closePanel();
         }
      }
      
      public function showPanel() : void
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         if(_loc1_.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队不能进入");
            return;
         }
         RefuseInviteHelper.refuseInvite();
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      protected function closePanel() : void
      {
         RefuseInviteHelper.resumeInvite();
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.clickBtn);
      }
   }
}

