package mmo.talk
{
   import flash.display.Sprite;

   /** REBUILT document class of talk/talk.swf: 私聊 listens from the moment the module is loaded. */
   public class DocTalk extends Sprite
   {
      public function DocTalk()
      {
         super();
         TalkService.instance.start();
      }

      private static function compileMe():void
      {
         var a:TalkServiceLocator, b:PrivateTalkPanel;
      }
   }
}
