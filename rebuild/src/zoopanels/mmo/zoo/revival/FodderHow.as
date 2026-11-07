package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;

   /** REBUILT (the era FeedingMachineMovie's art): where 饲料 comes from; 前往 opens the star map. */
   public class FodderHow extends MovieClip
   {
      public var btnClose:SimpleButton;
      public var btngo:SimpleButton;

      public function FodderHow()
      {
         super();
         var self:FodderHow = this;
         var close:Function = function(e:MouseEvent = null):void { ModalDialogManager.getInstance().removeModalDialog(self); };
         if (btnClose != null) btnClose.addEventListener(MouseEvent.CLICK, close);
         if (btngo != null) btngo.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            close();
            SimpleCustomLoader.loadSingleResource("map/map", "mmo.map.AolaMapService", LoadingSpriteType.DIALOG, "正在加载地图……",
               function(p:Object):void { if (p is IShowPanel) IShowPanel(p).showPanel(); });
         });
      }
   }
}
