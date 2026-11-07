package mmo.activity121220.abyssevil
{
   import flash.display.DisplayObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.scheduler.ResScheduler;
   
   public class Need100LevelPanel extends Sprite implements IDispose, IShowPanel
   {
      
      public var btnclose:SimpleButton;
      
      public var btnhow:SimpleButton;
      
      public var btncontinue:SimpleButton;
      
      private var cb:Function;
      
      public function Need100LevelPanel(param1:Function)
      {
         super();
         this.cb = param1;
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = DisplayObject(param1.target).name;
         switch(_loc2_)
         {
            case "btnclose":
               this.close();
               break;
            case "btncontinue":
               this.handleContinue();
               break;
            case "btnhow":
               this.handleHow();
         }
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function handleContinue() : void
      {
         if(this.cb != null)
         {
            this.cb.apply();
         }
      }
      
      private function handleHow() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("pet/howtolevelup",function(param1:Object):void
         {
            var panelClass:Class;
            var panel:IShowPanel;
            var args:Object = param1;
            ProgressFullSprite.close();
            panelClass = ApplicationDomain.currentDomain.getDefinition("mmo.howtolevelup.MainPanel") as Class;
            panel = new panelClass(function():void
            {
            });
            panel.showPanel();
         });
      }
      
      public function showPanel() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }
   }
}

