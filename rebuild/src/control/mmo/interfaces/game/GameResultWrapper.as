package mmo.interfaces.game
{
   /**
    * LATER: the later interfaces' reader of a mini game's result (score
    * added, the result state and its words), which the later copies of the
    * 生态园 保卫战 games (game/pvz, guardnut, seadefend) use at the end of
    * their 地狱模式. The 2013 interfaces lack it; it is in play.swf so those
    * games find it. Written from the later class.
    */
   public class GameResultWrapper
   {
      private static const DEFAULT_RESULT_DESC:Object = {
         "1":"",
         "-1":"你今天已达到了每日晶币获得上限，不能再获得奖励了。",
         "-2":"你已探险了太长时间，小奥拉体力消耗殆尽，已不能获得奖励了。",
         "-3":"你已探险了很长时间，小奥拉体力消耗了不少，只能获得一半的奖励了。",
         "-4":"你今天已达到了该游戏每日晶币的获得上限，不能再获得晶币了，可以去玩下别的游戏噢！",
         "-5":"你今天已达到了所有小游戏每日晶币的获得上限，不能再获得晶币了，可以去玩下其他的活动噢！"
      };

      private var param:Object;

      public function GameResultWrapper(param:Object)
      {
         super();
         this.param = param || {};
      }

      public function get score():int
      {
         return getInt("scoreAdded");
      }

      public function get gameResultState():int
      {
         return getInt("state");
      }

      public function getDefaultDesc():String
      {
         return DEFAULT_RESULT_DESC[String(gameResultState)] || "";
      }

      public function getInt(key:String):int
      {
         return param.hasOwnProperty(key) ? parseInt(param[key]) : -1;
      }

      public function getNumber(key:String):Number
      {
         return param.hasOwnProperty(key) ? parseFloat(param[key]) : -1;
      }

      public function getString(key:String):String
      {
         return param.hasOwnProperty(key) ? String(param[key]) : null;
      }

      public function getList(key:String):Array
      {
         return param.hasOwnProperty(key) ? param[key] as Array : null;
      }
   }
}
