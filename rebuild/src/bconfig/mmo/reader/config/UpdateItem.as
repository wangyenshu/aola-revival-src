package mmo.reader.config
{
   /** REBUILT (ported): the date a catalog last changed, for the "new" mark. */
   public class UpdateItem
   {
      public var value:String = null;
      public var no:String = null;

      public function UpdateItem(o:Object)
      {
         super();
         no = o.no;
         value = o.value;
      }
   }
}
