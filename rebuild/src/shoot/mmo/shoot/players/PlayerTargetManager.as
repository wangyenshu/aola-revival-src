package mmo.shoot.players
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.shoot.players.effects.PlayerEffectManager;
   
   public class PlayerTargetManager
   {
      
      public static const instance:PlayerTargetManager = new PlayerTargetManager();
      
      private var shootService:IShootService;
      
      public function PlayerTargetManager()
      {
         super();
         this.shootService = ServiceContainer.getService(IShootService) as IShootService;
      }
      
      public function init() : void
      {
         PlayerManager.getInstance().addEventListener(PlayerManagerEvent.ENTER_ROOM,this.onEnterRoom);
         PlayerManager.getInstance().addEventListener(PlayerManagerEvent.LEAVE_ROOM,this.onLeaveRoom);
      }
      
      private function onEnterRoom(param1:PlayerManagerEvent) : void
      {
         this.shootService.registerTarget(new PlayerTargetHandler(param1.player,param1.player.getName()));
      }
      
      private function onLeaveRoom(param1:PlayerManagerEvent) : void
      {
         this.shootService.removeTarget(ShootTargetTypes.Player,param1.player.getName());
         PlayerEffectManager.instance.clearAllEffect(param1.player);
      }
   }
}

