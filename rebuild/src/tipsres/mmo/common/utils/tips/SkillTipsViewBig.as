package mmo.common.utils.tips
{
   import flash.display.MovieClip;
   import flash.text.TextField;

   /** The big tip of library_res/common_res_tips (its text as HTML). */
   public class SkillTipsViewBig extends BigTipsBase
   {
      public var mcborder:MovieClip;
      public var txtmessagecontent:TextField;
      public var txtmessagetitle:TextField;

      public var mcTips:MovieClip;

      public function SkillTipsViewBig()
      {
         super();
         html = true;
      }
   }
}
