package mmo.petfightnew
{
   import flash.display.MovieClip;

   /**
    * REVIVAL. The big-skill button over the skills: character 898 of the later pet/petfightnew
    * (its BigSkillMC), whose mcView's frames are 1 聚能中, 2 究极变身, 3 剩余回合 (mcNum: frame
    * n + 1 for n rounds), 7 超奥义 and 8 BOSS克星 (the later BigSkillMCHandler_ChangeView and
    * BigSkillMCHandler_AoYi).
    */
   public class BigSkillButton extends MovieClip
   {
      public var mcView:MovieClip;

      public function BigSkillButton()
      {
         super();
         stop();
         if (mcView) mcView.gotoAndStop(2);
      }

      /** Shows that frame of mcView (and, at 3, n rounds left). */
      public function show(frame:int, rounds:int = 0):void
      {
         if (mcView == null) return;
         mcView.gotoAndStop(frame);
         var num:MovieClip = mcView.getChildByName("mcNum") as MovieClip;
         if (num) num.gotoAndStop(Math.max(1, Math.min(num.totalFrames, rounds + 1)));
      }
   }
}
