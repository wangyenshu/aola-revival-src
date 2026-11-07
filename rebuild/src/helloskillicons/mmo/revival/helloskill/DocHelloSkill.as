package mmo.revival.helloskill
{
   import flash.display.Sprite;

   /**
    * robot/revival/helloskillicons (aola-revival): the HELLO skills' icons of May 2012, the symbols
    * of robot/robotanothermes's RobotOtherSkillicon (the skill bar of another player's HELLO), bound
    * to classes of their own for the HELLO's menu (robotmanager HelloWheel).
    */
   public class DocHelloSkill extends Sprite
   {
      public function DocHelloSkill()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [HelloSkillFollow, HelloSkillHeal, HelloSkillExp, HelloSkillHatch, HelloSkillRare, HelloSkillSort,
            HelloSkillWarehouse, HelloSkillReplace, HelloSkillTrain];
      }
   }
}
