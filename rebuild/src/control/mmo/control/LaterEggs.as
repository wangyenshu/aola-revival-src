package mmo.control
{
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.material.petegg.PetEgg;

   /**
    * REVIVAL. The 亚比蛋 of 守护者 that the January 2013 egg table (library/materialdata,
    * PetEggData) lacks, added to it at start as the February and August 2013 tables have them:
    * the eggs a win over 猪猪超人, 年兽, 极速威锋, 赤魔导士, 翡冷翠 and 猎空 brings (the server gives
    * them, battle.ts LATER_EGGS and BOSS_EGGS), named in the 亚比孵化器 and 物品 as the bosses'
    * eggs. And the eggs of the activities of September 2012 to February 2013 (修罗, 天空之神, 武神大陆
    * …), in no egg table that survives, named as their panels name them, after the boss each
    * grows into ("战胜即可获得波塞冬亚比蛋", "鲁曼的亚比蛋": RECONSTRUCTED rows). Not sold: the
    * 收费亚比蛋商品册 keeps its own list, the server its materials.
    */
   public class LaterEggs
   {
      private static const ROWS:Array = [
         [491, "年兽亚比蛋", 260],
         [631, "极速威锋亚比蛋", 200],
         [795, "赤魔导士亚比蛋", 240],
         [883, "猪猪超人亚比蛋", 240],
         [994, "翡冷翠亚比蛋", 240],
         [1696, "猎空亚比蛋", 400],
         // The activities' (sevenstar.ts, kingbosses.ts, fightking.ts, godbosses.ts, wnking.ts).
         [727, "凯撒亚比蛋", 0],
         [730, "修罗亚比蛋", 0],
         [793, "奇灵王亚比蛋", 0],
         [860, "关羽亚比蛋", 0],
         [929, "赵云亚比蛋", 0],
         [953, "张飞亚比蛋", 0],
         [974, "诸葛亮亚比蛋", 0],
         [1106, "吕布亚比蛋", 0],
         [1121, "狼王迪洛斯亚比蛋", 0],
         [1123, "夜王狄米特亚比蛋", 0],
         [1223, "刘备亚比蛋", 0],
         [1231, "鲁曼亚比蛋", 0],
         [1233, "拉诺斯亚比蛋", 0],
         [1249, "纳兹亚比蛋", 0],
         [1281, "施瓦辛格亚比蛋", 0],
         [1290, "塞娅亚比蛋", 0],
         [1335, "波塞冬亚比蛋", 0],
         [1346, "魔洛亚比蛋", 0],
         [1348, "赤翼魔龙王亚比蛋", 0]
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
