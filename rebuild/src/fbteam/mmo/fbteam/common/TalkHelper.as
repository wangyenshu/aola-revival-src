package mmo.fbteam.common
{
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.userstate.UserStates;
   
   public class TalkHelper
   {
      
      public function TalkHelper()
      {
         super();
      }
      
      public static function openFBtalkMode() : void
      {
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_END_NPC_TALK,onEndNpcTalk);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_START_NPC_TALK,onStartNpcTalk);
      }
      
      public static function closeFBtalkMode() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_END_NPC_TALK,onEndNpcTalk);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_START_NPC_TALK,onStartNpcTalk);
      }
      
      private static function onStartNpcTalk(param1:TaskEvent) : void
      {
         TeamHelper.setState(UserStates.FBSpeaking);
      }
      
      private static function onEndNpcTalk(param1:TaskEvent) : void
      {
         TeamHelper.cleanState();
      }
   }
}

