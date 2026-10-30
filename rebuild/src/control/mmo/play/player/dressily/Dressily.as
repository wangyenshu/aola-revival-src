package mmo.play.player.dressily
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.utils.Dictionary;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.AvatarEvent;
   import mmo.interfaces.avatar.AvatarProxyEvent;
   import mmo.interfaces.avatar.IAvatarService;
   import mmo.interfaces.avatar.ISceneAvatarProxy;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.revival.RLog;

   /**
    * REBUILT. Wraps a scene avatar proxy of the original 2012-12 avatar
    * service (material/avatarservice): new Dressily(forbiddenActions, avatarInfo).
    * Action codes are a direction (dd uu ll rr ld rd lu ru) plus "zn" (stand)
    * or "wn" (walk).
    */
   public class Dressily extends EventDispatcher implements IDressily
   {
      private var _avatarSprite:Sprite;
      protected var _avatarProxy:ISceneAvatarProxy;
      private var _forbiddenAction:Dictionary;

      public function Dressily(forbidden:Dictionary = null, info:AvatarInfo = null)
      {
         super();
         _forbiddenAction = forbidden;
         try
         {
            var svc:IAvatarService = ServiceContainer.getService(IAvatarService) as IAvatarService;
            _avatarProxy = svc.getSceneAvatarProxy(forbidden);
            _avatarProxy.addEventListener(AvatarEvent.AVATAR_SPRITE_COMPLETED, onSpriteCompleted);
            _avatarProxy.addEventListener(AvatarProxyEvent.onRender, onProxyRender);
            _avatarSprite = _avatarProxy.getSprite();
            if (info != null) _avatarProxy.setAvatarInfo(info);
         }
         catch (err:Error)
         {
            RLog.error("Dressily: avatar service", err);
            _avatarProxy = null;
            _avatarSprite = placeholder();
         }
      }

      private static function placeholder():Sprite
      {
         var s:Sprite = new Sprite();
         s.graphics.beginFill(0x3A8EE6);
         s.graphics.drawEllipse(-14, -70, 28, 70);
         s.graphics.endFill();
         return s;
      }

      public function get top():Number
      {
         return _avatarProxy ? _avatarProxy.top : -80;
      }

      public function get avatarSprite():DisplayObject
      {
         return _avatarSprite;
      }

      public function action(code:String):void
      {
         if (_avatarProxy != null && _avatarProxy.action(code))
         {
            dispatchEvent(new DressilyEvent(DressilyEvent.ACTION_BEGIN, {action: code}));
         }
      }

      public function currentAction():String
      {
         return _avatarProxy ? _avatarProxy.currentAction() : null;
      }

      public function setAvatar(avatar:Object):void
      {
         if (avatar == null || _avatarProxy == null) return;
         var info:AvatarInfo = avatar as AvatarInfo;
         if (info == null)
         {
            info = new AvatarInfo();
            info.setAvatarInfoWithString(String(avatar));
         }
         _avatarProxy.setAvatarInfo(info);
      }

      public function getAvatar():AvatarInfo
      {
         return _avatarProxy ? _avatarProxy.getAvatarInfo() : null;
      }

      public function dispose():void
      {
         if (_avatarProxy != null)
         {
            _avatarProxy.removeEventListener(AvatarEvent.AVATAR_SPRITE_COMPLETED, onSpriteCompleted);
            _avatarProxy.removeEventListener(AvatarProxyEvent.onRender, onProxyRender);
            _avatarProxy.dispose();
            _avatarProxy = null;
         }
         _avatarSprite = null;
      }

      private function onSpriteCompleted(e:Event):void
      {
         if (_avatarProxy == null) return;
         var a:String = currentAction();
         _avatarProxy.action(a != null && a.length >= 3 ? a : "ddzn");
         dispatchEvent(new DressilyEvent(DressilyEvent.DRESS_COMPLETED));
      }

      private function onProxyRender(e:Event):void
      {
         dispatchEvent(new DressilyEvent(DressilyEvent.onRender));
      }
   }
}
