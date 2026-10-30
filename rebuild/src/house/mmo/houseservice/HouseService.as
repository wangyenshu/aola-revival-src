package mmo.houseservice
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.Point;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import mmo.common.dialog.NewDialog;
   import mmo.houseinterfaces.HouseEvent;
   import mmo.houseinterfaces.HouseServiceEvent;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.IHouseLoader;
   import mmo.houseinterfaces.IHouseService;
   import mmo.houseinterfaces.decorate.HouseDecoratorEvent;
   import mmo.houseinterfaces.decorate.IFurnitureDecorator;
   import mmo.houseinterfaces.decorate.IHouseDecorator;
   import mmo.houseinterfaces.material.HouseItemTypes;
   import mmo.houseinterfaces.material.MaterialView;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.houseinterfaces.operate.HouseMenuEvent;
   import mmo.houseinterfaces.operate.HouseStorageEvent;
   import mmo.houseinterfaces.operate.IHouseMenuService;
   import mmo.houseinterfaces.operate.IHouseStorageService;
   import mmo.interfaces.IService;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.control.IControlService;
   import mmo.revival.RLog;

   /**
    * REBUILT house/houseservice (ServiceConfig "HouseService", SingleLocator,
    * with houseLoader, decorators, menu and storage injected): runs a home
    * once house/houseloader has built it. The 2013 module is lost; this is
    * written against the 2013 IHouseService and the steps its interfaces
    * define: preDecorate (each decorator reads what is placed), decorate
    * (places it), the menu's 我的家具 / 保存装扮, items dragged in from the
    * storage, and save.
    *
    * Only the furniture decorator is rebuilt; the robot, pet display, plant
    * and breeding decorators are stand-ins that never answer, so a decorator
    * that has not answered within a moment is counted as done.
    */
   public class HouseService extends EventDispatcher implements IHouseService
   {
      private static const PATIENCE_MS:int = 1500;

      private var _houseLoader:IHouseLoader;
      private var _decorators:Array = [];
      private var _menu:IHouseMenuService;
      private var _storage:IHouseStorageService;
      private var _house:IHouse;
      private var _isEditing:Boolean;
      private var editor:HouseEditor;

      public function HouseService()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function getInstance():IService
      {
         return this;
      }

      // ───── injected by the ServiceContainer ─────

      public function set houseLoader(v:IHouseLoader):void
      {
         if (_houseLoader == null) _houseLoader = v;
      }

      public function get houseLoader():IHouseLoader
      {
         return _houseLoader;
      }

      public function set decorators(v:Array):void
      {
         if (_decorators.length == 0 && v != null) _decorators = v;
      }

      public function get decorators():Array
      {
         return _decorators;
      }

      public function get furniturDecorators():IFurnitureDecorator
      {
         for each (var d:IHouseDecorator in _decorators)
         {
            if (d is IFurnitureDecorator) return IFurnitureDecorator(d);
         }
         return null;
      }

      public function set menu(v:IHouseMenuService):void
      {
         if (_menu == null) _menu = v;
      }

      public function get menu():IHouseMenuService
      {
         return _menu;
      }

      public function set storage(v:IHouseStorageService):void
      {
         if (_storage == null) _storage = v;
      }

      public function get storage():IHouseStorageService
      {
         return _storage;
      }

      // ───── state ─────

      public function get house():IHouse
      {
         return _house;
      }

      public function get inHouse():Boolean
      {
         return _house != null;
      }

      public function get isMyHouse():Boolean
      {
         return _houseLoader != null && _houseLoader.isMyHouse;
      }

      public function get owner():String
      {
         return _houseLoader && _houseLoader.houseInfo ? _houseLoader.houseInfo.owner : null;
      }

      public function get isEditing():Boolean
      {
         return _isEditing;
      }

      // ───── building a home ─────

      /** Before the room is joined: every decorator reads what this home holds. */
      public function preDecorate():void
      {
         if (_house != null) closeHouse();
         _house = _houseLoader.house;
         _house.loader = _houseLoader;
         _house.addEventListener(HouseEvent.onLeaveRoom, onLeaveRoom);
         var self:HouseService = this;
         waitForAll(HouseDecoratorEvent.onPreDecorated, function(d:IHouseDecorator):void { d.preDecorate(self); }, onAllPreDecorated);
      }

      private function onAllPreDecorated():void
      {
         try
         {
            if (_storage) _storage.preDecorate(_house, _decorators);
            if (_menu)
            {
               _menu.editable = isMyHouse;
               _menu.preDecorate(_house);
            }
         }
         catch (err:Error)
         {
            RLog.error("house menu/storage preDecorate", err);
         }
         dispatchEvent(new HouseServiceEvent(HouseServiceEvent.onPreDecorated, {}));
      }

      /** The home is on screen: place the furniture, show the menu. */
      public function decorate():void
      {
         waitForAll(HouseDecoratorEvent.onDecorated, function(d:IHouseDecorator):void { d.decorate(); }, onAllDecorated);
      }

      private function onAllDecorated():void
      {
         try
         {
            if (_storage)
            {
               _storage.decorate();
               _storage.enabled = true;
               _storage.visiable = false;
               _storage.addEventListener(HouseStorageEvent.onDragMaterial, onDragMaterial);
               _storage.addEventListener(HouseStorageEvent.onChooseMaterial, onChooseMaterial);
            }
            if (_menu)
            {
               _menu.decorate();
               _menu.enabled = true;
               _menu.visiable = true;
               _menu.addEventListener(HouseMenuEvent.onEdit, onMenuEdit);
               _menu.addEventListener(HouseMenuEvent.onExitEdit, onMenuExitEdit);
               _menu.addEventListener(HouseMenuEvent.onSave, onMenuSave);
               _menu.addEventListener(HouseMenuEvent.onOpenStorage, onMenuOpenStorage);
            }
         }
         catch (err:Error)
         {
            RLog.error("house menu/storage decorate", err);
         }
         editor = new HouseEditor(_house);
         editor.addEventListener(HouseEditor.GRASP, function(e:Event):void { setPanelsEnabled(false); });
         editor.addEventListener(HouseEditor.LAY_DOWN, function(e:Event):void { setPanelsEnabled(true); });
         dispatchEvent(new HouseServiceEvent(HouseServiceEvent.onDecorated, {}));
      }

      /**
       * Call start(decorator) on every decorator and then done() once each
       * has sent type, or after PATIENCE_MS for those that stay silent.
       */
      private function waitForAll(type:String, start:Function, done:Function):void
      {
         var waiting:Array = _decorators.concat();
         var finished:Boolean = false;
         var timer:uint;
         var check:Function = function():void
         {
            if (!finished && waiting.length == 0)
            {
               finished = true;
               clearTimeout(timer);
               done();
            }
         };
         var answer:Function = function(e:Event):void
         {
            e.target.removeEventListener(type, answer);
            var i:int = waiting.indexOf(e.target);
            if (i >= 0) waiting.splice(i, 1);
            check();
         };
         timer = setTimeout(function():void
         {
            if (finished) return;
            for each (var silent:IHouseDecorator in waiting)
            {
               silent.removeEventListener(type, answer);
               RLog.log("house: " + silent + " did not answer " + type + " (stand-in)");
            }
            waiting = [];
            check();
         }, PATIENCE_MS);
         for each (var d:IHouseDecorator in _decorators.concat())
         {
            d.addEventListener(type, answer);
            try
            {
               start(d);
            }
            catch (err:Error)
            {
               RLog.error("house decorator " + d, err);
               d.removeEventListener(type, answer);
               var j:int = waiting.indexOf(d);
               if (j >= 0) waiting.splice(j, 1);
            }
         }
         check();
      }

      private function setPanelsEnabled(v:Boolean):void
      {
         if (_menu) _menu.enabled = v;
         if (_storage) _storage.enabled = v;
      }

      // ───── decorating ─────

      private function onMenuEdit(e:Event):void
      {
         if (_isEditing) return;
         _isEditing = true;
         Object(_house).enterEditMode();
         if (_storage) _storage.visiable = true;
         editor.enterEditMode();
         controlVisible(false);
         dispatchEvent(new HouseServiceEvent(HouseServiceEvent.onStartEdit, {}));
      }

      private function onMenuExitEdit(e:Event):void
      {
         endEditing();
      }

      private function onMenuOpenStorage(e:Event):void
      {
         if (_storage) _storage.visiable = true;
      }

      private function onMenuSave(e:Event):void
      {
         endEditing();
         if (_menu) _menu.enabled = false;
         var ok:Boolean = true;
         waitForAll(HouseDecoratorEvent.onSaved, function(d:IHouseDecorator):void
         {
            d.addEventListener(HouseDecoratorEvent.onSaved, function(ev:HouseDecoratorEvent):void
            {
               ev.target.removeEventListener(HouseDecoratorEvent.onSaved, arguments.callee);
               ok = ok && Boolean(ev.params.result);
            });
            d.save();
         }, function():void
         {
            if (_menu) _menu.enabled = true;
            dispatchEvent(new HouseServiceEvent(HouseServiceEvent.onSaveEdit, {result: ok}));
         });
      }

      private function endEditing():void
      {
         if (!_isEditing) return;
         _isEditing = false;
         editor.exitEditMode();
         Object(_house).exitEditMode();
         if (_storage) _storage.visiable = false;
         controlVisible(true);
      }

      private function controlVisible(v:Boolean):void
      {
         try
         {
            var c:IControlService = ServiceContainer.getService(IControlService) as IControlService;
            if (v) c.show();
            else c.hide();
         }
         catch (err:Error) {}
      }

      /** An item taken from the storage: dragged into the home, or chosen (placed at its usual spot). */
      private function onDragMaterial(e:HouseStorageEvent):void
      {
         addView(e.params.userMaterialWrap as UserMaterialWrap, e.params.point as Point, true);
      }

      private function onChooseMaterial(e:HouseStorageEvent):void
      {
         addView(e.params.userMaterialWrap as UserMaterialWrap, new Point(int.MAX_VALUE, int.MAX_VALUE), false);
      }

      private function addView(w:UserMaterialWrap, at:Point, grasp:Boolean):void
      {
         if (w == null || editor == null) return;
         if (!_house.berthable(w.itemType))
         {
            NewDialog.showFailMessage("这件家具不能摆在这里哦。");
            return;
         }
         if (w.isFix) at = w.fixPoint;
         else if (at == null) at = new Point(int.MAX_VALUE, int.MAX_VALUE);
         var v:MaterialView = w.parent.buildView(w, at);
         if (v != null) editor.addView(v, grasp);
      }

      // ───── leaving ─────

      private function onLeaveRoom(e:Event):void
      {
         leaveHouse();
      }

      public function leaveHouse():void
      {
         closeHouse();
         if (_houseLoader) _houseLoader.leaveHouse();
      }

      /** Close the decorators, menu and storage of the home being left. */
      private function closeHouse():void
      {
         if (_house == null) return;
         _house.removeEventListener(HouseEvent.onLeaveRoom, onLeaveRoom);
         if (_isEditing) controlVisible(true);
         _isEditing = false;
         for each (var d:IHouseDecorator in _decorators)
         {
            try { d.close(); } catch (err:Error) { RLog.error("house decorator close", err); }
         }
         if (_storage)
         {
            _storage.removeEventListener(HouseStorageEvent.onDragMaterial, onDragMaterial);
            _storage.removeEventListener(HouseStorageEvent.onChooseMaterial, onChooseMaterial);
            try { _storage.close(); } catch (err2:Error) {}
         }
         if (_menu)
         {
            _menu.removeEventListener(HouseMenuEvent.onEdit, onMenuEdit);
            _menu.removeEventListener(HouseMenuEvent.onExitEdit, onMenuExitEdit);
            _menu.removeEventListener(HouseMenuEvent.onSave, onMenuSave);
            _menu.removeEventListener(HouseMenuEvent.onOpenStorage, onMenuOpenStorage);
            try { _menu.close(); } catch (err3:Error) {}
         }
         if (editor != null) editor.dispose();
         editor = null;
         _house = null;
      }
   }
}
