package mmo.revival.tipsres
{
   import flash.display.Sprite;
   import mmo.common.utils.tips.HtmlTipsViewBig;
   import mmo.common.utils.tips.SkillTipsViewBig;
   import mmo.common.utils.tips.TipsView;
   import mmo.common.utils.tips.TipsViewBig;

   /**
    * REBUILT library_res/common_res_tips (aola-revival): the views of the 2013 TipsManager's tips
    * (TipsView, TipsViewBig, HtmlTipsViewBig, SkillTipsViewBig) on the art of its later copy, whose
    * own code calls what the 2013 libraries do not have (and so every big tip failed).
    */
   public class DocTipsRes extends Sprite
   {
      public function DocTipsRes()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [TipsView, TipsViewBig, HtmlTipsViewBig, SkillTipsViewBig];
      }
   }
}
