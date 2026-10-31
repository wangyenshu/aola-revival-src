package mmo.fbteam.common
{
   import flash.geom.Point;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   import mmo.interfaces.team.TeamMemberInfo;
   import mmo.interfaces.userstate.IUserStateService;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class TeamHelper
   {
      
      public function TeamHelper()
      {
         super();
      }
      
      public static function isInMulMemberTeam() : Boolean
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc2_:TeamInfo = _loc1_.getMyTeam();
         if(null != _loc2_ && _loc2_.teamLength > 1)
         {
            return true;
         }
         return false;
      }
      
      public static function isCaptain() : Boolean
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc2_:TeamInfo = _loc1_.getMyTeam();
         var _loc3_:String = SocketClient.instance.myUserName;
         if(null == _loc2_ || _loc2_.leader == _loc3_)
         {
            return true;
         }
         return false;
      }
      
      public static function getTeamKey() : String
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc2_:TeamInfo = _loc1_.getMyTeam();
         if(null == _loc2_)
         {
            return SocketClient.instance.myUserName;
         }
         return _loc2_.key;
      }
      
      public static function isTeamMember() : Boolean
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc2_:TeamInfo = _loc1_.getMyTeam();
         if(null == _loc2_)
         {
            return false;
         }
         return true;
      }
      
      public static function checkCount(param1:int) : Boolean
      {
         var _loc2_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc3_:TeamInfo = _loc2_.getMyTeam();
         if(null == _loc3_)
         {
            if(param1 >= 1)
            {
               return true;
            }
            return false;
         }
         if(_loc3_.teamLength <= param1)
         {
            return true;
         }
         return false;
      }
      
      public static function setState(param1:int, param2:String = "") : void
      {
         var _loc3_:IUserStateService = ServiceContainer.getService(IUserStateService) as IUserStateService;
         _loc3_.setMyState(param1,param2);
      }
      
      public static function cleanState() : void
      {
         var _loc1_:IUserStateService = ServiceContainer.getService(IUserStateService) as IUserStateService;
         _loc1_.clearMyState();
      }
      
      public static function jumpTo(param1:Point) : void
      {
         var _loc2_:ITeamService = null;
         var _loc3_:TeamInfo = null;
         var _loc4_:Array = null;
         var _loc5_:TeamMemberInfo = null;
         var _loc6_:PlayerBase = null;
         var _loc7_:String = null;
         if(isTeamMember())
         {
            _loc2_ = ServiceContainer.getService(ITeamService) as ITeamService;
            _loc3_ = _loc2_.getMyTeam();
            _loc4_ = [_loc3_.leader];
            for each(_loc5_ in _loc3_.members)
            {
               _loc4_.push(_loc5_.userName);
            }
            _loc6_ = null;
            for each(_loc7_ in _loc4_)
            {
               _loc6_ = PlayerManager.getInstance().playerList[_loc7_] as PlayerBase;
               if(null != _loc6_)
               {
                  _loc6_.x = param1.x;
                  _loc6_.y = param1.y;
               }
            }
         }
         PlayerManager.getInstance().myPlayer.x = param1.x;
         PlayerManager.getInstance().myPlayer.y = param1.y;
         PlayerManager.getInstance().myPlayer.jumpTo(param1.x,param1.y);
      }
   }
}

