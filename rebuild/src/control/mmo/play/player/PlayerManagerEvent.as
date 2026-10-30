package mmo.play.player
{
   import flash.events.Event;
   import mmo.play.player.sceneplayer.PlayerBase;

   /** REBUILT. A player entered or left the current room. */
   public final class PlayerManagerEvent extends Event
   {
      public static const ENTER_ROOM:String = "onPlayerEnterRoom";
      public static const LEAVE_ROOM:String = "onPlayerLeaveRoom";
      public static const AVATAR_HIDE:String = "onPlayerAvatarHide";
      public static const AVATAR_SHOW:String = "onPlayerAvatarShow";

      private var _userName:String;
      private var _player:PlayerBase;
      private var _params:Object;

      public function PlayerManagerEvent(type:String, userName:String, player:PlayerBase = null, params:Object = null)
      {
         super(type);
         _userName = userName;
         _player = player;
         _params = params || {};
      }

      public function get userName():String
      {
         return _userName;
      }

      public function get player():PlayerBase
      {
         return _player;
      }

      public function get params():Object
      {
         return _params;
      }

      override public function clone():Event
      {
         return new PlayerManagerEvent(type, _userName, _player, _params);
      }
   }
}
