package mmo.loader.common.datastructures
{
   /**
    * REVIVAL (aola-revival). The later loader's ResourceObject (the 2013 loader has none): a
    * resource path (without .swf, as ResScheduler takes it) and the class to make from it.
    * 酷跑星世界's ParkourResConfig names its panels with them.
    */
   public class ResourceObject
   {
      private var _resPath:String;
      private var _clsName:String;
      private var _pars:Array;

      public function ResourceObject(resPath:String, clsName:String, pars:Array = null)
      {
         super();
         _resPath = resPath;
         _clsName = clsName;
         _pars = pars;
      }

      public function get resPath():String
      {
         return _resPath;
      }

      public function get clsName():String
      {
         return _clsName;
      }

      public function get pars():Array
      {
         return _pars;
      }
   }
}
