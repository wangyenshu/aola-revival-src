package mmo.control
{
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.material.petegg.PetEgg;

   /**
    * REVIVAL. The 亚比蛋 of 守护者 that the January 2013 egg table (library/materialdata,
    * PetEggData) lacks, added to it at start as the February and August 2013 tables have them:
    * the eggs a win over 猪猪超人, 年兽, 极速威锋, 赤魔导士, 翡冷翠 and 猎空 brings (the server gives
    * them, battle.ts LATER_EGGS and BOSS_EGGS), named in the 亚比孵化器 and 物品 as the bosses'
    * eggs. Not sold: the 收费亚比蛋商品册 keeps its own list, the server its materials.
    */
   public class LaterEggs
   {
      private static const ROWS:Array = [
         [491, "年兽亚比蛋", 260],
         [631, "极速威锋亚比蛋", 200],
         [795, "赤魔导士亚比蛋", 240],
         [883, "猪猪超人亚比蛋", 240],
         [994, "翡冷翠亚比蛋", 240],
         [1696, "猎空亚比蛋", 400]
      ];

      public static function install():void
      {
         var data:Object;
         try
         {
            data = Object(getDefinitionByName("mmo.materialdata.PetEggData")).data;
         }
         catch (e:Error)
         {
            return;
         }
         for each (var r:Array in ROWS)
         {
            if (data[String(r[0])] == null) data[String(r[0])] = new PetEgg(r[0], r[1], false, 0, false, 999, 0, r[2], true);
         }
      }
   }
}
