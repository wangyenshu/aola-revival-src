package mmo.task140
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.filters.GlowFilter;
   import flash.geom.Rectangle;
   import mmo.framework.comm.RobotClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.revival.RComic;
   import mmo.revival.task.TaskScript;

   /**
    * REBUILT taskext/task140 (version 130117): 贝鲁特博士的指导. The 2013
    * script is lost (the copy under its URL teaches healing instead). The
    * steps are those of the task panel taskpanel/tp140 and the era copy
    * scenes, which point the way while they are being done (sciencecopy: to
    * 亚比研究中心 for 142/144, to HELLO学院 for 146/147; starlandcopy and
    * toolshopcopy: to 米娜 for 143); 米娜's "买亚比球就来找我吧！" and the
    * catching hint are from the screenshots of the December 2011
    * walkthrough; the rest of the words are RECONSTRUCTED. Era film:
    * task152res_hellouse0–2 (what the HELLO can do).
    *
    *   142  亚比研究中心 (yabistudy, standing in for yabistudycopy): 贝鲁特
    *   143  道具店 copy: buy 5 普通亚比球 from 米娜
    *   144  贝鲁特 teaches catching
    *   145  艾夕区 冰河瀑布 (aixiscene2): catch a 朵朵兔
    *   146  HELLO学院 copy: 普伦博士 gives the HELLO (RobotClient.addRobot)
    *   147  普伦博士 shows what the HELLO can do; back to 麦哲伦 (task 150)
    */
   public class Task140Initialler extends TaskScript
   {
      /** 贝鲁特's place in the 亚比研究中心 (he has none in the later NPC data). */
      private static const BEIRUT:Array = [11, 1, 300, 330];
      private static const DUODUOTU:int = 10;
      private static const BALL:int = 32;
      private var arrow:DisplayObject;

      public function Task140Initialler()
      {
         super(140);
      }

      override public function init():void
      {
         onFightEnd(fightEnded);
         super.init();
      }

      override public function dispose():void
      {
         if (arrow && arrow.parent) arrow.parent.removeChild(arrow);
         arrow = null;
         super.dispose();
      }

      override protected function refresh():void
      {
         var s:String = scene;
         switch (step)
         {
            case 142:
               if (s == "yabistudy") beirut("142", <config>
                     <context npcId="11" iconId="1" str="哈！你就是#username#吧！欢迎来到亚比研究中心！">
                        <choice str="贝鲁特博士好！">
                           <context npcId="11" iconId="1" str="想要拥有更多的亚比伙伴，就要学会捕捉亚比。捕捉亚比要用到亚比球。"/>
                           <context npcId="11" iconId="1" str="你先去流星购物街的道具店，找米娜买5个亚比球吧！">
                              <choice str="好的，我这就去！" taskId="142" nextScene="starlandcopy"/>
                           </context>
                        </choice>
                     </context>
                  </config>);
               break;
            case 143:
               if (s == "toolshopcopy" || s == "toolshop")
               {
                  var mina:int = s == "toolshopcopy" ? 301 : 3;
                  var x:XML = <config>
                        <context npcId="301" str="买亚比球就来找我吧！">
                           <choice str="我要买5个亚比球！" action="t143_buy"/>
                           <choice str="我再看看。"/>
                        </context>
                     </config>;
                  x.context.@npcId = mina;
                  setTalk(mina, x);
               }
               break;
            case 144:
               if (s == "yabistudy") beirut("144", <config>
                     <context npcId="11" iconId="1" str="亚比球都买回来了吗？很好！现在我来教你捕捉亚比的技巧。">
                        <choice str="请博士指教！">
                           <context npcId="11" iconId="1" str="在战斗中，先削弱对方亚比的体力。对方亚比的体力越少，捕捉就越容易成功！"/>
                           <context npcId="11" iconId="1" str="然后点击「捕捉」，选好亚比球扔出去就可以啦！">
                              <choice str="我记住了！" taskId="144"/>
                           </context>
                        </choice>
                     </context>
                  </config>);
               break;
            case 145:
               if (s == "yabistudy") beirut("145", <config>
                     <context npcId="11" iconId="1" str="学会捕捉亚比，就要去实践一下了！到异空间艾夕区的冰河瀑布，捉一只朵朵兔试试吧！">
                        <choice str="出发！" nextScene="aixiscene2"/>
                     </context>
                  </config>);
               else if (s == "aixiscene2")
               {
                  sayOnce("145hint", 1, <config>
                        <context npcId="1" str="朵朵兔很容易捕捉，扔扔亚比球就可以！点它一下就能开始战斗，先打掉它一些体力再捕捉吧。">
                           <choice str="知道了！"/>
                        </context>
                     </config>);
                  pointAtDuoduotu(20);
               }
               break;
            case 146:
               if (s == "helloschoolcopy" || s == "helloschool") prof("146", s, <config>
                     <context npcId="300" str="你就是#username#吧？我是HELLO学院的院长普伦博士。">
                        <choice str="普伦博士好！">
                           <context npcId="300" str="HELLO是奥拉星上一种特殊的生物，以奥拉能量晶石为食。它们在HELLO学院学习以后，能帮助奥拉人照顾和训练亚比。"/>
                           <context npcId="300" str="这只HELLO以后就跟着你啦，它会是你的小管家和生活小帮手！">
                              <choice str="谢谢普伦博士！" action="t146_hello"/>
                           </context>
                        </choice>
                     </context>
                  </config>);
               else if (s == "aixiscene2") sayOnce("146go", 11, <config>
                     <context npcId="11" iconId="1" str="干得好，你已经学会捕捉亚比了！去科学院的HELLO学院看看普伦博士想要教给你些什么吧！">
                        <choice str="好的！" nextScene="sciencecopy"/>
                     </context>
                  </config>);
               break;
            case 147:
               if (s == "helloschoolcopy" || s == "helloschool") prof("147", s, <config>
                     <context npcId="300" str="对了，HELLO还会帮你把战斗中获得的经验分配给亚比哦！">
                        <choice str="真的吗？快教教我！" action="t147_comic"/>
                     </context>
                  </config>);
               break;
         }
      }

      private function beirut(key:String, xml:XML):void
      {
         addNpc(BEIRUT[0], BEIRUT[1], BEIRUT[2], BEIRUT[3]);
         setTalk(11, xml);
         delay(600, function():void { sayOnce(key, 11, xml); });
      }

      /** 普伦博士: the newbie copy NPC 300 in helloschoolcopy, the NPC 14 in helloschool. */
      private function prof(key:String, s:String, xml:XML):void
      {
         var id:int = s == "helloschoolcopy" ? 300 : 14;
         for each (var c:XML in xml..context) c.@npcId = id;
         setTalk(id, xml);
         delay(600, function():void { sayOnce(key, id, xml); });
      }

      override protected function onAction(a:String):void
      {
         switch (a)
         {
            case "t143_buy":
               buyBalls();
               break;
            case "t146_hello":
               RobotClient.instance.addRobot();
               delay(400, function():void { finish(146); });
               break;
            case "t147_comic":
               var c:int = color();
               var id:int = scene == "helloschoolcopy" ? 300 : 14;
               RComic.play("taskres/task152res_hellouse" + c, "mmo.task152.HelloUseMc" + c, function():void
               {
                  var x:XML = <config>
                        <context npcId="300" str="学会了吗？好了，快去指挥中心向司令官麦哲伦报告吧！">
                           <choice str="是！" taskId="147" nextScene="maintown2"/>
                        </context>
                     </config>;
                  x.context.@npcId = id;
                  say(id, x);
               });
               break;
         }
      }

      private function ballsOwned():int
      {
         try
         {
            var items:IItemService = ServiceContainer.getService(IItemService) as IItemService;
            var u:UserItem = items ? items.getMyItemById(BALL) : null;
            return u ? u.quantity : 0;
         }
         catch (e:Error) {}
         return 0;
      }

      private function buyBalls():void
      {
         var mina:int = scene == "toolshopcopy" ? 301 : 3;
         var done:Function = function():void
         {
            var x:XML = <config>
                  <context npcId="301" str="5个亚比球收好啦！快回亚比研究中心找贝鲁特博士吧！">
                     <choice str="谢谢米娜！" taskId="143" nextScene="sciencecopy"/>
                  </context>
               </config>;
            x.context.@npcId = mina;
            say(mina, x);
         };
         if (ballsOwned() >= 5)
         {
            done();
            return;
         }
         ServiceContainer.instance.tryGetBuyMaterialService(2, function(svc:IBuyMaterial, o:Object):void
         {
            svc.logSourceKey("task143");
            svc.buy(new BuyMaterialInfo(2, BALL, 5, 1), function(ok:Boolean):void
            {
               if (ok) done();
            });
         });
      }

      /**
       * A red arrow bobbing over a wild 朵朵兔, once one stands in the scene
       * (drawn after the arrow of the era film task145res_petinscene, whose
       * own 亚比 is another one).
       */
      private function pointAtDuoduotu(tries:int):void
      {
         if (arrow != null && arrow.parent != null) return;
         var pet:DisplayObjectContainer = wildPet(DUODUOTU) as DisplayObjectContainer;
         if (pet == null)
         {
            if (tries > 0) delay(1000, function():void { pointAtDuoduotu(tries - 1); });
            return;
         }
         var a:Sprite = new Sprite();
         a.mouseEnabled = a.mouseChildren = false;
         var g:Graphics = a.graphics;
         g.lineStyle(3, 0xFFFFFF);
         g.beginFill(0xE8251E);
         g.moveTo(-8, -30); g.lineTo(8, -30); g.lineTo(8, -14); g.lineTo(16, -14); g.lineTo(0, 0); g.lineTo(-16, -14); g.lineTo(-8, -14); g.lineTo(-8, -30);
         g.endFill();
         a.filters = [new GlowFilter(0x8A0000, 0.8, 4, 4, 2)];
         var top:Number = topOf(pet, a);
         a.y = top - 8;
         var t:int = 0;
         a.addEventListener(Event.ENTER_FRAME, function(e:Event):void
         {
            t++;
            // The 亚比's art may come later (or its stand-in): follow its top.
            if (t % 12 == 0) top = topOf(pet, a);
            a.y = top - 8 - Math.abs(Math.sin(t / 5)) * 10;
         });
         pet.addChild(a);
         arrow = a;
      }

      /** The top of what the 亚比 shows, leaving out the arrow itself. */
      private static function topOf(pet:DisplayObjectContainer, arrow:DisplayObject):Number
      {
         var top:Number = 0;
         for (var i:int = 0; i < pet.numChildren; i++)
         {
            var c:DisplayObject = pet.getChildAt(i);
            if (c == arrow || !c.visible) continue;
            var b:Rectangle = c.getBounds(pet);
            if (b.height > 0 && b.top < top) top = b.top;
         }
         return top;
      }

      private function fightEnded(r:Object):void
      {
         if (step != 145) return;
         if (r.isCatched && int(r.raceId) == DUODUOTU)
         {
            if (arrow && arrow.parent) arrow.parent.removeChild(arrow);
            arrow = null;
            finish(145);
         }
         else delay(1500, function():void { pointAtDuoduotu(5); });
      }
   }
}
