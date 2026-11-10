package mmo.common.utils.tips
{
   /** The later tips' hidden part ("隐藏开始…隐藏结束", what a tip carries for itself): left out of the text. */
   public class TipsMsgFilter
   {
      public static function filterMsg(s:String):String
      {
         var a:int = s.indexOf("隐藏开始");
         if (a < 0) return s;
         var b:int = s.indexOf("隐藏结束") + "隐藏结束".length;
         return s.substr(0, a) + s.substr(b, s.length);
      }
   }
}
