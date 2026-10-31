package mmo.house.b000247
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.UserMaterial;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REBUILT: the 家园's 我的荣誉 (and its bar's 勋章), the wall of the badges
    * the player has earned: the era BadgeService's materials (type 104,
    * mmo.materialdata.BadgeData), each with its picture (getView) and name.
    * The 2012 wall is lost; drawn in the look of the rebuilt panels.
    */
   public class HonourWall extends Sprite
   {
      private static const W:int = 540;
      private static const H:int = 380;
      private static const BADGE:int = 104;
      private static var current:HonourWall;

      private var box:Sprite;
      private var grid:Sprite;
      private var listening:Array = [];

      public static function show():void
      {
         if (current != null) current.close();
         current = new HonourWall();
         LayerManager.getBaseTop().addChild(current);
      }

      public function HonourWall()
      {
         super();
         name = "honourWall";
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "我的荣誉", close, "honourClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         box.addChild(RUI.well(16, 54, W - 32, 270));
         grid = new Sprite();
         grid.x = 30;
         grid.y = 66;
         box.addChild(grid);
         var said:TextField = RUI.text(12, 0x557799, false, W - 40);
         said.x = 20;
         said.y = 334;
         box.addChild(said);
         var svc:IMaterialService = null;
         var mine:Array = [];
         try
         {
            var f:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            svc = f ? f.getService(BADGE) : null;
            if (svc) mine = svc.getMyMaterials();
         }
         catch (e:Error) { RLog.error("honour badges", e); }
         var n:int = 0;
         for each (var u:* in mine)
         {
            var um:UserMaterial = u as UserMaterial;
            if (um == null || um.quantity <= 0 || n >= 24) continue;
            var cell:Sprite = cellFor(svc, um);
            cell.x = (n % 6) * 80;
            cell.y = int(n / 6) * 64;
            grid.addChild(cell);
            n++;
         }
         said.text = n ? "共 " + n + " 枚勋章。" : "还没有获得勋章。完成任务和挑战，勋章会挂在这里。";
      }

      private function cellFor(svc:IMaterialService, um:UserMaterial):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.graphics.lineStyle(2, 0xF2C27A);
         cell.graphics.beginFill(0xFFF8E6);
         cell.graphics.drawRoundRect(0, 0, 72, 56, 12, 12);
         cell.graphics.endFill();
         var holder:Sprite = new Sprite();
         holder.mouseEnabled = holder.mouseChildren = false;
         cell.addChild(holder);
         var v:DisplayObject = null;
         try { v = svc.getView(um.materialId); } catch (e:Error) {}
         if (v != null) place(holder, v);
         else
         {
            var id:int = um.materialId;
            var later:Function = function(ev:MaterialServiceEvent):void
            {
               if (ev.params == null || int(ev.params.id) != id || !(ev.params.view is DisplayObject)) return;
               svc.removeEventListener(MaterialServiceEvent.onGetView, later);
               if (holder.numChildren == 0) place(holder, DisplayObject(ev.params.view));
            };
            svc.addEventListener(MaterialServiceEvent.onGetView, later);
            listening.push([svc, later]);
         }
         try { TipsManager.getInstance().addTips(cell, um.material ? um.material.name : String(um.materialId)); } catch (e2:Error) {}
         return cell;
      }

      private static function place(holder:Sprite, v:DisplayObject):void
      {
         holder.addChild(v);
         DisplayUtil.scaleDisplay(v, 48, 48);
         DisplayUtil.middleDisplay(v, 72, 56);
      }

      public function close():void
      {
         for each (var l:Array in listening) IMaterialService(l[0]).removeEventListener(MaterialServiceEvent.onGetView, l[1]);
         listening = [];
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
