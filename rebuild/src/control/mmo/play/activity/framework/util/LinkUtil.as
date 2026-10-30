package mmo.play.activity.framework.util
{
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RNotice;

   /**
    * REBUILT shim (not in the January 2013 engine): links later modules use
    * to jump to other panels. Only what the catalog book calls is here.
    */
   public class LinkUtil
   {
      /** 开通蓝宝石: the VIP sign-up page of the real-money shop, which the revival does not have. */
      public static function goToBlueDiamond():void
      {
         RNotice.show(LayerManager.getBaseTop(), "蓝宝石骑士还在修复中哦！");
      }
   }
}
