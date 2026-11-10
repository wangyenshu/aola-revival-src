package mmo.common.utils.tips
{
   import flash.display.MovieClip;
   import flash.text.TextField;

   /** The big tip of library_res/common_res_tips (plain text). */
   public class TipsViewBig extends BigTipsBase
   {
      public var mcborder:MovieClip;
      public var txtmessagecontent:TextField;
      public var txtmessagetitle:TextField;
      public var txtNum:TextField;


      public function TipsViewBig()
      {
         super();
         html = false;
      }
   }
}
