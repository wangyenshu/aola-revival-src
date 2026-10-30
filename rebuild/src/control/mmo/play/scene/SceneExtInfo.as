package mmo.play.scene
{
   /**
    * REBUILT. Extra data passed along with a scene change (house loaders and
    * the scene arrows take one). Named values plus the arrow list, as the
    * 2013 interfaces use it.
    */
   public dynamic class SceneExtInfo
   {
      public var arrowInfos:Array;
      public var taskIdFromTP:int = -1;
      private var values:Object = {};

      public function SceneExtInfo()
      {
         super();
      }

      public function setVal(key:String, value:*):void
      {
         values[key] = value;
      }

      public function getVal(key:String):*
      {
         return values[key];
      }

      public function hadUsed(key:String):Boolean
      {
         return values.hasOwnProperty(key);
      }

      public function disposeVal(key:String):void
      {
         delete values[key];
      }

      public function dispose():void
      {
         values = {};
      }
   }
}
