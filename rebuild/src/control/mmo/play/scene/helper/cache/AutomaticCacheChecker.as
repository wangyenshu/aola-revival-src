package mmo.play.scene.helper.cache
{
   import flash.display.DisplayObject;

   /**
    * REBUILT shim (not in the January 2013 engine): later modules (the catalog
    * book's PageLoader) create one to bitmap-cache static page art. Caching is
    * only an optimisation, so nothing is cached here.
    */
   public class AutomaticCacheChecker
   {
      private static var _instance:AutomaticCacheChecker;

      public function AutomaticCacheChecker()
      {
         super();
      }

      public static function getInstance():AutomaticCacheChecker
      {
         if (_instance == null) _instance = new AutomaticCacheChecker();
         return _instance;
      }

      public function check(d:DisplayObject, depth:int):Boolean
      {
         return false;
      }
   }
}
