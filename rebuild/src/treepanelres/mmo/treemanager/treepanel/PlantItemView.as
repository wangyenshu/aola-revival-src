package mmo.treemanager.treepanel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.plantitem.IPlantItemService;
   import mmo.interfaces.material.plantitem.PlantItem;

   /** REBUILT (the 2012 code on its art, symbol 94): a 盆栽道具's picture in its square. */
   public class PlantItemView extends Sprite
   {
      public var _cont:MovieClip;

      private var id:int;

      public function PlantItemView(item:PlantItem)
      {
         super();
         id = item.id;
         mouseEnabled = mouseChildren = false;
         var service:IPlantItemService = ServiceContainer.getService(IPlantItemService) as IPlantItemService;
         if (service == null) return;
         var got:Function = function(e:MaterialServiceEvent):void
         {
            if (int(e.params.id) != id) return;
            service.removeEventListener(MaterialServiceEvent.onGetView, got);
            put(e.params.view as DisplayObject);
         };
         service.addEventListener(MaterialServiceEvent.onGetView, got);
         var v:DisplayObject = null;
         try { v = service.getView(id); } catch (err:Error) {}
         if (v != null)
         {
            service.removeEventListener(MaterialServiceEvent.onGetView, got);
            put(v);
         }
      }

      private function put(v:DisplayObject):void
      {
         if (v == null) return;
         DisplayUtil.scaleDisplay(v, 48, 48);
         DisplayUtil.middleDisplay(v, 48.9, 48.9);
         (_cont != null ? _cont : this).addChild(v);
      }
   }
}
