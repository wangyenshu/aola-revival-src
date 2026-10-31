package mmo.spacetime.common
{
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   
   public class DialogHelper
   {
      
      public function DialogHelper()
      {
         super();
      }
      
      public static function showMaxLevelDialog() : void
      {
         var onRemoveEvent:Function = null;
         var onOk:Function = null;
         var message:String = null;
         var md:ModalDialog = null;
         if(TeamHelper.isCaptain())
         {
            onRemoveEvent = function(param1:ModalDialogEvent):void
            {
               var _loc2_:ModalDialog = param1.currentTarget as ModalDialog;
               _loc2_.removeEventListener(ModalDialogEvent.OK,onOk);
               _loc2_.removeEventListener(ModalDialogEvent.CLOSE,onRemoveEvent);
            };
            onOk = function(param1:ModalDialogEvent):void
            {
               onRemoveEvent(param1);
               JumpSceneHelper.loadPreviousScene();
            };
            message = "你的力量不足以穿过这道时空之门，时空乱流将你卷回了竞技场，请在此继续提高你的对战实力吧.";
            md = NewDialog.getDialog(message,NewDialog.getSucceedIcon());
            md.addEventListener(ModalDialogEvent.OK,onOk);
            md.addEventListener(ModalDialogEvent.CLOSE,onRemoveEvent);
            md.show();
         }
      }
      
      public static function showSelectPanelDialog() : void
      {
         var cls:Class = null;
         var panel:IShowPanel = null;
         if(ApplicationDomain.currentDomain.hasDefinition("mmo.spacetimepanel.SelectPanel"))
         {
            cls = getDefinitionByName("mmo.spacetimepanel.SelectPanel") as Class;
            panel = new cls() as IShowPanel;
            panel.showPanel();
         }
         else
         {
            SimpleCustomLoader.loadSingleResource("spacetime/spacetimepanel","mmo.spacetimepanel.SelectPanel",LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"载入中。。",function(param1:IShowPanel):void
            {
               param1.showPanel();
            });
         }
      }
   }
}

