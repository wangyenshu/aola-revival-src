package mmo.zoo.revival
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.TipsManager;
   import mmo.loader.layer.LayerManager;

   /**
    * REBUILT panel of one animal of the zoo: the era PetOperatationPanel (zoo/petbreedingservice)
    * on its art: its name and stars, 成长时间 (what is left), 收获经验, 变异亚比, and the buttons
    * 收获 (grown: 97_7), 道具 (the 饲料: the zoo's rebuilt list), 玩耍 (the 饲料机's free feed,
    * 97_12) and 放生 (97_6). The later 珍藏品 half of the art (treasures to steal) is put away.
    */
   public class AnimalPanel extends MovieClip
   {
      public var btn1:SimpleButton;
      public var btn2:SimpleButton;
      public var btn3:SimpleButton;
      public var btn4:SimpleButton;
      public var star:MovieClip;
      public var mctrea:MovieClip;
      public var mccannotsteal:MovieClip;
      public var txtName:TextField;
      public var txtTime:TextField;
      public var txtExperience:TextField;
      public var txtMutant:TextField;

      private static var current:AnimalPanel;

      private var data:Object;
      private var mine:Boolean;
      private var onAction:Function;

      /** a: {id, raceId, mature, left (s), rate} of 97_4; at: the animal's head on the stage; onAction(what, reply). */
      public static function show(a:Object, mine:Boolean, at:Point, onAction:Function):void
      {
         hide();
         current = new AnimalPanel(a, mine, onAction);
         LayerManager.getBaseTop().addChild(current);
         current.x = Math.round(Math.max(-100, Math.min(960 - 300, at.x - 195)));
         current.y = Math.round(Math.max(0, Math.min(560 - 160, at.y - 150)));
      }

      public static function hide():void
      {
         if (current != null && current.parent != null) current.parent.removeChild(current);
         if (current != null) current.unhook();
         current = null;
      }

      public function AnimalPanel(a:Object, mine:Boolean, onAction:Function)
      {
         super();
         stop();
         data = a;
         this.mine = mine;
         this.onAction = onAction;
         name = "zooAnimalPanel";
         ZooKit.hide(mctrea);
         ZooKit.hide(mccannotsteal);
         for (var i:int = 0; i < numChildren; i++)
         {
            var d:DisplayObject = getChildAt(i);
            if (d.getBounds(this).right <= 104) d.visible = false; // the 珍藏品 half: its plate and title
         }
         var race:int = int(a.raceId);
         var grown:Boolean = Boolean(a.mature);
         var animal:Object = ZooKit.animal(race);
         txtName.text = ZooKit.nameOf(race, grown) + (grown ? "(成年)" : "(幼仔)");
         txtTime.text = ZooKit.hoursText(grown ? 0 : int(a.left));
         txtExperience.text = animal ? String(animal.exp) : "";
         txtMutant.text = mutation(animal, int(a.rate));
         if (star != null) star.gotoAndStop(Math.max(1, animal ? int(animal.starNum) : 1));
         var tips:Array = ["收获", "道具", "玩耍", "放生"];
         var ok:Array = [mine && grown, mine && !grown, mine && !grown, mine];
         var why:Array = [mine ? "小动物还在成长中，不能收获哦！" : "你不能收获别人的动物哦！", "", "", ""];
         for (i = 1; i <= 4; i++)
         {
            var b:SimpleButton = this["btn" + i] as SimpleButton;
            if (ok[i - 1])
            {
               TipsManager.getInstance().addTips(b, tips[i - 1]);
               b.addEventListener(MouseEvent.CLICK, onButton);
            }
            else
            {
               DisplayUtil.applyGray(b);
               if (why[i - 1]) TipsManager.getInstance().addTips(b, why[i - 1]);
               else b.mouseEnabled = false;
            }
         }
         addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         LayerManager.stage.addEventListener(MouseEvent.MOUSE_DOWN, onOutside);
      }

      private static function mutation(animal:Object, rate:int):String
      {
         if (animal == null) return "";
         var names:Array = animal.evoNameArr as Array || [];
         var rates:Array = animal.evoRateArr as Array || [];
         var out:Array = [];
         for (var i:int = 0; i < names.length; i++) out.push(names[i] + "(" + (i == 0 && rate > 0 ? rate : int(rates[i])) + "%)");
         return out.join("\n");
      }

      private function onButton(e:MouseEvent):void
      {
         e.stopPropagation();
         var i:int = int(String(e.currentTarget.name).substr(3));
         var id:int = int(data.id);
         var act:Function = onAction;
         if (i == 1) ZooKit.ask("97_7", {id: id}, function(p:Object):void { act("harvest", p); });
         else if (i == 2) act("items", null);
         else if (i == 3) ZooKit.ask("97_12", {id: id, itemId: 0}, function(p:Object):void { act("feed", p); });
         else if (i == 4)
         {
            var d:ModalDialog = NewDialog.getCofirmDialog("放生以后它就回到大自然了，你确定吗？", null, null, NewDialog.getSucceedIcon());
            d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void { ZooKit.ask("97_6", {id: id}, function(p:Object):void { act("drop", p); }); });
            d.show();
         }
         hide();
      }

      private function onOutside(e:MouseEvent):void
      {
         hide();
      }

      private function unhook():void
      {
         LayerManager.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onOutside);
         for (var i:int = 1; i <= 4; i++) TipsManager.getInstance().removeTips(this["btn" + i]);
      }
   }
}
