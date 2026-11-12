package mmo.revival.shikarsky
{
   import flash.display.Sprite;
   import mmo.bosspanel.shikarsky.BossInfoPanel;
   import mmo.bosspanel.shikarsky.ShikarSkyBossPanel;

   /** dailyactivity/bosspanel/shikarskybosspanel (猎空's panel) on the 2013 libraries (aola-revival). */
   public class DocShikarSky extends Sprite
   {
      public function DocShikarSky()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [ShikarSkyBossPanel, BossInfoPanel];
      }
   }
}
