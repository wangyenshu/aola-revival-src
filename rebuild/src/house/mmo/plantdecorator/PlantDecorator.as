package mmo.plantdecorator
{
   import flash.geom.Point;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.IHouseService;
   import mmo.houseinterfaces.decorate.HouseDecoratorEvent;
   import mmo.houseinterfaces.decorate.IHouseDecorator;
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.MaterialLayoutState;
   import mmo.houseinterfaces.material.MaterialSketch;
   import mmo.houseinterfaces.material.MaterialView;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.interfaces.IService;
   import mmo.interfaces.changeable.ChangeableCollection;
   import mmo.interfaces.changeable.ChangeableCollectionEvent;
   import mmo.interfaces.material.plant.UserPlant;
   import mmo.revival.RLog;

   /**
    * REBUILT yz/plantdecorator (ServiceConfig "PlantDecorator", one of HouseService's
    * decorators): the trees made furniture (收为家具 in the tree panel) in the 小屋. The
    * 2013 module is lost; written after its later copy (the same PlantClient commands)
    * on the 2013 houseinterfaces:
    *
    *   80_1 {}                    -> {userPlants}   one's own trees (those with isFurniture are furniture)
    *   80_9 {owner, houseId}      -> {userPlants}   the trees standing in someone's room
    *   80_10 {houseId, changes}   -> {result}       changes: [{id, x, y, houseId}] (houseId 0: back in storage)
    *   80_11 {houseId, newHouseId} -> {result, nid} another house type: every tree back in storage
    *
    * A tree is a floor item of the 我的家具 storage ("普通" tab) until it is put down;
    * its picture is the grown tree of plant/y<id> (PlantArt). The garden's own 植树盆
    * (the rebuilt furniture/b000247) shows the growing tree: nothing here in the garden
    * or the 动物园.
    */
   public class PlantDecorator extends ChangeableCollection implements IHouseDecorator
   {
      private static const GET_MINE:String = "80_1";
      private static const GET_HOUSE:String = "80_9";
      private static const SAVE:String = "80_10";
      private static const CHANGE_HOUSE:String = "80_11";

      private var houseService:IHouseService;
      private var house:IHouse;
      private var plants:Array = [];
      private var views:Array = [];

      public function PlantDecorator()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      private function get houseId():int
      {
         return houseService.houseLoader.houseInfo.currentHouseId;
      }

      /** Not the garden nor the 动物园 (their own rooms). */
      private function get inRoom():Boolean
      {
         try { return !houseService.houseLoader.houseInfo.isInGarden && houseId < 20000 && houseId != 247; } catch (e:Error) {}
         return false;
      }

      public function preDecorate(hs:IHouseService):void
      {
         houseService = hs;
         house = hs.house;
         plants = [];
         if (!inRoom)
         {
            dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onPreDecorated, {}));
            return;
         }
         var mine:Boolean = hs.houseLoader.isMyHouse;
         var cmd:String = mine ? GET_MINE : GET_HOUSE;
         var sc:SocketClient = SocketClient.instance;
         var got:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(cmd, got);
            for each (var o:Object in (e.params.userPlants as Array) || [])
            {
               if (!o.isFurniture) continue;
               try { plants.push(UserPlant.parse(o)); } catch (err:Error) { RLog.error("plant decorator", err); }
            }
            dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onPreDecorated, {}));
         };
         sc.addEventListener(cmd, got);
         if (mine) sc.sendXtMessage("PlantExtension", GET_MINE, {});
         else sc.sendXtMessage("PlantExtension", GET_HOUSE, {owner: hs.houseLoader.houseInfo.owner, houseId: houseId});
      }

      public function decorate():void
      {
         clear();
         var mine:Boolean = houseService.houseLoader.isMyHouse;
         for each (var p:UserPlant in plants)
         {
            var w:UserPlantWrap = new UserPlantWrap(p, this);
            if (mine) addObject(w);
            if (p.houseId != 0 && p.houseId == houseId) place(w, p);
         }
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onDecorated, {}));
      }

      private function place(w:UserPlantWrap, p:UserPlant):void
      {
         var x:int = p.x, y:int = p.y;
         if (x < 0 || x > 960 || y < 0 || y > 560) x = y = int.MAX_VALUE;
         var v:PlantView = new PlantView(w.buildLayoutInfo(houseId, p.userPlantId, x, y, 0, ""));
         v.show(house);
         views.push(v);
      }

      /** From the storage into the room. */
      public function buildView(w:UserMaterialWrap, at:Point):MaterialView
      {
         var layout:MaterialLayoutInfo = w.getNewLayoutInfo(houseId);
         if (layout == null) return null;
         layout.x = at.x;
         layout.y = at.y;
         var v:PlantView = new PlantView(layout);
         v.show(house);
         views.push(v);
         if (w.available == 0) dispatchEvent(new ChangeableCollectionEvent(ChangeableCollectionEvent.onRemoveObject, w, {}));
         return v;
      }

      /** Back into the storage (dropped outside the room). */
      public function unUse(v:MaterialView):void
      {
         var i:int = views.indexOf(v);
         if (i >= 0) views.splice(i, 1);
         var w:UserMaterialWrap = v.layoutInfo.source;
         w.unUse(v.layoutInfo);
         if (w.available == 1) dispatchEvent(new ChangeableCollectionEvent(ChangeableCollectionEvent.onAddObject, w, {}));
      }

      public function getStorageItems():Array
      {
         return getObjects();
      }

      public function getSketch(w:UserMaterialWrap, width:int, height:int):MaterialSketch
      {
         return new PlantSketch(w, width, height);
      }

      // ───── saving ─────

      public function save():void
      {
         var changes:Array = [];
         for each (var w:UserPlantWrap in getObjects())
         {
            for each (var l:MaterialLayoutInfo in w.getChanges())
            {
               var gone:Boolean = l.state == MaterialLayoutState.Deleted;
               if (!gone && (l.x < 0 || l.x > 960 || l.y < 0 || l.y > 560))
               {
                  NewDialog.showFailMessage("保存装扮数据错误。");
                  saved(false);
                  return;
               }
               changes.push({id: w.userPlant.userPlantId, x: gone ? 0 : l.x, y: gone ? 0 : l.y, houseId: gone ? 0 : l.houseId});
            }
         }
         if (changes.length == 0)
         {
            saved(true);
            return;
         }
         var sc:SocketClient = SocketClient.instance;
         var onSaved:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(SAVE, onSaved);
            var ok:Boolean = Boolean(e.params.result);
            if (!ok) NewDialog.showFailMessage("保存错误！");
            saved(ok);
         };
         sc.addEventListener(SAVE, onSaved);
         sc.sendXtMessage("PlantExtension", SAVE, {houseId: houseId, changes: changes});
      }

      private function saved(ok:Boolean):void
      {
         if (ok)
         {
            for each (var w:UserMaterialWrap in getObjects()) w.acceptChanges();
         }
         else
         {
            disposeViews();
            for each (var old:UserMaterialWrap in getObjects()) old.dispose();
            decorate();
         }
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onSaved, {result: ok}));
      }

      /** Another house type (the furniture decorator asks): every tree back into the storage. */
      public function resetHouse(oldId:int, newId:int):void
      {
         var sc:SocketClient = SocketClient.instance;
         var onChanged:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(CHANGE_HOUSE, onChanged);
            if (e.params.result)
            {
               for each (var w:UserPlantWrap in getObjects()) w.clearOnResetHouse();
            }
            dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onResetHouse, e.params));
         };
         sc.addEventListener(CHANGE_HOUSE, onChanged);
         sc.sendXtMessage("PlantExtension", CHANGE_HOUSE, {houseId: oldId, newHouseId: newId});
      }

      public function close():void
      {
         disposeViews();
         for each (var w:UserMaterialWrap in getObjects())
         {
            try { w.dispose(); } catch (err:Error) {}
         }
         clear();
         plants = [];
         house = null;
         houseService = null;
      }

      private function disposeViews():void
      {
         for each (var v:MaterialView in views) v.dispose();
         views = [];
      }
   }
}
