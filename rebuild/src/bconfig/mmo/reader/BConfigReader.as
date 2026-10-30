package mmo.reader
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.utils.getDefinitionByName;
   import mmo.reader.config.BookInfo;
   import mmo.reader.config.UpdateItem;

   /**
    * REBUILT (ported from the later catalog/bconfigreaderservice, same API, so
    * the later catalog/bookclubservice and catalogservice use it): the list of
    * catalog books, read from mmo.config.ConfigEmbed.bconfig, which here holds
    * the era books of tools/gen_bconfig.py.
    */
   public class BConfigReader extends EventDispatcher
   {
      public static const getConfigCatalogs_finished:String = "getConfigCatalogs_finished";
      private static var _instence:BConfigReader;
      private static var _config:XMLList;
      private static var _updateList:Array = [];
      private static var _catalogs:Array = [];
      private static var _books:Array = [];
      private static var _doodles:Array = [];

      public function BConfigReader()
      {
         super();
      }

      public static function get instence():BConfigReader
      {
         if (_instence == null) _instence = new BConfigReader();
         return _instence;
      }

      public function loadConfig():void
      {
         if (_config != null) return;
         var C:Object = getDefinitionByName("mmo.config.ConfigEmbed");
         _config = C["bconfig"];
         for each (var u:XML in _config.updatelist.updateitem)
         {
            _updateList[String(u.@no)] = new UpdateItem({no: String(u.@no), value: u.toString()});
         }
         for each (var c:XML in _config.catalogs.catalog) _catalogs[String(c.@no)] = new BookInfo(obj(c));
         for each (var b:XML in _config.books.book) _books[String(b.@no)] = new BookInfo(obj(b));
         for each (var d:XML in _config.doodles.doodle)
         {
            var bi:BookInfo = new BookInfo(obj(d));
            _doodles[bi.no] = bi;
            _doodles.push(bi);
         }
         dispatchEvent(new Event(getConfigCatalogs_finished));
      }

      private static function obj(x:XML):Object
      {
         return {no: String(x.@no), name: String(x.@n), file: String(x.@f), classPrefix: String(x.@t), pages: String(x.@p)};
      }

      public function getCatalog(no:String):BookInfo
      {
         return _catalogs[no];
      }

      public function getBook(no:String):BookInfo
      {
         return _books[no];
      }

      public function getDoodle(no:String):BookInfo
      {
         return _doodles[no];
      }

      public function getRecentnessDoodle():String
      {
         return _doodles.length == 0 ? null : BookInfo(_doodles[_doodles.length - 1]).no;
      }

      public function get doodles():Array
      {
         return _doodles;
      }

      public function getUpdateItem(no:String):UpdateItem
      {
         return _updateList[no] || new UpdateItem({no: no, value: ""});
      }
   }
}
