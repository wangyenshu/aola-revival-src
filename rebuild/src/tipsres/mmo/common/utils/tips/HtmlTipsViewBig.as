package mmo.common.utils.tips
{
   import flash.display.MovieClip;
   import flash.text.TextField;

   /** The big tip of library_res/common_res_tips (its text as HTML). */
   public class HtmlTipsViewBig extends BigTipsBase
   {
      public var mcborder:MovieClip;
      public var txtmessagecontent:TextField;
      public var txtmessagetitle:TextField;



      public function HtmlTipsViewBig()
      {
         super();
         html = true;
      }
   }
}
