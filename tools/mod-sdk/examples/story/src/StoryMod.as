package
{
   import flash.display.Sprite;
   import flash.events.Event;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModNpc;
   import mmo.revival.mod.IModRoom;

   /**
    * A short story in two rooms: a keeper asks for help, a film shows the
    * light going out, an opponent guards the lighthouse, and the reward is a
    * 亚比 of the game. Progress is kept with getData / setData, so the story
    * goes on where it was left.
    */
   public class StoryMod extends Sprite implements IMod
   {
      private var game:IModGame;

      public function get info():Object
      {
         return {id: "lighthouse", name: "灯塔的故事", author: "aola-revival", version: "1.0",
            description: "两个房间、对话和选择、一段动画、一场挑战和奖励。"};
      }

      public function start(game:IModGame):void
      {
         this.game = game;
         game.room("shore", {
            name: "海边小路",
            background: Shore,
            walk: function(x:Number, y:Number):Boolean { return y < 360; },
            music: "music/themeparknew4.mp3",
            spawns: {start: [140, 470], fromLighthouse: [820, 440]},
            build: buildShore
         });
         game.room("lighthouse", {
            name: "灯塔下",
            background: Lighthouse,
            width: 1400,
            walk: function(x:Number, y:Number):Boolean { return y < 380 || (x > 560 && x < 840 && y < 470); },
            spawns: {start: [160, 470]},
            build: buildLighthouse
         });
         game.enter(game.getData("step") >= 2 ? "lighthouse" : "shore");
      }

      private function buildShore(room:IModRoom):void
      {
         var keeper:IModNpc = room.npc({
            name: "守灯人老海",
            look: Keeper,
            x: 460,
            y: 440,
            onClick: function():void { talkToKeeper(keeper); }
         });
         if (int(game.getData("step")) == 0) keeper.say("灯塔……灯塔不亮了！", 4);
         room.door(860, 360, 100, 150, "灯塔", function():void
         {
            if (int(game.getData("step")) < 1) keeper.say("先听我说完！", 3);
            else game.enter("lighthouse");
         });
         room.door(0, 380, 70, 150, "离开", function():void { game.leave(); });
      }

      private function talkToKeeper(keeper:IModNpc):void
      {
         var step:int = int(game.getData("step"));
         if (step >= 3)
         {
            keeper.talk(["谢谢你，#username#！灯塔又亮起来了。"]);
            return;
         }
         if (step >= 1)
         {
            keeper.talk(["灯塔就在东边，小心守在那里的家伙。"]);
            return;
         }
         keeper.talk([
            "#username#，你来得正好。",
            "昨天夜里，灯塔的灯忽然灭了，有个家伙占了灯塔。",
            {text: "你愿意帮我把灯塔夺回来吗？", choices: [
               ["交给我吧！", function():void
               {
                  game.film(new LightOut(), function():void
                  {
                     game.setData("step", 1);
                     keeper.say("灯塔在东边！", 4);
                  });
               }],
               ["我再想想。", function():void { keeper.say("……", 2); }]
            ]}
         ]);
      }

      private function buildLighthouse(room:IModRoom):void
      {
         room.door(0, 380, 80, 150, "海边", function():void { game.enter("shore", "fromLighthouse"); });
         if (int(game.getData("step")) >= 3)
         {
            room.add(new Beam(), 700, 120, "front");
            return;
         }
         game.setData("step", 2);
         // An opponent dressed as 火霍仔 (48) with a team of the game's 亚比: 火丁 (46), then 熔炎怪 (15).
         var guard:IModNpc = room.foe({
            name: "灯塔霸主",
            look: 48,
            boss: true,
            x: 700,
            y: 450,
            team: [{race: 46, level: 12}, {race: 15, level: 18, hp: 150}],
            onWin: function():void
            {
               game.setData("step", 3);
               room.add(new Beam(), 700, 120, "front");
               game.talk({name: "守灯人老海", picture: Keeper}, [
                  "灯塔又亮了！这只亚比送给你，它一直想跟着勇敢的人。"
               ], function():void { game.givePet(1, 10); });
            },
            onLose: function():void { game.message("再试一次吧！"); }
         });
         guard.say("这座灯塔归我了！", 4);
      }
   }
}

import flash.display.GradientType;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;

