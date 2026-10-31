package mmo.control
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.config.ConfigReader;
   import mmo.revival.RUI;

   /**
    * REVIVAL. The 工具箱's 传送 without typing: the places of the 30 Nov 2012
    * world map (tools/data/map-places-2012.json, map/mapguide2012) and the
    * scenes each of them shows, as buttons. Chinese can not be typed into
    * the Flash field under Ruffle; a pick needs no input method and no
    * browser box.
    */
   public class PlacePicker extends Sprite
   {
      /** title:scene,scene;… (generated once from the map's places and config.xml). */
      private static const PLACES:String = "M7星云:msevenstar1,msevenstar2,msevenstar3;指挥中心:maintown2;传送核心:maintown1;极速俱乐部:fastclub;主题公园:themepark;生态园:ecologicalpark;奥拉广场:starland;HELLO学院:helloschool,science;十字大道:crossroad,loveassociation,library,xianxiazhanguan;太空港:teambattleoutside;银河商会:employmenttown;蓝宝石要塞:bluesquare;奥拉之树:aolatree;奥拉运动场:gymnasium;战斗星域:spacetimechallenge;流星购物街:starshopping,clothesshop,furnitureshop,toolshop,plantpark;亚比研究中心:yabistudy,yabitrain,science;星光游乐场:amusementpark;欢乐岛:summerhotspring;百田大剧场:theatre;亚比协会:yabiunion;费尔区:feier1,feier2,feier3,feier4,volcano;比特区:bite1,bite2,bite3,bite4;海文花园:haiwen1,haiwen2,haiwen3,haiwen4,haiwen5;雷鸣大陆:leiming1,leiming2,leiming3,leiming4;沃尔特区:woerte1,woerte2,woerte3,woerte4;思伍德区:siwude1,siwude2,siwude3,siwude4,siwude6,siwude5;索里德区:suolide,suolide1,suolide2,suolide3,suolide4,suolide5;艾夕区:aixiscene1,aixiscene2,aixiscene4,aixiscene6;艺术之都:yishuzhidu1,yishuzhidu2,yishuzhidu3,yishuzhidu4,yishuzhidu5,aquarium,yishuzhidu6;发明岛:inventisland1,inventisland2,inventisland3,inventisland4,inventisland5;上古神殿:temple1,temple2,temple3,temple6;云端王国:cloudstar1,cloudstar2,cloudstar3,cloudstar4,cloudstar5,cloudstar6;大地迷城:mysticearth1,mysticearth2,mysticearth3,mysticearth4;海洋幻境:mysticocean1,mysticocean2,mysticocean3,mysticocean4;六芒神殿:hexagrampalace1,hexagrampalace2,hexagrampalace3,hexagrampalace4;美食之星:catestar1,catestar2,catestar3,catestar4;魔术之星:magicstar1,magicstar2,magicstar3;童话之星:fairytalestar1,fairytalestar2,fairytalestar3,fairytalestar4;独角之星:unicornstar1,unicornstar2,unicornstar3,unicornstar4,unicornstar5;海枯之星:haikustar1,haikustar2,haikustar3,haikustar4;冰雪之星:bingxuestar1,bingxuestar2,bingxuestar3,bingxuestar4;尖叫游乐园:screampark1,screampark2,screampark3,screampark4;音乐之都:musicstar1,musicstar2,musicstar3,musicstar4;白灵圣殿:bailingstar1,bailingstar2,bailingstar3,bailingstar4;雅克星:yakestar1,yakestar2,yakestar3,yakestar4;糖果星:candystar1,candystar2,candystar3,candystar4;风车谷:windmillstar1,windmillstar2,windmillstar3,windmillstar4;时钟之域:clockstar1,clockstar2,clockstar3,clockstar4;骑士王国:knightstar1,knightstar2,knightstar3,knightstar4;惊雷道馆:huanlei;炼火道馆:huanyan;御水道馆:huanliu;命运道馆:huanming;光明道馆:huanguang;终极神殿:huanfinal";

      private static const W:int = 438;
      private static const H:int = 312;

      private var onPick:Function;
      private var page:Sprite;

      public function PlacePicker(onPick:Function, onClose:Function)
      {
         super();
         this.onPick = onPick;
         graphics.beginFill(0xEAF6FF, 1);
         graphics.lineStyle(2, 0x5AA8E0);
         graphics.drawRoundRect(0, 0, W, H, 16, 16);
         graphics.endFill();
         var close:Sprite = RUI.smallButton("×", onClose, 28, 22, "pickerClose");
         close.x = W - 36;
         close.y = 6;
         addChild(close);
         showPlaces();
      }

      private static function places():Array
      {
         var out:Array = [];
         for each (var p:String in PLACES.split(";"))
         {
            var i:int = p.indexOf(":");
            out.push({title: p.substr(0, i), scenes: p.substr(i + 1).split(",")});
         }
         return out;
      }

      private function fresh(title:String):void
      {
         if (page != null) removeChild(page);
         page = new Sprite();
         addChildAt(page, 0);
         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = title;
         t.x = 14;
         t.y = 8;
         page.addChild(t);
      }

      private function showPlaces():void
      {
         fresh("选一个地方");
         var all:Array = places();
         var cols:int = 5;
         for (var i:int = 0; i < all.length; i++)
         {
            var p:Object = all[i];
            var b:Sprite = RUI.button(p.title, placeClick(p), 80, 20, 0x8ED0FA, 0x3C96DC, "pickPlace" + i);
            b.x = 12 + (i % cols) * 84;
            b.y = 36 + int(i / cols) * 22;
            page.addChild(b);
         }
      }

      private function placeClick(p:Object):Function
      {
         return function():void
         {
            if (p.scenes.length == 1) onPick(p.scenes[0]);
            else showScenes(p);
         };
      }

      private function showScenes(p:Object):void
      {
         fresh(p.title);
         var cfg:ConfigReader = ConfigReader.instance;
         var n:int = 0;
         for each (var nm:String in p.scenes)
         {
            var label:String = nm;
            try
            {
               var r:XMLList = cfg.xmlDocument..r.(attribute("nm") == nm);
               if (r.length() > 0 && String(r[0].@desc)) label = String(r[0].@desc);
            }
            catch (e:Error) {}
            var b:Sprite = RUI.button(label, sceneClick(nm), 132, 26, 0xFFC45A, 0xF07812, "pickScene" + n);
            b.x = 14 + (n % 3) * 140;
            b.y = 40 + int(n / 3) * 32;
            page.addChild(b);
            n++;
         }
         var back:Sprite = RUI.button("返回", showPlaces, 70, 24, 0x6CC0F5, 0x2E86D6, "pickBack");
         back.x = 14;
         back.y = H - 34;
         page.addChild(back);
      }

      private function sceneClick(nm:String):Function
      {
         return function():void { onPick(nm); };
      }
   }
}
