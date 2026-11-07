package mmo.useravatar
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import mmo.interfaces.avatar.IAlbumAvatarProxy;
   import mmo.interfaces.useravatar.IUserAvatarService;
   import mmo.revival.RAvatar;

   /**
    * REBUILT useravatar/useravatarservice (UserAvatarService; the January 2013 module is lost):
    * a player's avatar in its big pictures (the album avatar of the 2013 avatar service,
    * mmo.revival.RAvatar) put into holder at x, y, scaled sx, sy.
    */
   public class UserAvatarService extends EventDispatcher implements IUserAvatarService
   {
      public function UserAvatarService()
      {
         super();
      }

      public function showUserAvatar(userName:String, holder:MovieClip, sx:Number, sy:Number, x:int, y:int):void
      {
         if (holder == null || !userName) return;
         var avatar:IAlbumAvatarProxy = RAvatar.show(userName, holder);
         if (avatar == null) return;
         var s:Sprite = avatar.getSprite();
         s.scaleX = sx;
         s.scaleY = sy;
         s.x = x;
         s.y = y;
      }
   }
}
