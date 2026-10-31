package mmo.spacetime.common
{
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   
   public class TeamHelper
   {
      
      public function TeamHelper()
      {
         super();
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
   }
}

