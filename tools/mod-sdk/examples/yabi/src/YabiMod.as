package
{
   import flash.display.Sprite;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModNpc;
   import mmo.revival.mod.IModRoom;

   /**
    * A 亚比 of the mod's own: 泡泡蛙 (900101), a water 亚比 drawn in code. The
    * game learns it with species() (its picture, attribute, stats and skills);
    * then it can stand in a room, be fought, and be given to the player, who
    * keeps it (it is put aside while the mod is not running).
    */
   public class YabiMod extends Sprite implements IMod
   {
      public static const FROG:int = 900101;
      private var game:IModGame;

      public function get info():Object
      {
         return {id: "bubblefrog", name: "新亚比：泡泡蛙", author: "aola-revival", version: "1.0",
            description: "模组自己的亚比：图片、属性、种族值和技能。"};
      }

      public function start(game:IModGame):void
      {
         this.game = game;
         game.species({
            id: FROG,
            name: "泡泡蛙",
            attr: 10,
            stats: [70, 60, 65, 80, 70, 75],
            skills: [[0, 1014], [4, 11014], [8, 1148], [12, 11004], [16, 11003]],
            icon: Frog
         }, function(ok:Boolean):void
         {
            if (!ok)
            {
               game.message("游戏没有接受泡泡蛙。");
               return;
            }
            game.room("pond", {
               name: "泡泡池塘",
               background: Pond,
               walk: function(x:Number, y:Number):Boolean { return y < 320 || (x > 330 && x < 650 && y > 380 && y < 470); },
               spawns: {start: [140, 480]},
               build: buildPond
            });
            game.enter("pond");
         });
      }

      private function buildPond(room:IModRoom):void
      {
         var scientist:IModNpc = room.npc({
            name: "研究员小蓝",
            look: Scientist,
            x: 220,
            y: 400,
            onClick: function():void
            {
               scientist.talk([
                  "这是我新发现的亚比：泡泡蛙！它是水属性的。",
                  game.getData("caught") ? "看来它很喜欢你。" : "能打败它的话，它就会跟你走哦。"
               ]);
            }
         });
         if (game.getData("caught"))
         {
            room.npc({name: "泡泡蛙", look: FROG, x: 760, y: 470});
         }
         else
         {
            var frog:IModNpc = room.foe({
               name: "野生的泡泡蛙",
               look: FROG,
               x: 760,
               y: 470,
               team: [{race: FROG, level: 15}],
               onWin: function():void
               {
                  game.setData("caught", true);
                  game.givePet(FROG, 5, function(ok:Boolean):void
                  {
                     if (ok) game.message("泡泡蛙跟你走了！打开「亚比」看看它吧。");
                  });
               }
            });
            frog.say("呱！", 3);
         }
         room.door(860, 340, 100, 150, "离开", function():void { game.leave(); });
      }
   }
}

import flash.display.GradientType;
import flash.display.Sprite;
import flash.geom.Matrix;

/** 泡泡蛙: its picture, about 150 high, its feet at 0, 0. */
class Frog extends Sprite
{
   public function Frog()
   {
      graphics.beginFill(0x000000, 0.2);
      graphics.drawEllipse(-55, -10, 110, 20);
      graphics.endFill();
      var m:Matrix = new Matrix();
      m.createGradientBox(120, 110, Math.PI / 2, -60, -115);
      graphics.beginGradientFill(GradientType.LINEAR, [0x7FD3FF, 0x2B8FD6], [1, 1], [0, 255], m);
      graphics.drawEllipse(-60, -115, 120, 110);
      graphics.endFill();
      graphics.beginFill(0xD9F3FF);
      graphics.drawEllipse(-35, -70, 70, 55);
      graphics.endFill();
      for each (var ex:int in [-28, 28])
      {
         graphics.beginFill(0x2B8FD6);
         graphics.drawCircle(ex, -118, 22);
         graphics.endFill();
         graphics.beginFill(0xFFFFFF);
         graphics.drawCircle(ex, -120, 15);
         graphics.endFill();
         graphics.beginFill(0x123456);
         graphics.drawCircle(ex + 3, -118, 7);
         graphics.endFill();
      }
      graphics.lineStyle(3, 0x123456);
      graphics.moveTo(-18, -88);
      graphics.curveTo(0, -76, 18, -88);
      graphics.lineStyle();
      graphics.beginFill(0xFFFFFF, 0.7);
      graphics.drawCircle(52, -140, 9);
      graphics.drawCircle(66, -158, 6);
      graphics.endFill();
   }
}

class Pond extends Sprite
{
   public function Pond()
   {
      var m:Matrix = new Matrix();
      m.createGradientBox(960, 320, Math.PI / 2);
      graphics.beginGradientFill(GradientType.LINEAR, [0x9BE3FF, 0xE6F8FF], [1, 1], [0, 255], m);
      graphics.drawRect(0, 0, 960, 320);
      graphics.endFill();
      graphics.beginFill(0x7CC85A);
      graphics.drawRect(0, 320, 960, 240);
      graphics.endFill();
      graphics.beginFill(0x3FA0D8);
      graphics.drawEllipse(330, 370, 330, 110);
      graphics.endFill();
      graphics.beginFill(0x8FD0F0, 0.6);
      graphics.drawEllipse(380, 390, 200, 50);
      graphics.endFill();
   }
}

class Scientist extends Sprite
{
   public function Scientist()
   {
      graphics.beginFill(0x000000, 0.2);
      graphics.drawEllipse(-22, -6, 44, 12);
      graphics.endFill();
      graphics.beginFill(0xFFFFFF);
      graphics.drawRoundRect(-20, -72, 40, 64, 10, 10);
      graphics.endFill();
      graphics.beginFill(0xFFE0BD);
      graphics.drawCircle(0, -90, 22);
      graphics.endFill();
      graphics.beginFill(0x2B5FA8);
      graphics.drawEllipse(-24, -116, 48, 24);
      graphics.endFill();
      graphics.lineStyle(2, 0x333333);
      graphics.drawCircle(-8, -90, 6);
      graphics.drawCircle(8, -90, 6);
   }
}
