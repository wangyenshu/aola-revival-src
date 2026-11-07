package mmo.control
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.revival.RUI;

   /**
    * REVIVAL. The 工具箱's music: every piece of the game's music up to the end of 2014
    * (game/www.9aola.com/music, 100 pieces), numbered from 1 in the order they came (their
    * upload dates), named after a place that plays it (config.xml's desc, of 2013 or later).
    * A pick plays it (SceneMusic.playChosen) until the next scene, or a mini game with music
    * of its own.
    */
   public class MusicPicker extends Sprite
   {
      /** file (under music/, without .mp3):name; in their order (generated from the music files and the configs). */
      private static const LIST:String = "aixifb:叹息小径;anniversary:女神音乐会;aolafight:陆军战斗遗址;bailingstar:白灵古道;bingxuestar:怀特雪原;bite:机械废墟;blowbubble:欢乐满天飞;bluesquare:战队要塞;bluesquarenew:蓝宝圣殿;candystar:彩虹小城;catestar:冰淇淋大街;centre:传送核心;challenger:银河冠军擂台;cherrybanquet:女神殿堂;christmas:亚比游乐园;city:道具店;clockstar:雕刻时光沙滩;cloudstar:奇草树林;diamondisland:钻石屋;dinosaurfb:迅猛龙巢穴;dust:遗迹区域;ecologicalparknew:生态园;fairytalestar:童心小屋;festival:快乐方舟;fightkingwar:奔马平原;fightspace:斗魂平原;fire:费尔村落;forevernight:奥拉之树;giantcordillera:巨人山脚;gymnasium:王牌运动场;haikustar:观星海岸;haiwen:天空大陆;hallowmas:亚比协会;hami:最美星光;hexagrampalace:六芒前殿;house:小屋;hubblebubble:缤纷泡泡街;ice:冰雕广场;inventisland:发明港口;knightstar:骑士学院;leiming:雷鸣海滨;library:HELLO学院;login:无火祭坛;magicstar:魔术广场;mantenxiagu:奇迹谷底;matchthreegame:对对碰;milliondance:舞动全星;msevenstar:古代遗迹;musicstar:时代广场;mysticearth:迷城河畔;mysticocean:幻之结界;newyearspringmusic:科学院;onelinegame:小小印花家;puzzlebobble:霓虹泡泡珠;screampark:尖叫游乐园;shootgame:宇宙神射手;siwudefb:蚁穴前哨;skycity4:海底世界;spacetime:时空隧道;starlandnew:卡尔夫魔法学院;starsea:章鱼海湾;summerhotspringnew:欢乐岛;suolidefb:沙漏密室;swimming:减肥大作战;teambattleoutside:太空港;temple:崩坏的上古神殿;temple16:赤羽道场;themeparknew:银河商会;themeparknew2:十字大道;themeparknew3:十字大道;themeparknew4:蓝宝石要塞;twoyearscherry:贵宾广场;unicornstar:皇宫外城;water:回音海岸;whitenight:白昼峡谷;windmillstar:风车城;wood:部落林地;xuhuanzhichun:虚幻之春;yabiexhibition:伢牙乐大庙会;yakestar:伊索部落;yishuzhidu:艺术广场;youanmingzhou:选择之殿;starshinecity2:魔戒密林;majicorsair0:麻吉海盗船;holysword:亚希国;newheroking:潜能试炼场;lonlyisland:寂静之森;twinkingdom:考验之巅;jiabistar:时空钟摆;apocalypse:伏天之城;themepark5:落木之涯;clothesmusic/clothessuit_511:风之岛屿;themepark:双11狂欢节;bluesquare2015:蓝宝石要塞;peteden:神宠乐园;starland:奥拉广场;starshopping:流星购物街;themepark2015:日月神殿;yabistudy:亚比培养基地;fightBgMusic1:亚比战斗";
      private static const W:int = 438;
      private static const H:int = 330;
      private static const PAGE:int = 30;

      private var onPick:Function;
      private var page:Sprite;

      /** [{id, file ("music/x.mp3"), name}] */
      public static function all():Array
      {
         var out:Array = [];
         var parts:Array = LIST.split(";");
         for (var i:int = 0; i < parts.length; i++)
         {
            var p:String = parts[i];
            var k:int = p.indexOf(":");
            out.push({id: i + 1, file: "music/" + p.substr(0, k) + ".mp3", name: p.substr(k + 1)});
         }
         return out;
      }

      /** A piece by its number or its file name (with or without music/ and .mp3). */
      public static function find(q:String):Object
      {
         q = q.replace(/^\s+|\s+$/g, "");
         var list:Array = all();
         if (/^[0-9]+$/.test(q)) return list[int(q) - 1];
         var file:String = q.replace(/^music\//, "").replace(/\.mp3$/, "");
         for each (var o:Object in list) if (o.file == "music/" + file + ".mp3" || o.name == q) return o;
         return null;
      }

      public function MusicPicker(onPick:Function, onClose:Function)
      {
         super();
         this.onPick = onPick;
         graphics.beginFill(0xEAF6FF, 1);
         graphics.lineStyle(2, 0x5AA8E0);
         graphics.drawRoundRect(0, 0, W, H, 16, 16);
         graphics.endFill();
         var close:Sprite = RUI.smallButton("×", onClose, 28, 22, "musicPickerClose");
         close.x = W - 36;
         close.y = 6;
         addChild(close);
         show(0);
      }

      private function show(n:int):void
      {
         if (page != null) removeChild(page);
         page = new Sprite();
         addChildAt(page, 0);
         var list:Array = all();
         var pages:int = Math.ceil(list.length / PAGE);
         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = "选一首音乐  " + (n + 1) + "/" + pages;
         t.x = 14;
         t.y = 8;
         page.addChild(t);
         for (var i:int = 0; i < PAGE && n * PAGE + i < list.length; i++)
         {
            var o:Object = list[n * PAGE + i];
            var b:Sprite = RUI.button(o.id + " " + o.name, pick(o), 136, 20, 0x8ED0FA, 0x3C96DC, "pickMusic" + o.id);
            b.x = 12 + (i % 3) * 140;
            b.y = 36 + int(i / 3) * 24;
            page.addChild(b);
         }
         if (n > 0) page.addChild(at(RUI.button("上一页", function():void { show(n - 1); }, 70, 22, 0xFFC45A, 0xF07812, "musicPrev"), 12, H - 32));
         if (n < pages - 1) page.addChild(at(RUI.button("下一页", function():void { show(n + 1); }, 70, 22, 0xFFC45A, 0xF07812, "musicNext"), W - 82, H - 32));
      }

      private function pick(o:Object):Function
      {
         return function():void { onPick(o); };
      }

      private static function at(s:Sprite, x:int, y:int):Sprite
      {
         s.x = x;
         s.y = y;
         return s;
      }
   }
}
