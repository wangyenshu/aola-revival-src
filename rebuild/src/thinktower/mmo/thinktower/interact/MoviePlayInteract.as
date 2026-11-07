package mmo.thinktower.interact
{
   import flash.display.MovieClip;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   
   public class MoviePlayInteract implements Iinteract
   {
      
      private var params:Array;
      
      private var fun:Function;
      
      public function MoviePlayInteract()
      {
         super();
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         var params:Array = param1;
         var callback:Function = param2;
         this.params = params;
         this.fun = callback;
         MovieClip(params[0]).addFrameScript(MovieClip(params[0]).totalFrames - 1,function():void
         {
            MovieClip(params[0]).stop();
            ModalDialogManager.getInstance().removeModalDialog(params[0]);
            if(callback != null)
            {
               callback.apply();
            }
         });
         ModalDialogManager.getInstance().addModalDialog(params[0],AlignType.NONE);
      }
      
      public function dispose() : void
      {
      }
   }
}

