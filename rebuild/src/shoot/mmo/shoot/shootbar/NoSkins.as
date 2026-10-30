package mmo.shoot.shootbar
{
   /**
    * REBUILT. The later shoot module dresses its bar panel in the control-bar
    * skin chosen (IControlBarSkinService, later than 2013); the 2013 bar has
    * one look, the first frame.
    */
   public class NoSkins
   {
      public static const instance:NoSkins = new NoSkins();
      /** Never sent: there is no skin to change to. */
      public static const CHANGE:String = "revival_no_control_bar_skin";

      public function getUsingSkinId():int
      {
         return 0;
      }
   }
}
