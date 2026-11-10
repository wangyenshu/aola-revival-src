package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IEventDispatcher;
   import flash.geom.Rectangle;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.MaterialServiceEvent;

   /**
    * REVIVAL. A material's picture from its 2013 service: getView gives it when it is loaded, else
    * null, and the service's onGetView brings it once it is (MaterialServiceEvent {id, view}); the
    * holder given here takes it either way. into() fits a picture into the middle of a square, again as it loads.
    */
   public class RMaterialView
   {
      public static function of(service:IMaterialService, id:int):DisplayObject
      {
         var holder:Sprite = new Sprite();
         if (service == null) return holder;
         var ed:IEventDispatcher = service as IEventDispatcher;
         var on:Function = function(e:MaterialServiceEvent):void
         {
            if (e.params == null || int(e.params.id) != id) return;
            ed.removeEventListener(MaterialServiceEvent.onGetView, on);
            var pic:DisplayObject = e.params.view as DisplayObject;
            if (pic != null && holder.numChildren == 0) holder.addChild(pic);
         };
         if (ed != null) ed.addEventListener(MaterialServiceEvent.onGetView, on);
         var v:DisplayObject = null;
         try { v = service.getView(id); } catch (err:Error) {}
         if (v != null)
         {
            if (ed != null) ed.removeEventListener(MaterialServiceEvent.onGetView, on);
            return v;
         }
         return holder;
      }

      /** Into a square (its own size less pad), fitted again whenever the picture's own size changes while it loads. */
      public static function into(view:DisplayObject, box:DisplayObjectContainer, pad:Number):void
      {
         if (view == null || box == null) return;
         var r:Rectangle = box.getBounds(box);
         var w:Number = r.width - pad, h:Number = r.height - pad;
         box.addChild(view);
         var last:String = "";
         var frames:int = 0;
         var tick:Function = function(e:Event = null):void
         {
            var own:Rectangle = view.getBounds(view);
            if (own.width > 0 && own.height > 0 && own.toString() != last)
            {
               last = own.toString();
               var k:Number = Math.min(w / own.width, h / own.height);
               view.scaleX = view.scaleY = k;
               view.x = r.x + r.width / 2 - (own.x + own.width / 2) * k;
               view.y = r.y + r.height / 2 - (own.y + own.height / 2) * k;
            }
            if (++frames > 300 || view.parent == null) view.removeEventListener(Event.ENTER_FRAME, tick);
         };
         tick();
         view.addEventListener(Event.ENTER_FRAME, tick);
      }
   }
}
