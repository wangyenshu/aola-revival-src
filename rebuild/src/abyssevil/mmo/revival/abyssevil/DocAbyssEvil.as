package mmo.revival.abyssevil
{
   import flash.display.Sprite;
   import mmo.activity121220.abyssevil.BuyLimitPanel;
   import mmo.activity121220.abyssevil.BuyPanel;
   import mmo.activity121220.abyssevil.MainPanel;
   import mmo.activity121220.abyssevil.MoneyPanel;
   import mmo.activity121220.abyssevil.Need100LevelPanel;

   /**
    * activityres/activity121220/abyssevilmainpanel (魔龙之战, its copy of 2015) on the 2013 libraries
    * (aola-revival): its decompiled code on its own art; the later buff bar it put on the panel
    * (IBuffCache) is left out.
    */
   public class DocAbyssEvil extends Sprite
   {
      public function DocAbyssEvil()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [MainPanel, MoneyPanel, BuyPanel, BuyLimitPanel, Need100LevelPanel];
      }
   }
}
