package mmo.house.b000247
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REBUILT: the 家园's 经验分配器. The HELLO keeps the experience tasks
    * reward (麦哲伦: "HELLO会帮你把奖励的经验分给亚比"); here it goes to the
    * 亚比 of the bag. The 2012 panel is lost; the commands are the era
    * RobotClient's: getExp (RobotExtension 2-12 -> {exp}) and giveExp
    * (2-13 {pi, e} -> {res, exp}), the 亚比 growing as in a battle. Drawn in
    * the look of the rebuilt panels.
    */
   public class ExpPanel extends Sprite
   {
      private static const W:int = 500;
      private static const H:int = 400;
      private static var current:ExpPanel;

      private var box:Sprite;
      private var pool:TextField;
      private var said:TextField;
      private var list:Sprite;
      private var exp:int;

      public static function show():void
      {
         if (current != null) current.close();
         current = new ExpPanel();
         LayerManager.getBaseTop().addChild(current);
      }

      public function ExpPanel()
      {
         super();
         name = "expPanel";
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "经验分配器", close, "expClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         pool = RUI.text(15, RUI.BLUE, true);
         pool.x = 24;
         pool.y = 54;
         box.addChild(pool);
         box.addChild(RUI.well(16, 84, W - 32, 252));
         list = new Sprite();
         list.x = 26;
         list.y = 92;
         box.addChild(list);
         said = RUI.text(12, 0x8A3B00, true, W - 40);
         said.x = 20;
         said.y = 346;
         box.addChild(said);
         SocketClient.instance.addEventListener("2-12", onExp);
         SocketClient.instance.addEventListener("2-13", onGiven);
         SocketClient.instance.sendXtMessage("RobotExtension", "2-12", {});
         draw();
      }

      private function onExp(e:SocketClientEvent):void
      {
         exp = int(e.params.exp);
         draw();
      }

      private function onGiven(e:SocketClientEvent):void
      {
         exp = int(e.params.exp);
         var r:int = int(e.params.res);
         said.text = r == 1 ? "分给了亚比 " + int(e.params.e) + " 点经验。" : r == -2 ? "HELLO 没有那么多经验。" : "背包里没有这只亚比。";
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("exp refresh", err); }
         draw();
      }

      private function draw():void
      {
         pool.text = "HELLO 保管的经验：" + exp;
         while (list.numChildren) list.removeChildAt(0);
         var pets:Array = [];
         try
         {
            var svc:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
            if (svc) pets = svc.getMyPets() || [];
         }
         catch (e:Error) { RLog.error("exp pets", e); }
         for (var i:int = 0; i < pets.length && i < 6; i++)
         {
            var p:PetBriefInfo = pets[i] as PetBriefInfo;
            if (p == null) continue;
            var row:Sprite = new Sprite();
            row.y = i * 40;
            var t:TextField = RUI.text(14, RUI.BLUE, true);
            t.text = p.name + "  Lv" + p.level;
            t.y = 6;
            row.addChild(t);
            var amounts:Array = [100, 1000, 10000];
            for (var k:int = 0; k < amounts.length; k++)
            {
               var b:Sprite = RUI.button("+" + amounts[k], give(p.id, amounts[k]), 66, 26, 0xFFC45A, 0xF07812, "expGive_" + p.id + "_" + amounts[k]);
               b.x = 186 + k * 72;
               b.y = 4;
               row.addChild(b);
            }
            list.addChild(row);
         }
         if (pets.length == 0) said.text = "背包里没有亚比。";
         else if (!said.text) said.text = exp > 0 ? "选一只亚比，把经验分给它。" : "完成任务时 HELLO 会得到经验，再来这里分给亚比吧。";
      }

      private function give(id:int, amount:int):Function
      {
         return function():void
         {
            var e:int = Math.min(amount, exp);
            if (e <= 0)
            {
               said.text = "HELLO 现在没有经验可以分。";
               return;
            }
            SocketClient.instance.sendXtMessage("RobotExtension", "2-13", {pi: id, e: e});
         };
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("2-12", onExp);
         SocketClient.instance.removeEventListener("2-13", onGiven);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
