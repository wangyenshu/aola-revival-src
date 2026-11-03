package
{
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModNpc;
   import mmo.revival.mod.IModRoom;

   /**
    * The smallest mod: one room drawn in code, a character who talks and asks a
    * question, and a door out; in a team, a wave to the others. Build it with
    *   node tools/mod-sdk/build.mjs tools/mod-sdk/examples/hello
    * and load bin/hello.swf in the game's 沙盒 → 模组 → 导入模组.
    */
   public class HelloMod extends Sprite implements IMod
   {
      private var game:IModGame;
      /** The gardener of the room shown. */
      private var guide:IModNpc;

      public function get info():Object
      {
         return {id: "hello", name: "你好，沙盒", author: "aola-revival", version: "1.0",
            description: "一个房间、一个会说话的角色和一扇门。"};
      }

      public function start(game:IModGame):void
      {
         this.game = game;
         game.room("garden", {
            name: "小花园",
            background: Garden,
            // Only the lawn (below the fence) may be walked on.
            walk: function(x:Number, y:Number):Boolean { return y < 330; },
            music: "music/themeparknew4.mp3",
            spawns: {start: [200, 450]},
            build: buildGarden
         });
         // A team member's wave (listen once, in start: a room's build runs each time it is shown).
         if (game.apiVersion >= 3)
            game.onTeam("wave", function(from:String, data:*):void { if (guide != null) guide.say(from + "向大家挥手：" + data.text, 4); });
         game.enter("garden");
      }

      private function buildGarden(room:IModRoom):void
      {
         guide = room.npc({
            name: "园丁小星",
            look: Gardener,
            x: 620,
            y: 420,
            onClick: function():void { talkToGuide(guide); }
         });
         guide.say("欢迎来到我的小花园！", 4);
         room.door(840, 340, 110, 150, "离开", function():void { game.leave(); });
         // 组队 (API 3, a shared server): a team plays this room together. The whole team is in
         // it, and a wave is seen by everyone who is.
         if (game.apiVersion >= 3 && game.team.length > 0)
         {
            room.door(40, 360, 110, 120, "向队友挥手", function():void
            {
               guide.say(game.playerName + "向大家挥手！", 4);
               game.sendTeam("wave", {text: "你们好！"});
            });
         }
      }

      private function talkToGuide(guide:IModNpc):void
      {
         var times:int = int(game.getData("visits")) + 1;
         game.setData("visits", times);
         guide.talk([
            "#username#，你好！这是你第" + times + "次来看我。",
            {text: "你喜欢这里的花吗？", choices: [
               ["喜欢！", function():void { guide.say("太好了！", 3); }],
               ["还好吧……", function():void { guide.say("那我再多种一些。", 3); }]
            ]}
         ]);
      }
   }
}

import flash.display.GradientType;
import flash.display.Sprite;
import flash.geom.Matrix;

/** The room's picture, drawn in code: sky, a fence and a lawn with flowers (960 × 560). */
class Garden extends Sprite
{
   public function Garden()
   {
      var m:Matrix = new Matrix();
      m.createGradientBox(960, 330, Math.PI / 2);
      graphics.beginGradientFill(GradientType.LINEAR, [0x7EC8F2, 0xD8F1FF], [1, 1], [0, 255], m);
      graphics.drawRect(0, 0, 960, 330);
      graphics.endFill();
      m.createGradientBox(960, 230, Math.PI / 2, 0, 330);
      graphics.beginGradientFill(GradientType.LINEAR, [0x8ED65A, 0x4FA83A], [1, 1], [0, 255], m);
      graphics.drawRect(0, 330, 960, 230);
      graphics.endFill();
      graphics.lineStyle(4, 0xB07A40);
      for (var x:int = 0; x < 960; x += 40)
      {
         graphics.moveTo(x, 330);
         graphics.lineTo(x, 280);
      }
      graphics.moveTo(0, 300);
      graphics.lineTo(960, 300);
      graphics.lineStyle();
      var colours:Array = [0xFF6F91, 0xFFD24A, 0xFFFFFF, 0xB18CFF];
      for (var i:int = 0; i < 40; i++)
      {
         var fx:Number = (i * 211) % 940 + 10, fy:Number = 350 + (i * 97) % 190;
         graphics.beginFill(colours[i % colours.length]);
         graphics.drawCircle(fx, fy, 5);
         graphics.endFill();
      }
   }
}

/** A character drawn in code, its feet at 0, 0. */
class Gardener extends Sprite
{
   public function Gardener()
   {
      graphics.beginFill(0x000000, 0.2);
      graphics.drawEllipse(-22, -6, 44, 12);
      graphics.endFill();
      graphics.beginFill(0x3D7FD6);
      graphics.drawRoundRect(-18, -70, 36, 62, 14, 14);
      graphics.endFill();
      graphics.beginFill(0xFFE0BD);
      graphics.drawCircle(0, -88, 22);
      graphics.endFill();
      graphics.beginFill(0x6B3E1E);
      graphics.drawEllipse(-30, -118, 60, 18);
      graphics.drawRect(-16, -128, 32, 16);
      graphics.endFill();
      graphics.beginFill(0x222222);
      graphics.drawCircle(-8, -90, 3);
      graphics.drawCircle(8, -90, 3);
      graphics.endFill();
   }
}
