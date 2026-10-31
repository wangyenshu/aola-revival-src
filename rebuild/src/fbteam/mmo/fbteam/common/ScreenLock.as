package mmo.fbteam.common
{
   import flash.display.Sprite;
   import mmo.loader.layer.LayerManager;

   /**
    * REVIVAL: the later ProgressFullSprite.lockScreen / unlockScreen, which the
    * 2013 library lacks: while a room's film plays, clicks are kept off the
    * scene by a clear sheet over it.
    */
   public class ScreenLock
   {
      private static var sheet:Sprite;

      public static function lock():void
      {
         if (sheet == null)
         {
            sheet = new Sprite();
            sheet.name = "fbScreenLock";
            sheet.graphics.beginFill(0, 0.01);
            sheet.graphics.drawRect(0, 0, 960, 560);
            sheet.graphics.endFill();
         }
         try { LayerManager.getBaseTop().addChild(sheet); } catch (e:Error) {}
      }

      public static function unlock():void
      {
         if (sheet != null && sheet.parent != null) sheet.parent.removeChild(sheet);
      }
   }
}
