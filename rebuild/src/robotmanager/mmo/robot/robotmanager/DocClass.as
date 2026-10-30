package mmo.robot.robotmanager
{
   import flash.display.Sprite;

   /**
    * REBUILT document class of init/robotmanager.swf. The module is a <play>
    * module with no service of its own in the 2013 ServiceConfig: like the
    * later copy's, loading it is what starts the HELLO manager.
    */
   public class DocClass extends Sprite
   {
      public function DocClass()
      {
         super();
         RobotManager.instance.init();
      }

      private static function compileMe():void
      {
         var a:RobotManager, b:RobotAvatar;
      }
   }
}
