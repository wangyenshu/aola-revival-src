package mmo.game.parkour.client
{
   import mmo.framework.comm.SocketClient;
   
   public class ParkourClient
   {
      
      private static const XtName:String = "HolidayExtension";
      
      private static const CmdHead:String = "ActKuPaoStarWorld";
      
      public static const CmdGetMainInfo:String = CmdHead + "_panel";
      
      public static const CmdUpRoleLevel:String = CmdHead + "_upgradeRole";
      
      public static const CmdUpRidePetLevel:String = CmdHead + "_upgradeRidePet";
      
      public static const CmdBuyRole:String = CmdHead + "_gainRole";
      
      public static const CmdBuyRidePet:String = CmdHead + "_gainRidePet";
      
      public static const CmdStartGame:String = CmdHead + "_startGame";
      
      public static const CmdEndGame:String = CmdHead + "_endGame";
      
      public static const CmdRelive:String = CmdHead + "_sReStartGame";
      
      public static const CmdBuyMoney:String = CmdHead + "_buyJingBi";
      
      public static const CmdBuyLove:String = CmdHead + "_buyEngery";
      
      public static const CmdCheckReward:String = CmdHead + "_getAllGB";
      
      public static const CmdGetReward:String = CmdHead + "_gainGB";
      
      public static const CmdDailySign:String = CmdHead + "_dailySign";
      
      public static const CmdCheckDailyTask:String = CmdHead + "_dailyTaskPanel";
      
      public static const CmdGetDailyTaskReward:String = CmdHead + "_gainDailyTask";
      
      public static const CmdAddProgDailyTask:String = CmdHead + "_dailyTaskFinish";
      
      public static const CmdRentRole:String = CmdHead + "_rent";
      
      public function ParkourClient()
      {
         super();
      }
      
      private static function sendXtMessage(param1:String, param2:Object) : void
      {
         SocketClient.instance.sendXtMessage(XtName,param1,param2);
      }
      
      public static function getMainInfo() : void
      {
         sendXtMessage(CmdGetMainInfo,{});
      }
      
      public static function upRidePetLevel(param1:int) : void
      {
         sendXtMessage(CmdUpRidePetLevel,{"id":param1});
      }
      
      public static function upRoleLevel(param1:int) : void
      {
         sendXtMessage(CmdUpRoleLevel,{"id":param1});
      }
      
      public static function buyRole(param1:int) : void
      {
         sendXtMessage(CmdBuyRole,{"id":param1});
      }
      
      public static function buyRidePet(param1:int) : void
      {
         sendXtMessage(CmdBuyRidePet,{"id":param1});
      }
      
      public static function startGame(param1:int, param2:int, param3:Boolean) : void
      {
         sendXtMessage(CmdStartGame,{
            "pId":param1,
            "rId":param2,
            "ir":param3
         });
      }
      
      public static function endGame(param1:int, param2:int, param3:int) : void
      {
         sendXtMessage(CmdEndGame,{
            "t":param1,
            "l":param2,
            "sc":param3
         });
      }
      
      public static function relive(param1:int, param2:int, param3:int, param4:int, param5:int) : void
      {
         sendXtMessage(CmdRelive,{
            "pId":param1,
            "rId":param2,
            "t":param3,
            "l":param4,
            "sc":param5
         });
      }
      
      public static function buyMoney(param1:int) : void
      {
         sendXtMessage(CmdBuyMoney,{"id":param1});
      }
      
      public static function buyLove(param1:int) : void
      {
         sendXtMessage(CmdBuyLove,{"id":param1});
      }
      
      public static function checkReward() : void
      {
         sendXtMessage(CmdCheckReward,{});
      }
      
      public static function getReward(param1:int) : void
      {
         sendXtMessage(CmdGetReward,{"gId":param1});
      }
      
      public static function dailySign(param1:int) : void
      {
         sendXtMessage(CmdDailySign,{"dId":param1});
      }
      
      public static function checkDailyTask() : void
      {
         sendXtMessage(CmdCheckDailyTask,{});
      }
      
      public static function getDailyTaskReward(param1:int) : void
      {
         sendXtMessage(CmdGetDailyTaskReward,{"tId":param1});
      }
      
      public static function addProgDailyTask(param1:String) : void
      {
         sendXtMessage(CmdAddProgDailyTask,{"tId":param1});
      }
      
      public static function rentRole(param1:int) : void
      {
         sendXtMessage(CmdRentRole,{"rId":param1});
      }
   }
}

