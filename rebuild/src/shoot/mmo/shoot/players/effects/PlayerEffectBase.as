package mmo.shoot.players.effects
{
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class PlayerEffectBase implements IDispose
   {
      
      private var _player:PlayerBase;
      
      private var _params:*;
      
      public function PlayerEffectBase(param1:PlayerBase, param2:Object)
      {
         super();
         this._player = param1;
         this._params = param2;
      }
      
      public function get player() : PlayerBase
      {
         return this._player;
      }
      
      public function get params() : Object
      {
         return this._params;
      }
      
      public function apply() : void
      {
      }
      
      public function clear() : void
      {
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("ClearPlayerEffect",{"EffectKey":this.excludeKey}));
         this._player = null;
      }
      
      public function get excludeKey() : String
      {
         throw new Error("must implement");
      }
   }
}

