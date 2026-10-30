package mmo.game.common
{
   /**
    * LATER (game/gamemanager of 2015, decompiled): each game's entrance panel,
    * [file, class]; the panel files are era ones up to gameentrance13.
    */
   public class GameMap
   {
      
      private static const map:Object = {
         1:["gameentrancepanel/gameentrance","mmo.game.makelantern.EntranceRes"],
         2:["gameentrancepanel/gameentrance","mmo.game.flycat.EntranceRes"],
         3:["gameentrancepanel/gameentrance","mmo.game.gamellk.EntranceRes"],
         4:["gameentrancepanel/gameentrance","mmo.game.gameAolaVsDaserte.EntranceRes"],
         5:["gameentrancepanel/gameentrance2","mmo.game.gameRopedancer.EntranceRes"],
         6:["gameentrancepanel/gameentrance2","mmo.game.gameDragonBoat.EntranceRes"],
         7:["gameentrancepanel/gameentrance2","mmo.game.gameYabijiyiji.EntranceRes"],
         8:["gameentrancepanel/gameentrance2","mmo.game.flyprince.EntranceRes"],
         9:["gameentrancepanel/gameentrance3","mmo.game.gameHelloWhodisappear.EntranceRes"],
         10:["gameentrancepanel/gameentrance3","mmo.game.gameHelloLittleToMore.EntranceRes"],
         11:["gameentrancepanel/gameentrance3","mmo.game.gameHelloruleanalyze.EntranceRes"],
         12:["gameentrancepanel/gameentrance4","mmo.game.gameRecycleGame.EntranceRes"],
         13:["gameentrancepanel/gameentrance4","mmo.game.gameShootGame.EntranceRes"],
         14:["gameentrancepanel/gameentrance5","mmo.game.gameMakeCake.EntranceRes"],
         15:["gameentrancepanel/gameentrance4","mmo.game.gameSlamDunk.EntranceRes"],
         16:["gameentrancepanel/gameentrance4","mmo.game.gameYiNiJump.EntranceRes"],
         17:["gameentrancepanel/gameentrance5","mmo.game.gameMakeMooncake.EntranceRes"],
         18:["gameentrancepanel/gameentrance5","mmo.game.gameBlowBubble.EntranceRes"],
         19:["gameentrancepanel/gameentrance5","mmo.game.gameFlyingUnicorn.EntraceRes"],
         20:["gameentrancepanel/gameentrance6","mmo.game.gameSwimming.EntranceRes"],
         21:["gameentrancepanel/gameentrance6","mmo.game.gameMatchThree.EntranceRes"],
         22:["gameentrancepanel/gameentrance6","mmo.game.gameGhostHoliday.EntranceRes"],
         23:["gameentrancepanel/gameentrance6","mmo.game.gameOneLine.EntranceRes"],
         24:["gameentrancepanel/gameentrance6","mmo.game.gamePuzzleBobble.EntranceRes"],
         25:["gameentrancepanel/gameentrance7","mmo.game.gameBrickGame.EntranceRes"],
         26:["gameentrancepanel/gameentrance8","mmo.game.gameHitBrick.EntranceRes"],
         27:["gameentrancepanel/gameentrance8","mmo.game.gameEatBeans.EntranceRes"],
         28:["gameentrancepanel/gameentrance8","mmo.game.gameZillionaire.EntranceRes"],
         29:["gameentrancepanel/gameentrance8","mmo.game.gameYaYaEatBeans.EntranceRes"],
         30:["gameentrancepanel/gameentrance8","mmo.game.gameZuMa.EntranceRes"],
         31:["gameentrancepanel/gameentrance9","mmo.game.gameReunionGame.EntranceRes"],
         32:["gameentrancepanel/gameentrance9","mmo.game.gameTangyuan.EntranceRes"],
         33:["gameentrancepanel/gameentrance9","mmo.game.gameFlyStone.EntranceRes"],
         34:["gameentrancepanel/gameentrance9","mmo.game.gameMyCat.EntranceRes"],
         35:["gameentrancepanel/gameentrance10","mmo.game.gameLoveFes.EntranceRes"],
         36:["gameentrancepanel/gameentrance10","mmo.game.gameAnimalRun.EntranceRes"],
         37:["gameentrancepanel/gameentrance10","mmo.game.gameflygame.EntranceRes"],
         38:["gameentrancepanel/gameentrance10","mmo.game.gamekafuCookie.EntranceRes"],
         39:["gameentrancepanel/gameentrance11","mmo.game.gameFighting.EntranceRes"],
         40:["gameentrancepanel/gameentrance11","mmo.game.gamecarsurf.EntranceRes"],
         41:["gameentrancepanel/gameentrance11","mmo.game.gamelubijump.EntranceRes"],
         42:["gameentrancepanel/gameentrance11","mmo.game.gameMemoryCard.EntranceRes"],
         43:["gameentrancepanel/gameentrance12","mmo.game.gameFlyingQiQi.EntranceRes"],
         44:["gameentrancepanel/gameentrance12","mmo.game.gameYaYaSlamDunk.EntranceRes"],
         45:["gameentrancepanel/gameentrance12","mmo.game.gameDropIcePieces.EntranceRes"],
         46:["gameentrancepanel/gameentrance12","mmo.game.gameThrowBalls.EntranceRes"],
         47:["gameentrancepanel/gameentrance13","mmo.game.carfu.EntranceRes"],
         48:["gameentrancepanel/gameentrance13","mmo.game.eatbird.EntranceRes"],
         50:["gameentrancepanel/gameentrance13","mmo.game.iceskating.EntranceRes"],
         51:["gameentrancepanel/gameentrance13","mmo.game.lelerun.EntranceRes"],
         52:["gameentrancepanel/gameentrance14","mmo.game.cleanice.EntranceRes"],
         53:["gameentrancepanel/gameentrance14","mmo.game.castleescape.EntranceRes"],
         54:["gameentrancepanel/gameentrance14","mmo.game.towerboxx.EntranceRes"],
         55:["gameentrancepanel/gameentrance15","mmo.game.hungrymonster.EntranceRes"],
         56:["gameentrancepanel/gameentrance15","mmo.game.gameJumpFireRing.EntranceRes"],
         57:["gameentrancepanel/gameentrance15","mmo.game.gameChocolateRabbit.EntranceRes"],
         60:["gameentrancepanel/gameentrance15","mmo.game.gameGoldPitman.EntranceRes"],
         62:["gameentrancepanel/gameentrance16","mmo.game.gameCatchFish.EntranceRes"],
         63:["gameentrancepanel/gameentrance16","mmo.game.gamePrincemazegather.EntranceRes"],
         64:["gameentrancepanel/gameentrance16","mmo.game.gameLimitBomb.EntranceRes"],
         66:["gameentrancepanel/gameentrance16","mmo.game.gameNinjaRush.EntranceRes"],
         67:["gameentrancepanel/gameentrance17","mmo.game.magicccd.EntranceRes"],
         72:["game/flyingfruitres","mmo.game.flyingfruit.panel.GamePrePanelEnterance"]
      };
      
      public function GameMap()
      {
         super();
      }
      
      public static function getGameEntranceRes(param1:int) : String
      {
         return map[param1] ? map[param1][0] : null;
      }
      
      public static function getGameEntranceClass(param1:int) : String
      {
         return map[param1] ? map[param1][1] : null;
      }
   }
}

