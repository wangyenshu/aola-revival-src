package mmo.revival.wnking
{
   import flash.display.Sprite;
   import mmo.activity130221.wolfandnightking.WNKingBuyConfirmPanel;
   import mmo.activity130221.wolfandnightking.WNKingChallengeMainPanel;
   import mmo.activity130221.wolfandnightking.WNKingChallengePanel;
   import mmo.activity130221.wolfandnightking.WNKingChallengeTipsPanel;
   import mmo.activity130221.wolfandnightking.WNKingFinalChallengePanel;
   import mmo.activity130221.wolfandnightking.WNKingFinalTipsPanel;
   import mmo.activity130221.wolfandnightking.WNKingItemFightPanel;
   import mmo.activity130221.wolfandnightking.WNKingManager;
   import mmo.activity130221.wolfandnightking.WNKingStarPanel;

   /**
    * activityres/activity130221/wolfandnightking (夜王复出！狼王再现！, February 2013; its copy of 2016)
    * on the 2013 libraries (aola-revival): its decompiled code on its own art, the later re-run's
    * changes taken out (the main panel shown again, not the 夜王 panel alone; no 快速挑战, 至尊秘籍,
    * 领取夜王 or 坐骑 link; the 背包, 治疗 and 远程仓库 buttons on the 2013 services).
    */
   public class DocWNKing extends Sprite
   {
      public function DocWNKing()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [WNKingManager, WNKingChallengeMainPanel, WNKingChallengePanel, WNKingItemFightPanel, WNKingStarPanel,
            WNKingFinalChallengePanel, WNKingBuyConfirmPanel, WNKingChallengeTipsPanel, WNKingFinalTipsPanel];
      }
   }
}
