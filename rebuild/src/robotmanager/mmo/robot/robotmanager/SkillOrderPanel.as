package mmo.robot.robotmanager
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.revival.RUI;

   /**
    * 亚比技能排序 of the HELLO menu: the order of a 亚比's four skills (the first is the one
    * the battle screen lists first). PetClient2.setSortSkill (54_21 {id, sks}: the skill ids
    * in their new order, "," between them). The era pet/petskillsort (2011) only picks the
    * 亚比 and leaves an empty page; this panel is RECONSTRUCTED.
    */
   public class SkillOrderPanel extends Sprite
   {
      private static var current:SkillOrderPanel;

      private var box:Sprite;
      private var list:Sprite = new Sprite();
      private var pet:PetBriefInfo;
      private var order:Array = [];
      private var title:TextField;

      public static function show():void
      {
         var data:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         if (data == null || data.getMyPets() == null || data.getMyPets().length == 0)
         {
            NewDialog.showMessage("你的亚比背包里没有亚比哦！");
            return;
         }
         if (current != null) current.close();
         current = new SkillOrderPanel(data.getMyPets());
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      public function SkillOrderPanel(pets:Array)
      {
         super();
         box = RUI.panel(420, 300, "亚比技能排序", close, "skillOrderClose");
         addChild(box);
         for (var i:int = 0; i < pets.length && i < 6; i++)
         {
            var p:PetBriefInfo = pets[i] as PetBriefInfo;
            var b:Sprite = RUI.button(p.nickname || p.name, pick(p), 110, 30, 0x8FE3FF, 0x1E8FE0, "skillOrderPet" + i);
            b.x = 22;
            b.y = 52 + i * 38;
            box.addChild(b);
         }
         title = RUI.text(14, 0x1B4F8A, true);
         title.x = 150;
         title.y = 50;
         box.addChild(title);
         list.x = 150;
         list.y = 80;
         box.addChild(list);
         var save:Sprite = RUI.button("保存顺序", onSave, 100, 30, 0xFFC45A, 0xF07812, "skillOrderSave");
         save.x = 230;
         save.y = 252;
         box.addChild(save);
         pick(pets[0] as PetBriefInfo)();
      }

      private function pick(p:PetBriefInfo):Function
      {
         return function():void
         {
            pet = p;
            order = (p.skills || []).concat();
            title.text = (p.nickname || p.name) + " 的技能：";
            draw();
         };
      }

      private function draw():void
      {
         while (list.numChildren > 0) list.removeChildAt(0);
         for (var i:int = 0; i < order.length; i++)
         {
            var s:SkillInfo = order[i] as SkillInfo;
            var t:TextField = RUI.text(13, 0x1B4F8A, false);
            t.text = (i + 1) + ". " + (s ? s.name : "");
            t.y = i * 40 + 4;
            list.addChild(t);
            if (i > 0)
            {
               var up:Sprite = RUI.smallButton("▲", move(i, -1), 30, 24, "skillOrderUp" + i);
               up.x = 150;
               up.y = i * 40;
               list.addChild(up);
            }
            if (i < order.length - 1)
            {
               var down:Sprite = RUI.smallButton("▼", move(i, 1), 30, 24, "skillOrderDown" + i);
               down.x = 186;
               down.y = i * 40;
               list.addChild(down);
            }
         }
      }

      private function move(i:int, d:int):Function
      {
         return function():void
         {
            var j:int = i + d;
            if (j < 0 || j >= order.length) return;
            var x:* = order[i];
            order[i] = order[j];
            order[j] = x;
            draw();
         };
      }

      private function onSave():void
      {
         if (pet == null) return;
         var ids:Array = [];
         for each (var s:SkillInfo in order) if (s != null) ids.push(s.id);
         SocketClient.instance.addEventListener(PetClient2.cmdResortSkill, onSaved);
         PetClient2.instance.setSortSkill(pet.id, ids.join(","));
      }

      private function onSaved(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(PetClient2.cmdResortSkill, onSaved);
         if (int(e.params.res) == 1)
         {
            PetClient.instance.viewAllPM();
            NewDialog.showSucceedMessage("技能顺序已经保存好了！");
         }
         else NewDialog.showFailMessage("技能顺序没有保存成功。");
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener(PetClient2.cmdResortSkill, onSaved);
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }
   }
}
