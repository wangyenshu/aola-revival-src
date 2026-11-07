package mmo.revival
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.HTTPStatusEvent;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.IAlbumAvatarProxy;
   import mmo.interfaces.avatar.IAvatarService;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.material.clothes.Clothes;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.interfaces.material.clothes.UserClothes;
   import mmo.loader.scheduler.VersManager;

   /**
    * REVIVAL. A player's avatar in its big pictures (the 2013 avatar service's album avatar,
    * the skinview files): the player card, the rebuilt useravatar service (UserAvatarService),
    * the 家园's friends.
    */
   public class RAvatar
   {
      /** skinview file name -> whether the site has it (asked once a session). */
      private static var views:Object = {};

      /**
       * userName's avatar into `into`. fit(sprite, bounds) is called each frame until it returns
       * true, once the avatar has drawn something (bounds: the sprite's own, unscaled); without
       * fit the avatar stays at its own size and origin. Returns the proxy (null: no avatar service).
       */
      public static function show(userName:String, into:DisplayObjectContainer, fit:Function = null):IAlbumAvatarProxy
      {
         var clothes:IClothesService;
         var avatar:IAlbumAvatarProxy;
         try
         {
            clothes = ServiceContainer.getService(IClothesService) as IClothesService;
            avatar = (ServiceContainer.getService(IAvatarService) as IAvatarService).getAlbumAvatarProxy();
         }
         catch (e:Error)
         {
            RLog.error("avatar " + userName, e);
            return null;
         }
         if (clothes == null || avatar == null) return null;
         var sprite:Sprite = avatar.getSprite();
         into.addChild(sprite);
         if (fit != null)
         {
            var each:Function = function(e:Event = null):void
            {
               if (sprite.parent == null) { sprite.removeEventListener(Event.ENTER_FRAME, each); return; }
               var sx:Number = sprite.scaleX, sy:Number = sprite.scaleY;
               sprite.scaleX = sprite.scaleY = 1;
               var b:Rectangle = sprite.getBounds(sprite);
               sprite.scaleX = sx;
               sprite.scaleY = sy;
               if (b.height <= 1) return;
               if (fit(sprite, b) === true) sprite.removeEventListener(Event.ENTER_FRAME, each);
            };
            sprite.addEventListener(Event.ENTER_FRAME, each);
         }
         var dress:Function = function(info:AvatarInfo):void
         {
            drawable(info, function(shown:AvatarInfo):void { if (shown != null) avatar.setAvatarInfo(shown); });
         };
         try
         {
            if (userName == SocketClient.instance.myUserName) dress(clothes.getMyAvatarInfo());
            else clothes.getOthersAvatarInfo(userName, dress);
         }
         catch (e2:Error)
         {
            RLog.error("avatar " + userName, e2);
         }
         return avatar;
      }

      /**
       * The clothes of info whose big picture (skinview/<file>) the site has.
       * The album avatar loads each piece's skinview file; for a piece whose
       * file is missing its own error handler fails (it reads the failed
       * request as a ResLoader), and the pieces asked for after it, even on
       * the next avatar, were never drawn: the avatar stood blank once clothes
       * without a skinview file had been worn. Most clothes have one (later
       * copies, game/); the others are left off.
       */
      public static function drawable(info:AvatarInfo, done:Function):void
      {
         if (info == null)
         {
            done(null);
            return;
         }
         var list:Array = info.getClothes();
         var files:Array = [];
         for each (var u:* in list)
         {
            var c:Clothes = u is UserClothes ? UserClothes(u).material as Clothes : null;
            if (c != null && c.fileName && !views.hasOwnProperty(c.fileName) && files.indexOf(c.fileName) < 0) files.push(c.fileName);
         }
         var missed:Array = [];
         var finish:Function = function():void
         {
            var shown:AvatarInfo = info.clone();
            shown.setClothes(list.filter(function(u:*, i:int, a:Array):Boolean
            {
               var c:Clothes = u is UserClothes ? UserClothes(u).material as Clothes : null;
               return c == null || !c.fileName || (views[c.fileName] !== false && missed.indexOf(c.fileName) < 0);
            }));
            done(shown);
         };
         // Counted before any is asked: an answer that comes at once does not finish early.
         var waiting:int = files.length;
         if (waiting == 0)
         {
            finish();
            return;
         }
         var answer:Function = function(file:String):Function
         {
            return function(ok:Boolean):void
            {
               if (!ok) missed.push(file);
               if (--waiting == 0) finish();
            };
         };
         for each (var f:String in files) ask(f, answer(f));
      }

      /**
       * Whether skinview/<file> is a SWF the site has: views[file] true or false, kept for the
       * session only when sure (the file came, or the site answered that it has none). A page
       * the host sends instead of a missing file is no SWF. Gives up after 8 s.
       */
      private static function ask(file:String, then:Function):void
      {
         var ld:URLLoader = new URLLoader();
         ld.dataFormat = URLLoaderDataFormat.BINARY;
         var status:int = 0;
         var over:Boolean = false;
         var timer:Timer = new Timer(8000, 1);
         var end:Function = function(ok:Boolean, sure:Boolean):void
         {
            if (over) return;
            over = true;
            timer.stop();
            try { ld.close(); } catch (e0:Error) {}
            if (sure) views[file] = ok;
            then(ok);
         };
         ld.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void { status = e.status; });
         ld.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            var b:ByteArray = ld.data as ByteArray;
            var swf:Boolean = b != null && b.length > 8 && (b[0] == 0x46 || b[0] == 0x43 || b[0] == 0x5A) && b[1] == 0x57 && b[2] == 0x53;
            end(swf, true);
         });
         ld.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { end(false, status == 404 || status == 410); });
         ld.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:Event):void { end(false, false); });
         timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void { end(false, false); });
         timer.start();
         try { ld.load(VersManager.getVerURLRequest("skinview/" + file)); }
         catch (err:Error) { end(false, false); }
      }
   }
}
