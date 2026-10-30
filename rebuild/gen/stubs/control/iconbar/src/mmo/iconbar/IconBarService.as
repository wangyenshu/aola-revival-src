package mmo.iconbar
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.control.*;
   import mmo.interfaces.control.IIconBarService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for IconBar. Module control/iconbar.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.control.IIconBarService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class IconBarService extends EventDispatcher implements IIconBarService
   {
      public function IconBarService()
      {
         super();
      }

      public function setPlaceName(param1:String) : void
      {
         RLog.stub("IconBarService.setPlaceName");
      }

      public function resumeTimeBar() : void
      {
         RLog.stub("IconBarService.resumeTimeBar");
      }

      public function hide() : void
      {
         RLog.stub("IconBarService.hide");
      }

      public function showItemBar() : void
      {
         RLog.stub("IconBarService.showItemBar");
      }

      public function pauseTimeBar() : void
      {
         RLog.stub("IconBarService.pauseTimeBar");
      }

      public function closeItemBar() : void
      {
         RLog.stub("IconBarService.closeItemBar");
      }

      public function closeSoundButton(param1:Boolean) : void
      {
         RLog.stub("IconBarService.closeSoundButton");
      }

      public function show() : void
      {
         RLog.stub("IconBarService.show");
      }

      public function hideItemBar() : void
      {
         RLog.stub("IconBarService.hideItemBar");
      }

      public function init() : void
      {
         RLog.stub("IconBarService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
