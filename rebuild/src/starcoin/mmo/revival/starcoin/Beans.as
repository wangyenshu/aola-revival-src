package mmo.revival.starcoin
{
   import mmo.common.dialog.NewDialog;

   /**
    * The player's 晶豆 for the 财富小管家's 晶豆储蓄. The later client kept them in UserInfo.jingdou;
    * the 2013 UserInfo has none, so the ScoreManager account replies carry the count (jingdou),
    * and the later IMaterialGetPanel.showGettedJingdouPanel is a plain notice (REVIVAL).
    */
   public class Beans
   {
      public static var count:int = 0;

      public static function update(p:Object):void
      {
         if (p != null && p.jingdou != null) count = int(p.jingdou);
      }

      public static function got(n:int):void
      {
         NewDialog.showSucceedMessage("获得了" + n + "晶豆！");
      }
   }
}
