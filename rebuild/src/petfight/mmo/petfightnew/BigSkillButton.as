package mmo.petfightnew
{
   import flash.display.MovieClip;
   import flash.text.TextField;

   /**
    * REVIVAL. The big-skill button over the skills: character 898 of the later pet/petfightnew
    * (its BigSkillMC), whose mcView's frames are 1 聚能中, 2 究极变身, 3 剩余回合 (mcNum: frame
    * n + 1 for n rounds), 4 坐骑召唤 and 5 the 契约技能's name (txtSkillName), 7 超奥义 and 8 BOSS克星
    * (the later BigSkillMCHandler_ChangeView, BigSkillMCHandler_Bargain and BigSkillMCHandler_AoYi).
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

      /** Shows that frame of mcView (at 3, n rounds left; at 5, the 契约技能's name). */
      public function show(frame:int, rounds:int = 0, skillName:String = ""):void
      {
         if (mcView == null) return;
         mcView.gotoAndStop(frame);
         var num:MovieClip = mcView.getChildByName("mcNum") as MovieClip;
         if (num) num.gotoAndStop(Math.max(1, Math.min(num.totalFrames, rounds + 1)));
         var name:TextField = mcView.getChildByName("txtSkillName") as TextField;
         if (name)
         {
            name.mouseEnabled = false;
            name.text = skillName;
         }
      }
   }
}
