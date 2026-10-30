package mmo.reader.config
{
   /**
    * REBUILT (ported from the later catalog/bconfigreaderservice): a catalog
    * book; pages "f,p;f,p" are page file <file><f> and class <prefix><f>_<p>.
    */
   public class BookInfo
   {
      public var no:String;
      public var classPrefix:String;
      public var name:String;
      public var page:Array = [];
      public var file:String;

      public function BookInfo(o:Object)
      {
         super();
         no = o.no;
         name = o.name;
         file = o.file;
         classPrefix = o.classPrefix;
         for each (var p:String in String(o.pages).split(";"))
         {
            var fp:Array = p.split(",");
            if (fp.length < 2) continue;
            page.push(new PageInfo(file + fp[0], classPrefix + fp[0] + "_" + fp[1], int(fp[0]), int(fp[1])));
         }
      }

      public function get pageCount():int
      {
         return page.length;
      }

      public function get lastPageIndex():int
      {
         return page.length - 1;
      }

      public function getPageIndex(fileIndex:int, classIndex:int):int
      {
         for (var i:int = 0; i < page.length; i++)
         {
            var p:PageInfo = page[i] as PageInfo;
            if (p.fileNameIndex == fileIndex && p.classNameIndex == classIndex) return i;
         }
         return -1;
      }
   }
}
