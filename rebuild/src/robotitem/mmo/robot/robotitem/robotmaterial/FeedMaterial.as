package mmo.robot.robotitem.robotmaterial
{
   import flash.display.MovieClip;
   import flash.display.Sprite;

   /** LATER (robot/robotitem 2016, symbol 3): the 营养饼干 square of the HELLO物品 panel. */
   public class FeedMaterial extends Sprite
   {
      public var btnFeed:MovieClip;

      public function FeedMaterial()
      {
         super();
         if (btnFeed != null) btnFeed.buttonMode = true;
         buttonMode = true;
      }
   }
}
