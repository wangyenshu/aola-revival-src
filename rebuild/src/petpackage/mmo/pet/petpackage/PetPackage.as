package mmo.pet.petpackage
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.follow.IPetFollow;
   import mmo.interfaces.pet.follow.PetFollowEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REBUILT pet/petpackage (ServiceConfig "NewPetPackage",
    * mmo.pet.petpackage.PetPackage, showPanel): the 亚比背包 on its original
    * 2012 artwork (PetPackagePanel: six capsules bvc0-5, the platform with
    * the big picture, the follow / first / heal buttons, the 技能 / 能力 /
    * 信息 pages). The logic is lost and written here against IPetDataService;
    * pictures are the original peticon/peticon<id>.swf (_S small, _L large).
    */
   public class PetPackage extends MovieClip implements IShowPanel
   {
      private static var panel:PetPackagePanel;
      private var data:IPetDataService;
      private var selected:int = -1;
      private var page:String = "skill";
      private var pageText:TextField;
      private var titleText:TextField;

      public function PetPackage()
      {
         super();
      }

      public function showPanel():void
      {
         try { data = ServiceContainer.getService("PetDataService") as IPetDataService; } catch (e:Error) { RLog.error("petpackage data", e); }
         if (panel != null && panel.parent != null) return;
         panel = new PetPackagePanel();
         wire();
         ModalDialogManager.getInstance().addModalDialog(panel);
         if (data != null)
         {
            data.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM, onDetail);
            data.addEventListener(PetDataServiceEvent.RSPN_SET_CURRENT_PM, onListChanged);
            data.addEventListener(PetDataServiceEvent.RSPN_VIEW_ALL_PM, onListChanged);
            data.addEventListener("rspn_new_pm", onListChanged);
         }
         CommonEventDispatcher.instance.addEventListener(PetFollowEvent.SET_FOLLOW, onFollowChanged);
         CommonEventDispatcher.instance.addEventListener(PetFollowEvent.SET_UNFOLLOW, onFollowChanged);
         refresh();
      }

      private function wire():void
      {
         button(panel.btnClose, close);
         for (var i:int = 0; i < 6; i++)
         {
            var slot:MovieClip = panel["bvc" + i] as MovieClip;
            if (slot) button(slot, selectFn(i));
         }
         button(panel.btnshowskill, function():void { page = "skill"; showPage(); });
         button(panel.btnshowpropertity, function():void { page = "ability"; showPage(); });
         button(panel.btnshowinfo, function():void { page = "info"; showPage(); });
         button(panel.btnInfo, function():void { page = "skill"; showPage(); });
         button(panel.btnItem, notReady("亚比道具"));
         button(panel.btnCloth, notReady("亚比装扮"));
         button(panel.btnCard, notReady("战术卡"));
         button(panel.btnBackWare, function():void
         {
            // 亚比仓库: the rebuilt pet/petwarehouse (service PetWareHouse).
            ServiceContainer.instance.tryGetService("PetWareHouse", function(svc:IService, o:Object):void
            {
               try { IShowPanel(svc).showPanel(); } catch (e:Error) { RLog.error("petpackage warehouse", e); }
            });
         });
         button(panel.mcRide, notReady("坐骑"));
         button(panel.mcSetPri, setFirst);
         button(panel.mcFollow, toggleFollow);
         button(panel.btnHealth, healAll);
         // The art's two-frame tabs and switches (frame 1 plain, 2 chosen) would play
         // on and blink: the lost logic held them still, as here.
         for each (var n:String in ["btnInfo", "btnItem", "btnCloth", "btnCard"]) frame(panel[n], n == "btnInfo" ? 2 : 1);
         frame(panel.mcRide, 3);
         frame(panel.mcSetPri, 1);
         frame(panel.mcFollow, 1);
         // The page under the 技能 / 能力 / 信息 tabs, and the name above them.
         titleText = text(new TextFormat("SimSun", 14, 0x0D5EB0, true));
         titleText.x = panel.btnshowskill.x - 30;
         titleText.y = panel.btnshowskill.y + panel.btnshowskill.height + 8;
         titleText.width = 320;
         titleText.height = 24;
         panel.addChild(titleText);
         pageText = text(new TextFormat("SimSun", 13, 0x1B4F8A, false, null, null, null, null, null, null, null, null, 6));
         pageText.x = panel.btnshowskill.x - 30;
         pageText.y = titleText.y + 26;
         pageText.width = 350;
         pageText.height = 210;
         panel.addChild(pageText);
      }

      private static function text(fmt:TextFormat):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = fmt;
         t.multiline = true;
         t.wordWrap = true;
         t.selectable = false;
         t.mouseEnabled = false;
         return t;
      }

      private static function button(d:*, f:Function):void
      {
         var o:DisplayObject = d as DisplayObject;
         if (o == null) return;
         if (o is Sprite) Sprite(o).buttonMode = true;
         o.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
      }

      private function selectFn(i:int):Function
      {
         return function():void { select(i); };
      }

      private function notReady(what:String):Function
      {
         return function():void { RNotice.show(LayerManager.getBaseTop(), what + "还在修复中哦！"); };
      }

      private function get pets():Array
      {
         return data ? data.getMyPets() : [];
      }

      private function refresh():void
      {
         var list:Array = pets;
         for (var i:int = 0; i < 6; i++)
         {
            var slot:MovieClip = panel["bvc" + i] as MovieClip;
            if (slot == null) continue;
            clearIcons(slot);
            var p:PetBriefInfo = list[i] as PetBriefInfo;
            if (p) icon(slot, p.viewId, "S", 46);
            var hl:MovieClip = panel["highlight" + i] as MovieClip;
            if (hl) hl.visible = false;
         }
         if (list.length == 0)
         {
            showEmpty();
            return;
         }
         var sel:int = selected >= 0 && selected < list.length ? selected : 0;
         select(sel);
      }

      private function clearIcons(c:DisplayObjectContainer):void
      {
         for (var i:int = c.numChildren - 1; i >= 0; i--)
         {
            if (c.getChildAt(i).name == "revivalIcon") c.removeChildAt(i);
         }
      }

      /** peticon/peticon<id>.swf: mmo.pet.peticon<id>_S / _L. */
      private function icon(into:DisplayObjectContainer, viewId:int, size:String, fit:int, maxScale:Number = 1):Sprite
      {
         var cls:String = "mmo.pet.peticon" + viewId + "_" + size;
         var holder:Sprite = new Sprite();
         holder.name = "revivalIcon";
         holder.mouseEnabled = holder.mouseChildren = false;
         into.addChild(holder);
         var put:Function = function(d:*):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls) || holder.parent == null) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var pic:DisplayObject = new C() as DisplayObject;
            var b:Object = pic.getBounds(pic);
            var k:Number = Math.min(maxScale, fit / Math.max(1, b.width), fit / Math.max(1, b.height));
            pic.scaleX = pic.scaleY = k;
            // Centred across; stands on the holder's point (the bottom of the picture).
            pic.x = -(b.left + b.width / 2) * k;
            pic.y = size == "L" ? -b.bottom * k : -(b.top + b.height / 2) * k;
            holder.addChild(pic);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put(null);
         else ResScheduler.getResource("peticon/peticon" + viewId, put, cls, function(e:*):void {});
         return holder;
      }

      private function select(i:int):void
      {
         var list:Array = pets;
         var p:PetBriefInfo = list[i] as PetBriefInfo;
         if (p == null) return;
         selected = i;
         for (var k:int = 0; k < 6; k++)
         {
            var hl:MovieClip = panel["highlight" + k] as MovieClip;
            if (hl) hl.visible = k == i;
         }
         if (data) data.setSelectPetId(p.id);
         var big:MovieClip = panel.bigiconcontainer;
         if (big)
         {
            clearIcons(big);
            // Centred over the platform (normalEffect is the glow the big 亚比 stands in).
            var fx:DisplayObject = panel.normalEffect;
            var cx:Number = fx ? fx.x + fx.width / 2 : 301, cy:Number = fx ? fx.y + fx.height * 0.62 : 222;
            var h:Sprite = icon(big, p.viewId, "L", 130, 2.2);
            h.x = cx - big.x;
            h.y = cy - big.y;
         }
         var hp:int = p.curHp, max:int = Math.max(1, p.maxHp);
         if (panel.bighptext) panel.bighptext.text = hp + "/" + max;
         var bar:MovieClip = panel.hpmc;
         if (bar)
         {
            if (bar.totalFrames > 1) bar.gotoAndStop(Math.max(1, Math.round(hp / max * (bar.totalFrames - 1)) + 1));
            else if (bar.getChildByName("mc")) bar.getChildByName("mc").scaleX = hp / max;
         }
         showFollowState();
         PetClient.instance.viewSinglePM(p.id);
         showPage();
      }

      private function onDetail(e:PetDataServiceEvent):void
      {
         if (panel && panel.parent) showPage();
      }

      private function onListChanged(e:*):void
      {
         if (panel && panel.parent) refresh();
      }

      private static function frame(d:*, n:int):void
      {
         var mc:MovieClip = d as MovieClip;
         if (mc != null) mc.gotoAndStop(Math.min(n, mc.totalFrames));
      }

      private function showPage():void
      {
         frame(panel.btnshowskill, page == "skill" ? 2 : 1);
         frame(panel.btnshowpropertity, page == "ability" ? 2 : 1);
         frame(panel.btnshowinfo, page == "info" ? 2 : 1);
         frame(panel.mcSetPri, selected > 0 ? 2 : 1);
         var p:PetBriefInfo = pets[selected] as PetBriefInfo;
         if (p == null) return;
         var d:PetDetailedInfo = data ? data.getPetDetailedInfoById(p.id) : null;
         titleText.htmlText = "<font face='SimSun'>" + (p.nickname || p.name) + "    <font color='#E8641B'>Lv." + p.level + "</font></font>";
         var s:String = "";
         if (page == "skill")
         {
            for each (var sk:SkillInfo in p.skills || []) s += "◆ " + sk.name + "    PP " + sk.canUseTimes + "/" + sk.maxUseTimes + "\n";
         }
         else if (page == "ability")
         {
            if (d)
            {
               s += "体力 " + d.maxHp + "    攻击 " + d.attack + "    防御 " + d.defence + "\n";
               s += "特攻 " + d.spAttack + "    特防 " + d.spDefence + "    速度 " + d.speed + "\n";
               s += "经验 " + d.curExp + "    升级还需 " + d.toNextLevel + "\n";
            }
            else s += "正在读取……\n";
         }
         else
         {
            s += "种族：" + p.name + "\n性格：" + p.character + "\n";
            if (d) s += "获得日期：" + d.getDate + "\n";
         }
         pageText.htmlText = "<font face='SimSun'>" + s + "</font>";
      }

      private function showEmpty():void
      {
         if (panel.bighptext) panel.bighptext.text = "";
         titleText.text = "";
         pageText.htmlText = "<font face='SimSun'><b>你还没有亚比哦！</b>\n去找HELLO领取你的第一只亚比吧。</font>";
      }

      private function setFirst():void
      {
         var p:PetBriefInfo = pets[selected] as PetBriefInfo;
         if (p == null || selected == 0) return;
         PetClient.instance.setCurPM(p.id);
         selected = 0;
      }

      /** mcFollow: through pet/petfollow (PetClient2 54_8 to follow, 54_9 back into the bag). */
      private function toggleFollow():void
      {
         var p:PetBriefInfo = pets[selected] as PetBriefInfo;
         if (p == null) return;
         var back:Boolean = data != null && data.getCurFollowPetId() == p.id;
         ServiceContainer.instance.tryGetService("PetFollowService", function(svc:IService, o:Object):void
         {
            var f:IPetFollow = svc as IPetFollow;
            if (f == null) return;
            if (back) f.setBackPackage();
            else f.setFollow(p.id, p.raceId);
         });
      }

      private function onFollowChanged(e:PetFollowEvent):void
      {
         if (panel && panel.parent) showFollowState();
      }

      private function showFollowState():void
      {
         var p:PetBriefInfo = pets[selected] as PetBriefInfo;
         var on:Boolean = p != null && data != null && data.getCurFollowPetId() == p.id;
         var f:MovieClip = panel.mcFollow;
         if (f && f.totalFrames > 1) f.gotoAndStop(on ? 2 : 1);
         if (f) f.filters = on ? [new GlowFilter(0xFFCC00, 1, 8, 8, 3)] : [];
      }

      private function healAll():void
      {
         if (data) data.recureAllPet(function():void
         {
            RNotice.show(LayerManager.getBaseTop(), "你的亚比都恢复健康了！");
            refresh();
         });
      }

      private function close():void
      {
         if (data)
         {
            data.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM, onDetail);
            data.removeEventListener(PetDataServiceEvent.RSPN_SET_CURRENT_PM, onListChanged);
            data.removeEventListener(PetDataServiceEvent.RSPN_VIEW_ALL_PM, onListChanged);
            data.removeEventListener("rspn_new_pm", onListChanged);
         }
         CommonEventDispatcher.instance.removeEventListener(PetFollowEvent.SET_FOLLOW, onFollowChanged);
         CommonEventDispatcher.instance.removeEventListener(PetFollowEvent.SET_UNFOLLOW, onFollowChanged);
         if (panel && panel.parent) ModalDialogManager.getInstance().removeModalDialog(panel);
         panel = null;
      }
   }
}
