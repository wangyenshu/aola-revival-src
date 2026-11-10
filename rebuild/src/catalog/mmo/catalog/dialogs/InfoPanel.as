package mmo.catalog.dialogs
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.user.UserInfo;

   /** 你现在拥有: 晶币 and 星币, at the foot of the 购买 dialogs. */
   public class InfoPanel extends Sprite
   {
      public var txtx:TextField;
      public var txtj:TextField;

      public function InfoPanel()
      {
         super();
         txtj.text = UserInfo.score < 0 ? "" : String(UserInfo.score);
         txtx.text = String(UserInfo.xingbi);
      }
   }
}
