package mmo.common.material
{
   import mmo.common.dialog.NewDialog;
   import mmo.common.user.UserInfo;

   /**
    * REVIVAL (aola-revival). The later common library's MaterialResultDialogHelper (the 2013 one
    * has none): the message for a failed buy. 酷跑星世界 calls showMaterialResultDialog(res, true)
    * when a 星币 purchase is refused. The later texts; every case a plain fail message (the
    * later 星币 shortage dialog came from a dialogextension module the 2013 client lacks).
    */
   public class MaterialResultDialogHelper
   {
      public static function showMaterialResultDialog(res:int, xingbi:Boolean, xingzuan:Boolean = false):void
      {
         switch (res)
         {
            case 101:
               if (xingzuan) NewDialog.showFailMessage("很抱歉，你的星钻余额不足。");
               else if (xingbi) NewDialog.showFailMessage("很抱歉，你的星币余额不足，目前你拥有" + UserInfo.xingbi + "星币。");
               else NewDialog.showFailMessage("很抱歉，你的晶豆和晶币余额不足。");
               break;
            case 102:
               if (xingbi) NewDialog.showFailMessage("你今天的星币获得已达到上限。");
               else if (!xingzuan) NewDialog.showFailMessage("你今天的晶币获得已达到上限。");
               break;
            case 3:
               NewDialog.showFailMessage("你不能拥有更多的该物品。");
               break;
            case 6:
               NewDialog.showFailMessage("这件物品只能拥有一件噢，不能再获得啦！");
               break;
            case 7:
               NewDialog.showFailMessage("这件物品需要蓝宝石用户才能购买。");
               break;
            case 12:
               NewDialog.showFailMessage("你今天的星币消费额度已经达到上限，请明天再来吧！");
               break;
            case 13:
               NewDialog.showFailMessage("星币消费额度已经到达当月上限。");
               break;
            case 202:
               NewDialog.showFailMessage("今天已经不能继续获得该物品了！");
               break;
            default:
               NewDialog.showFailMessage("操作失败，请联系客服。" + res);
         }
      }
   }
}
