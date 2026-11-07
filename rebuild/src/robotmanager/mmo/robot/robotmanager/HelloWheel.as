package mmo.robot.robotmanager
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.robot.IRobotService;
   import mmo.interfaces.task.ITaskService;
   import mmo.revival.RExpPanel;
   import mmo.revival.RLog;
   import mmo.revival.RTraining;

   /**
    * The HELLO's menu of December 2012 (a guide page of 百田's 新手 section shows it): a click
    * on one's own HELLO opens this wheel. In its middle the HELLO, its name, 资料 (its 基本资料,
    * robot/robotmes) and 服装 (HELLO物品's clothes, robot/robotitem); round it nine of its skills:
    *   HELLO回家 / 跟随   (RobotClient unFollow / follow; 回家 after the newbie quest)
    *   亚比治疗          every 亚比 of the bag back to full strength
    *   经验分配          the experience the HELLO keeps, to a 亚比 (RExpPanel, 2-12 / 2-13)
    *   亚比孵化          the 家园's 亚比孵化器 (PetHatchEgg)
    *   稀有亚比搜索仪     where the rare 亚比 come out (RareSearch: the era sceneres/rarepetpanel)
    *   亚比技能排序       the order of a 亚比's skills (SkillOrderPanel, PetClient2 54_21)
    *   远程亚比仓库       the 亚比仓库 (PetWareHouse), a 蓝宝石 skill
    *   技能替换          which learnt skills a 亚比 carries (the 亚比背包's 更换技能)
    *   亚比训练          the era pet/pettraining (2010; pet/petbetraining while some train)
    * The wheel's own art is lost: it is drawn here (plain circles and signs); the HELLO in its
    * middle is the game's own HELLO (RobotAvatar). RECONSTRUCTED after the guide's picture.
    */
   public class HelloWheel extends Sprite
   {
      private static var current:HelloWheel;

      private static const R_CENTER:int = 104;
      private static const R_RING:int = 178;
      private static const R_BUTTON:int = 40;

      private var nameText:TextField;
      private var owner:String;

      public static function show(owner:String, a:String, member:Boolean):void
      {
         if (current != null) current.close();
         current = new HelloWheel(owner, a, member);
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      public function HelloWheel(owner:String, a:String, member:Boolean)
      {
         super();
         this.owner = owner;
         drawCenter();
         var hello:RobotAvatar = new RobotAvatar(owner);
         hello.setView(a, member);
         hello.mouseEnabled = hello.mouseChildren = false;
         hello.scaleX = hello.scaleY = 1.5;
         hello.x = 0;
         hello.y = 8;
         addChild(hello);
         nameText = label("HELLO", 13, 0x1A4F8C, false);
         var plate:Sprite = new Sprite();
         var g:Graphics = plate.graphics;
         g.beginFill(0xF4FAFF);
         g.lineStyle(1.5, 0x5AA8E8);
         g.drawRoundRect(-58, -10, 116, 21, 18, 18);
         g.endFill();
         plate.y = 22;
         plate.mouseEnabled = false;
         addChild(plate);
         nameText.x = -nameText.width / 2;
         nameText.y = 13;
         addChild(nameText);
         addChild(roundButton("资料", "doc", -34, 62, 24, onInfo, 0xFFE9A8, 0xF2A33A));
         addChild(roundButton("服装", "shirt", 34, 62, 24, onClothes, 0xFFE9A8, 0xF2A33A));
         var following:Boolean = robots() != null && robots().getIsFollow();
         var skills:Array = [
            [following ? "HELLO回家" : "HELLO跟随", "house", following ? onGoHome : onFollow],
            ["亚比治疗", "cross", onHeal],
            ["经验分配", "split", onExp],
            ["亚比孵化", "egg", onHatch],
            ["稀有亚比\n搜索仪", "lens", onRare],
            ["亚比技能\n排序", "updown", onSort],
            ["远程亚比\n仓库", "box", onWarehouse],
            ["技能替换", "swap", onReplace],
            ["亚比训练", "dumbbell", onTrain]
         ];
         for (var i:int = 0; i < skills.length; i++)
         {
            var ang:Number = (-90 + i * 360 / skills.length) * Math.PI / 180;
            addChild(pointer(ang));
            addChild(roundButton(skills[i][0], skills[i][1], Math.cos(ang) * R_RING, Math.sin(ang) * R_RING, R_BUTTON, skills[i][2], 0x8FE3FF, 0x1E8FE0));
         }
         var close:Sprite = closeButton();
         close.x = R_RING + 30;
         close.y = -R_RING - 18;
         addChild(close);
         // Centred on the stage (ModalDialogManager puts the panel's top-left at the middle less half its size).
         SocketClient.instance.addEventListener(RobotClient.cmdGetRobot, onRobot);
         RobotClient.instance.getRobot();
      }

      private function onRobot(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(RobotClient.cmdGetRobot, onRobot);
         if (e.params.un && String(e.params.un) != owner) return;
         if (e.params.n) nameText.text = String(e.params.n);
         nameText.x = -nameText.width / 2;
      }

      // ---------------------------------------------------------------- drawing

      private function drawCenter():void
      {
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         var m:Matrix = new Matrix();
         m.createGradientBox(R_CENTER * 2, R_CENTER * 2, Math.PI / 2, -R_CENTER, -R_CENTER);
         g.lineStyle(6, 0xBFF1FF);
         g.beginGradientFill(GradientType.LINEAR, [0x46C8FF, 0x1C7FD8, 0x0F5DB8], [1, 1, 1], [0, 140, 255], m);
         g.drawCircle(0, 0, R_CENTER);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.18);
         g.drawEllipse(-R_CENTER * 0.75, -R_CENTER * 0.92, R_CENTER * 1.5, R_CENTER * 0.8);
         g.endFill();
         s.filters = [new GlowFilter(0x0A3C80, 0.6, 10, 10, 2)];
         addChild(s);
      }

      /** A small triangle between the middle and a skill, pointing out. */
      private function pointer(ang:Number):Shape
      {
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         var r:Number = R_CENTER + 14;
         var cx:Number = Math.cos(ang) * r, cy:Number = Math.sin(ang) * r;
         var nx:Number = Math.cos(ang), ny:Number = Math.sin(ang);
         g.beginFill(0x2EA8F0);
         g.moveTo(cx + nx * 9, cy + ny * 9);
         g.lineTo(cx - ny * 8, cy + nx * 8);
         g.lineTo(cx + ny * 8, cy - nx * 8);
         g.endFill();
         return s;
      }

      private function roundButton(text:String, sign:String, x:Number, y:Number, r:int, f:Function, light:uint, dark:uint):Sprite
      {
         var b:Sprite = new Sprite();
         var g:Graphics = b.graphics;
         var m:Matrix = new Matrix();
         m.createGradientBox(r * 2, r * 2, Math.PI / 2, -r, -r);
         g.lineStyle(3, 0xFFFFFF);
         g.beginGradientFill(GradientType.LINEAR, [light, dark], [1, 1], [0, 255], m);
         g.drawCircle(0, 0, r);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.25);
         g.drawEllipse(-r * 0.7, -r * 0.88, r * 1.4, r * 0.75);
         g.endFill();
         var icon:Shape = glyph(sign, r * (text.indexOf("\n") >= 0 ? 0.42 : 0.5));
         icon.y = -r * (text.indexOf("\n") >= 0 ? 0.32 : 0.22);
         b.addChild(icon);
         var t:TextField = label(text, r >= 30 ? 12 : 11, 0xFFFFFF, true);
         t.x = -t.width / 2;
         t.y = r * (text.indexOf("\n") >= 0 ? 0.02 : 0.2);
         t.filters = [new GlowFilter(0x0B3F7A, 1, 3, 3, 6)];
         b.addChild(t);
         b.x = x;
         b.y = y;
         b.buttonMode = true;
         b.mouseChildren = false;
         b.name = "hw_" + text.replace(/\n/g, "");
         b.filters = [new DropShadowFilter(2, 90, 0x06305E, 0.5, 4, 4)];
         b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { b.scaleX = b.scaleY = 1.08; });
         b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { b.scaleX = b.scaleY = 1; });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            try { f(); } catch (err:Error) { RLog.error("hello wheel " + text, err); }
         });
         return b;
      }

      /** Plain signs for the skills (the era's pictures are lost). */
      private static function glyph(kind:String, s:Number):Shape
      {
         var sh:Shape = new Shape();
         var g:Graphics = sh.graphics;
         var ink:uint = 0xFFFFFF;
         switch (kind)
         {
            case "house":
               g.beginFill(0xFFF3C2);
               g.moveTo(-s, 0); g.lineTo(0, -s); g.lineTo(s, 0); g.lineTo(-s, 0);
               g.drawRect(-s * 0.7, 0, s * 1.4, s * 0.8);
               g.endFill();
               g.beginFill(0xE0702A);
               g.drawRect(-s * 0.2, s * 0.25, s * 0.4, s * 0.55);
               g.endFill();
               break;
            case "cross":
               g.beginFill(0xFFFFFF);
               g.drawCircle(0, 0, s);
               g.endFill();
               // One outline, so the middle where the two bars meet is red too (two
               // rectangles in one fill leave that square open, white).
               var a:Number = s * 0.25, b:Number = s * 0.7;
               g.beginFill(0xE8302A);
               g.moveTo(-a, -b);
               g.lineTo(a, -b); g.lineTo(a, -a); g.lineTo(b, -a); g.lineTo(b, a); g.lineTo(a, a);
               g.lineTo(a, b); g.lineTo(-a, b); g.lineTo(-a, a); g.lineTo(-b, a); g.lineTo(-b, -a); g.lineTo(-a, -a);
               g.lineTo(-a, -b);
               g.endFill();
               break;
            case "split":
               g.lineStyle(s * 0.28, 0x7CE05A);
               g.moveTo(0, s * 0.8); g.lineTo(0, -s * 0.2);
               g.moveTo(0, -s * 0.2); g.lineTo(-s * 0.8, -s * 0.8);
               g.moveTo(0, -s * 0.2); g.lineTo(s * 0.8, -s * 0.8);
               g.lineStyle();
               g.beginFill(0x7CE05A);
               g.drawCircle(0, s * 0.8, s * 0.3);
               g.endFill();
               break;
            case "egg":
               g.lineStyle(2, 0xC8D8E8);
               g.beginFill(0xFFFFFF);
               g.drawEllipse(-s * 0.7, -s * 0.95, s * 1.4, s * 1.8);
               g.endFill();
               g.lineStyle(2, 0xE04848);
               g.moveTo(-s * 0.6, 0); g.lineTo(-s * 0.3, -s * 0.25); g.lineTo(0, 0); g.lineTo(s * 0.3, -s * 0.25); g.lineTo(s * 0.6, 0);
               break;
            case "lens":
               g.lineStyle(s * 0.25, ink);
               g.beginFill(0xBFF1FF, 0.6);
               g.drawCircle(-s * 0.15, -s * 0.15, s * 0.6);
               g.endFill();
               g.moveTo(s * 0.3, s * 0.3); g.lineTo(s * 0.9, s * 0.9);
               break;
            case "updown":
               g.beginFill(0xFF5A3C);
               g.moveTo(-s * 0.9, -s * 0.1); g.lineTo(-s * 0.4, -s * 0.9); g.lineTo(s * 0.1, -s * 0.1);
               g.endFill();
               g.beginFill(0x52D03A);
               g.moveTo(-s * 0.1, s * 0.1); g.lineTo(s * 0.4, s * 0.9); g.lineTo(s * 0.9, s * 0.1);
               g.endFill();
               break;
            case "box":
               g.lineStyle(2, 0x2A6FB8);
               g.beginFill(0xD6ECFF);
               g.drawRoundRect(-s * 0.85, -s * 0.6, s * 1.7, s * 1.2, s * 0.4, s * 0.4);
               g.endFill();
               g.moveTo(-s * 0.85, -s * 0.1); g.lineTo(s * 0.85, -s * 0.1);
               break;
            case "swap":
               g.lineStyle(s * 0.25, 0xFFD23C);
               g.moveTo(-s * 0.8, -s * 0.35); g.lineTo(s * 0.6, -s * 0.35);
               g.moveTo(s * 0.8, s * 0.35); g.lineTo(-s * 0.6, s * 0.35);
               g.lineStyle();
               g.beginFill(0xFFD23C);
               g.moveTo(s * 0.9, -s * 0.35); g.lineTo(s * 0.45, -s * 0.7); g.lineTo(s * 0.45, 0);
               g.moveTo(-s * 0.9, s * 0.35); g.lineTo(-s * 0.45, 0); g.lineTo(-s * 0.45, s * 0.7);
               g.endFill();
               break;
            case "dumbbell":
               g.beginFill(0x445E80);
               g.drawRect(-s * 0.6, -s * 0.12, s * 1.2, s * 0.24);
               g.endFill();
               g.beginFill(0xFFB43C);
               g.drawRoundRect(-s * 0.95, -s * 0.5, s * 0.35, s, s * 0.2, s * 0.2);
               g.drawRoundRect(s * 0.6, -s * 0.5, s * 0.35, s, s * 0.2, s * 0.2);
               g.endFill();
               break;
            case "doc":
               g.lineStyle(1.5, 0x9A6A2A);
               g.beginFill(0xFFF8E6);
               g.drawRect(-s * 0.6, -s * 0.8, s * 1.2, s * 1.6);
               g.endFill();
               for (var k:int = 0; k < 3; k++) { g.moveTo(-s * 0.35, -s * 0.4 + k * s * 0.4); g.lineTo(s * 0.35, -s * 0.4 + k * s * 0.4); }
               break;
            case "shirt":
               g.lineStyle(1.5, 0x9A6A2A);
               g.beginFill(0xFFFFFF);
               g.moveTo(-s * 0.35, -s * 0.8); g.lineTo(-s * 0.95, -s * 0.4); g.lineTo(-s * 0.7, 0);
               g.lineTo(-s * 0.5, -s * 0.15); g.lineTo(-s * 0.5, s * 0.8); g.lineTo(s * 0.5, s * 0.8);
               g.lineTo(s * 0.5, -s * 0.15); g.lineTo(s * 0.7, 0); g.lineTo(s * 0.95, -s * 0.4);
               g.lineTo(s * 0.35, -s * 0.8); g.lineTo(-s * 0.35, -s * 0.8);
               g.endFill();
               break;
         }
         return sh;
      }

      private function closeButton():Sprite
      {
         var b:Sprite = new Sprite();
         var g:Graphics = b.graphics;
         g.lineStyle(3, 0xFFFFFF);
         g.beginFill(0x2C9BEA);
         g.drawCircle(0, 0, 17);
         g.endFill();
         g.lineStyle(4, 0xFFFFFF);
         g.moveTo(-7, -7); g.lineTo(7, 7);
         g.moveTo(7, -7); g.lineTo(-7, 7);
         b.buttonMode = true;
         b.name = "hw_close";
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         return b;
      }

      private static function label(s:String, size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         var f:TextFormat = new TextFormat("SimSun", size, color, bold);
         f.align = TextFormatAlign.CENTER;
         f.leading = -1;
         t.defaultTextFormat = f;
         t.autoSize = TextFieldAutoSize.CENTER;
         t.selectable = false;
         t.mouseEnabled = false;
         t.multiline = true;
         t.text = s;
         return t;
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener(RobotClient.cmdGetRobot, onRobot);
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }

      // ---------------------------------------------------------------- the skills

      private static function robots():IRobotService
      {
         return ServiceContainer.getService("RobotDataService") as IRobotService;
      }

      private static function newbieDone():Boolean
      {
         var t:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         try { return t != null && t.isUserTaskFinish(150); } catch (e:Error) {}
         return false;
      }

      private static function panel(name:String, then:Function = null):void
      {
         ServiceContainer.instance.tryGetService(name, function(svc:IService, o:Object = null):void
         {
            try
            {
               IShowPanel(svc).showPanel();
               if (then != null) then(svc);
            }
            catch (err:Error) { RLog.error("hello wheel " + name, err); }
         });
      }

      private function onInfo():void
      {
         close();
         var rs:IRobotService = robots();
         if (rs != null) rs.setSelectRobotId(owner);
         panel("RobotMes");
      }

      private function onClothes():void
      {
         close();
         panel("RobotItem", function(svc:Object):void
         {
            // HELLO物品 on its HELLO服装 page.
            if ("setShowItemType" in svc) svc.setShowItemType(1);
         });
      }

      private function onFollow():void
      {
         close();
         if (robots() != null && !robots().getIsFollow()) RobotClient.instance.follow();
      }

      private function onGoHome():void
      {
         if (!newbieDone())
         {
            NewDialog.showMessage("完成新手任务以后，HELLO才可以回家哦！");
            return;
         }
         close();
         NewDialog.getCofirmDialog("你确定让HELLO回家吗?", function(d:ModalDialog):void
         {
            d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void
            {
               if (robots() != null) robots().setIsFollow(false);
               RobotClient.instance.unFollow();
            });
            d.show();
         });
      }

      private function onHeal():void
      {
         var data:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         if (data == null) return;
         var pets:Array = data.getMyPets();
         if (pets == null || pets.length == 0)
         {
            NewDialog.showMessage("你的亚比背包里没有亚比哦！");
            return;
         }
         var full:Boolean = true;
         for each (var p:PetBriefInfo in pets) if (p.curHp < p.maxHp) full = false;
         if (full)
         {
            NewDialog.showSucceedMessage("你的亚比都精力充沛，不需要治疗哦！");
            return;
         }
         Object(data).recureAllPet(function():void { NewDialog.showSucceedMessage("HELLO为亚比们恢复了体力！"); });
      }

      private function onExp():void
      {
         close();
         RExpPanel.show();
      }

      private function onHatch():void
      {
         close();
         panel("PetHatchEgg");
      }

      private function onRare():void
      {
         close();
         RareSearch.show();
      }

      private function onSort():void
      {
         close();
         SkillOrderPanel.show();
      }

      private function onWarehouse():void
      {
         if (!MemberManager.instance.isMember())
         {
            NewDialog.showFailMessage("远程亚比仓库是蓝宝石HELLO的技能哦！");
            return;
         }
         close();
         panel("PetWareHouse");
      }

      private function onReplace():void
      {
         // 技能替换: the 亚比背包, whose 更换技能 picks the skills a 亚比 carries.
         close();
         panel("NewPetPackage");
      }

      private function onTrain():void
      {
         close();
         // The 亚比 in training first (pet/petbetraining), else the lessons (pet/pettraining).
         RTraining.open();
      }
   }
}
