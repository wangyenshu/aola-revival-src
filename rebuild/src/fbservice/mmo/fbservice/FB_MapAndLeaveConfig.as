package mmo.fbservice
{
   public class FB_MapAndLeaveConfig
   {
      
      public static const FBMAP_RESINFO:Object = {
         "fbaixi":["fbservice/fbaiximap","mmo.fbservice.fbaixi.FbAixiMapPanel"],
         "fbsuolide":["fbservice/fbaiximap","mmo.fbservice.fbsuolide.FbSuolideMapPanel"],
         "fbsiwude":["fbservice/fbaiximap","mmo.fbservice.fbsiwude.FbSiwudeMapPanel"],
         "fbyishuzhidu":["fbservice/fbaiximap","mmo.fbservice.fbyishuzhidu.FbYishuzhiduMapPanel"]
      };
      
      public static const FB_MSGS:Object = {
         "fbaixi":["倒立金字塔地图","离开幻影冰宫","你确定要离开幻影冰宫吗？"],
         "fbsuolide":["倒立金字塔地图","离开倒立金字塔","你确定要离开倒立金字塔吗？"],
         "fbsiwude":["蚁族王朝地图","离开蚁族王朝","你确定要离开蚁族王朝吗？"],
         "fbyishuzhidu":["艺术之都恐龙馆地图","离开恐龙馆","你确定要离开恐龙馆吗？"]
      };
      
      public function FB_MapAndLeaveConfig()
      {
         super();
      }
   }
}

