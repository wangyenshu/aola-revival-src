package mmo.control
{
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.material.item.Item;

   /**
    * REVIVAL. Items of the activities after January 2013 that the January material table
    * (library/materialdata) lacks or has otherwise, added to it at start as the August 2013 table
    * has them: the 剑魂 and 封印 of 夜王复出！狼王再现！ (February 2013; the 封印 are not in the
    * January table, whose 剑魂 are the 2012 activity's, for 蓝宝石 only and without a 星币 price).
    * Their icons are the era files (item/view707–709 of 21 February 2013). The server has the
    * same rows (wnking.ts).
    */
   public class LaterItems
   {
      private static const ROWS:Array = [
         [565, "光之剑魂", 9, 0, 70, 1, 0, false, false, 1, "集齐光之剑魂、王之剑魂、灵之剑魂后，可以获得狼王迪洛斯。"],
         [566, "王之剑魂", 9, 0, 100, 1, 0, false, false, 1, "集齐光之剑魂、王之剑魂、灵之剑魂后，可以获得狼王迪洛斯。"],
         [567, "灵之剑魂", 9, 0, 130, 1, 0, false, false, 1, "集齐光之剑魂、王之剑魂、灵之剑魂后，可以获得狼王迪洛斯。"],
         [707, "幽之封印", 9, 0, 70, 1, 0, false, false, 1, "集齐幽、暗、冥三个封印，就可以召唤夜王了。"],
         [708, "暗之封印", 9, 0, 100, 1, 0, false, false, 1, "集齐幽、暗、冥三个封印，就可以召唤夜王了。"],
         [709, "冥之封印", 9, 0, 130, 1, 0, false, false, 1, "集齐幽、暗、冥三个封印，就可以召唤夜王了。"]
      ];

      public static function install():void
      {
         var data:Object;
         try
         {
            data = Object(getDefinitionByName("mmo.materialdata.ItemData")).data;
         }
         catch (e:Error)
         {
            return;
         }
         for each (var r:Array in ROWS)
         {
            data[String(r[0])] = new Item(r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10]);
         }
      }
   }
}
