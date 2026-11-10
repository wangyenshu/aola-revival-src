package mmo.loader
{
   import flash.display.DisplayObjectContainer;

   /**
    * LATER: the later loader's description of one resource to load (file, class, loading
    * picture, callback), which later copies of 小游戏 (卖蛋糕小达人, 对决无双, 疯狂的水果) hand to
    * SimpleCustomLoader.loadSingleRes. The 2013 loader lacks both; this is in play.swf, and those
    * games call SimpleCLLoader.loadSingleRes instead (their bytecode's SimpleCustomLoader renamed:
    * tools/abc_rename.py in build/all.sh). Written from the later class.
    */
   public class SimpleCLParam
   {
      public var fileName:String;
      public var clsName:String;
      public var loadingSpriteType:int = LoadingSpriteType.DIALOG_WITHOUT_CANCLE;
      public var desc:String = "正在下载，请稍候……";
      public var callback:Function;
      public var callbackObject:Object;
      public var otherFunction:Function;
      public var parent:DisplayObjectContainer;
      public var resDomain:Object;

      public function SimpleCLParam(fileName:String, clsName:String, callback:Function)
      {
         super();
         this.fileName = fileName;
         this.clsName = clsName;
         this.callback = callback;
      }

      public static function create(fileName:String, clsName:String, callback:Function):SimpleCLParam
      {
         return new SimpleCLParam(fileName, clsName, callback);
      }
   }
}
