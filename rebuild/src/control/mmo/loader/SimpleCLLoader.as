package mmo.loader
{
   import flash.system.ApplicationDomain;

   /**
    * LATER: SimpleCustomLoader.loadSingleRes of the later loader, for the later copies of 小游戏
    * that call it (their bytecode names this class instead: tools/abc_rename.py in build/all.sh):
    * the 2013 loader's loadSingleResource with the parameters of a SimpleCLParam; the callback
    * also gets the domain, as the later one gave it.
    */
   public class SimpleCLLoader
   {
      public static function loadSingleRes(p:SimpleCLParam):void
      {
         if (p == null) return;
         var cb:Function = p.callback;
         SimpleCustomLoader.loadSingleResource(p.fileName, p.clsName, p.loadingSpriteType, p.desc, function(o:*):void
         {
            if (cb == null) return;
            if (cb.length >= 2) cb.apply(p.callbackObject, [o, ApplicationDomain.currentDomain]);
            else cb.apply(p.callbackObject, [o]);
         }, null, p.otherFunction);
      }
   }
}
