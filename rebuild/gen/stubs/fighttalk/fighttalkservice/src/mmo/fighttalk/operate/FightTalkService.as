package mmo.fighttalk.operate
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fighttalk.*;
   import mmo.interfaces.fighttalk.IFightTalk;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FightTalkService. Module fighttalk/fighttalkservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fighttalk.IFightTalk) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FightTalkService extends EventDispatcher implements IFightTalk
   {
      public function FightTalkService()
      {
         super();
      }

      public function getTalkPanel() : Sprite
      {
         RLog.stub("FightTalkService.getTalkPanel");
         return null;
      }

      public function petSaySkill(param1:String) : void
      {
         RLog.stub("FightTalkService.petSaySkill");
      }

      public function reSetSystemFightMessage(param1:String) : void
      {
         RLog.stub("FightTalkService.reSetSystemFightMessage");
      }

      public function init() : void
      {
         RLog.stub("FightTalkService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