/** The pictures, drawn in code. */
class Shore extends Sprite
{
   public function Shore()
   {
      var m:Matrix = new Matrix();
      m.createGradientBox(960, 300, Math.PI / 2);
      graphics.beginGradientFill(GradientType.LINEAR, [0x1E3C72, 0x6A9BD8], [1, 1], [0, 255], m);
      graphics.drawRect(0, 0, 960, 300);
      graphics.endFill();
      graphics.beginFill(0x2C6FB0);
      graphics.drawRect(0, 300, 960, 70);
      graphics.endFill();
      m.createGradientBox(960, 190, Math.PI / 2, 0, 370);
      graphics.beginGradientFill(GradientType.LINEAR, [0xF1D9A0, 0xD9B56A], [1, 1], [0, 255], m);
      graphics.drawRect(0, 360, 960, 200);
      graphics.endFill();
      graphics.beginFill(0xFFFFFF, 0.8);
      for (var i:int = 0; i < 30; i++) graphics.drawCircle((i * 157) % 960, (i * 53) % 260, 1.5);
      graphics.endFill();
   }
}

class Lighthouse extends Sprite
{
   public function Lighthouse()
   {
      var m:Matrix = new Matrix();
      m.createGradientBox(1400, 380, Math.PI / 2);
      graphics.beginGradientFill(GradientType.LINEAR, [0x0F1F3D, 0x3A5F8F], [1, 1], [0, 255], m);
      graphics.drawRect(0, 0, 1400, 380);
      graphics.endFill();
      graphics.beginFill(0x7A7F87);
      graphics.drawRect(0, 380, 1400, 180);
      graphics.endFill();
      graphics.beginFill(0xEEEEEE);
      graphics.moveTo(640, 380);
      graphics.lineTo(670, 110);
      graphics.lineTo(730, 110);
      graphics.lineTo(760, 380);
      graphics.endFill();
      graphics.beginFill(0xC0392B);
      graphics.drawRect(652, 200, 96, 30);
      graphics.drawRect(645, 290, 110, 30);
      graphics.endFill();
      graphics.beginFill(0x333333);
      graphics.drawRect(660, 80, 80, 30);
      graphics.endFill();
   }
}

class Keeper extends Sprite
{
   public function Keeper()
   {
      graphics.beginFill(0x000000, 0.2);
      graphics.drawEllipse(-22, -6, 44, 12);
      graphics.endFill();
      graphics.beginFill(0x2D4C7C);
      graphics.drawRoundRect(-20, -72, 40, 64, 12, 12);
      graphics.endFill();
      graphics.beginFill(0xF2D2B0);
      graphics.drawCircle(0, -90, 22);
      graphics.endFill();
      graphics.beginFill(0xDDDDDD);
      graphics.drawEllipse(-20, -82, 40, 22);
      graphics.endFill();
      graphics.beginFill(0x1B2A44);
      graphics.drawRect(-24, -116, 48, 10);
      graphics.drawRect(-16, -130, 32, 16);
      graphics.endFill();
   }
}

/** The light of the lighthouse, back on (it turns). */
class Beam extends Sprite
{
   public function Beam()
   {
      graphics.beginFill(0xFFF2A8, 0.45);
      graphics.moveTo(0, 0);
      graphics.lineTo(420, -60);
      graphics.lineTo(420, 60);
      graphics.endFill();
      graphics.beginFill(0xFFF8D0);
      graphics.drawCircle(0, 0, 16);
      graphics.endFill();
      mouseEnabled = false;
      addEventListener(Event.ENTER_FRAME, function(e:Event):void { rotation += 2; });
   }
}

/**
 * A film drawn in code: the light of the lighthouse flickers and goes out, then a shadow
 * comes. It tells the end with Event.COMPLETE (IModGame.film waits for it).
 */
class LightOut extends Sprite
{
   private var t:int;
   private var light:Shape = new Shape();
   private var shadow:Shape = new Shape();

   public function LightOut()
   {
      graphics.beginFill(0x0A1428);
      graphics.drawRect(0, 0, 960, 560);
      graphics.endFill();
      graphics.beginFill(0xDDDDDD);
      graphics.moveTo(440, 520);
      graphics.lineTo(465, 200);
      graphics.lineTo(495, 200);
      graphics.lineTo(520, 520);
      graphics.endFill();
      light.graphics.beginFill(0xFFF2A8);
      light.graphics.drawCircle(480, 190, 30);
      light.graphics.endFill();
      addChild(light);
      shadow.graphics.beginFill(0x000000);
      shadow.graphics.drawEllipse(-60, -90, 120, 180);
      shadow.graphics.endFill();
      shadow.x = 1100;
      shadow.y = 420;
      addChild(shadow);
      addEventListener(Event.ENTER_FRAME, frame);
   }

   private function frame(e:Event):void
   {
      t++;
      if (t < 50) light.alpha = (t % 6 < 3) ? 1 : 0.3;
      else light.alpha = Math.max(0, 1 - (t - 50) / 10);
      if (t > 50) shadow.x += (600 - shadow.x) * 0.08;
      if (t >= 110)
      {
         removeEventListener(Event.ENTER_FRAME, frame);
         dispatchEvent(new Event(Event.COMPLETE));
      }
   }
}
