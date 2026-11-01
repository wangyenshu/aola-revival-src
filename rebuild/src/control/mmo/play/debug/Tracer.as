package mmo.play.debug
{
   import mmo.revival.RLog;

   /**
    * REBUILT (not of the 2013 engine): the later engine's debug trace. Later
    * uploads of quest scripts call it (taskext/task1034, 遇见小宇宙, after its
    * first fight); without the class their handler stopped there.
    */
   public class Tracer
   {
      public static function doTrace(... parts):void
      {
         RLog.log("trace: " + parts.join(" "));
      }
   }
}
