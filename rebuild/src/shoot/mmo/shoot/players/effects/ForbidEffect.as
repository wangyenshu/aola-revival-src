package mmo.shoot.players.effects
{
   import mmo.common.user.UserInfo;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.scenetalk.ISceneTalkService;
   import mmo.interfaces.shoot.IShootService;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class ForbidEffect extends PlayerEffectBase
   {
      
      public function ForbidEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setForbid(true);
      }
      
      public function setForbid(param1:Boolean) : void
      {
         if(this.player.getName() != UserInfo.userName)
         {
            return;
         }
         var _loc2_:IShootService = ServiceContainer.getService(IShootService) as IShootService;
         _loc2_.shootable = !param1;
         var _loc3_:ISceneTalkService = ServiceContainer.getService(ISceneTalkService) as ISceneTalkService;
         _loc3_.isSmilable = !param1;
      }
      
      override public function get excludeKey() : String
      {
         return "ForbidEffect";
      }
      
      override public function clear() : void
      {
         this.setForbid(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

