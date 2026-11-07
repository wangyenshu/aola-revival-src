package mmo.zoo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.zoo.IZooService;
   import mmo.revival.RLog;

   /**
    * REVIVAL. What the rebuilt 2012 zoo panels share: the ZooExtension commands (server
    * zoo.ts), the era ZooAnimalData (material type 12) and the zoo's pictures through the
    * era zoo/zooservice (ZooIconLoader: zoopeticon, zooitem).
    */
   public class ZooKit
   {
      public static const EXT:String = "ZooExtension";
      /** ZooIconType (2013 interfaces). */
      public static const BABY:int = 0, MATURE:int = 2, ITEM:int = 3;

      /** cmd sent; then(params) on its reply (once). */
      public static function ask(cmd:String, params:Object, then:Function = null):void
      {
         var sc:SocketClient = SocketClient.instance;
         if (then != null)
         {
            var got:Function = function(e:SocketClientEvent):void
            {
               sc.removeEventListener(cmd, got);
               try { then(e.params); } catch (err:Error) { RLog.error("zoo " + cmd, err); }
            };
            sc.addEventListener(cmd, got);
         }
         sc.sendXtMessage(EXT, cmd, params || {});
      }

      /** The era Animal of this race (name, matureName, starNum, exp, evoNameArr, evoRateArr, matureTime …). */
      public static function animal(race:int):Object
      {
         try
         {
            var f:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            var s:IMaterialService = f ? f.getService(12) : null;
            return s ? s.getMaterialById(race) : null;
         }
         catch (e:Error) {}
         return null;
      }

      public static function nameOf(race:int, grown:Boolean):String
      {
         var a:Object = animal(race);
         return a == null ? "动物" + race : String(grown ? a.matureName : a.name);
      }

      /**
       * A picture of the zoo (BABY, MATURE, ITEM) into a card's pictureContainer, as the era
       * containers put it (ZooIconLoader.loadIconComplete; the loading clip progressMC goes).
       */
      public static function icon(id:int, type:int, into:DisplayObjectContainer):void
      {
         if (into == null) return;
         ServiceContainer.instance.tryGetService("ZooService", function(s:IZooService, o:Object = null):void
         {
            try
            {
               s.loadIconComplete(type, id, function(pic:Sprite):void
               {
                  var loading:DisplayObject = into.getChildByName("progressMC");
                  if (loading != null) into.removeChild(loading);
                  if (pic != null) into.addChild(pic);
               });
            }
            catch (e:Error) { RLog.error("zoo icon " + id, e); }
         });
      }

      /** "x小时y分钟" of a number of seconds. */
      public static function hoursText(seconds:int):String
      {
         seconds = Math.max(0, seconds);
         return int(seconds / 3600) + "小时" + int((seconds % 3600) / 60) + "分钟";
      }

      public static function hide(d:DisplayObject):void
      {
         if (d != null) d.visible = false;
      }
   }
}
