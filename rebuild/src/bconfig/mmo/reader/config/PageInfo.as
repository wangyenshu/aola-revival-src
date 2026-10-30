package mmo.reader.config
{
   /** REBUILT (ported from the later catalog/bconfigreaderservice): one catalog page. */
   public class PageInfo
   {
      public var className:String;
      public var fileName:String;
      public var fileNameIndex:int;
      public var classNameIndex:int;

      public function PageInfo(fileName:String, className:String, fileNameIndex:int, classNameIndex:int)
      {
         super();
         this.fileName = fileName;
         this.className = className;
         this.fileNameIndex = fileNameIndex;
         this.classNameIndex = classNameIndex;
      }
   }
}
