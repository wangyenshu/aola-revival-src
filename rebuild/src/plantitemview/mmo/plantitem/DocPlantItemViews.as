package mmo.plantitem
{
   import flash.display.MovieClip;

   /**
    * REBUILT plantitem/view1 … view7 (the 盆栽道具's pictures; the era files are lost).
    * Each file is one picture bound to its class mmo.plantitem.view<id>, the name
    * the material service asks for: 1 极速雨露, 2 极速养料, 3 健康基因药剂, 4 营养基因药剂,
    * 5 增产养料, 6 繁盛养料 (pictures of the 种植手册's 种植道具 page, catalog/zhongzhi2),
    * 7 铲子 (the shovel of the tree manager's 铲除 film). This root only lists them.
    */
   public class DocPlantItemViews extends MovieClip
   {
      public static const VIEWS:Array = [view1, view2, view3, view4, view5, view6, view7];

      public function DocPlantItemViews()
      {
         super();
      }
   }
}
