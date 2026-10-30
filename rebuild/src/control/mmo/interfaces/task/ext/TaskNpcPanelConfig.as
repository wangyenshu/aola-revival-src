package mmo.interfaces.task.ext
{
   /**
    * LATER class (from the later control's mmo.interfaces.task.ext, unchanged),
    * carried in the rebuilt play.swf so it is in the main application domain.
    *
    * The task scripts of the 2012 story quests that survive only as their
    * 2015–2019 uploads keep their NPC conversations in a subclass of this
    * (Task<id>NpcPanelConfig) and hand it to the NPC service with
    * ITaskNpcService.setTaskNpcPanelConfig, which the January 2013 interface
    * does not have (the rebuilt task/tasknpc answers it; see TaskNpcService).
    */
   public class TaskNpcPanelConfig
   {
      protected var _npcStarterTalkConfig:Array = [];
      protected var _npcTaskTalkConfig:Array = [];
      protected var _npcFreeTaskTalkConfig:Array = [];

      public function TaskNpcPanelConfig()
      {
         super();
         this.initTask();
         this.initFreeTalk();
         this.initStarter();
      }

      protected function initTask():void
      {
      }

      protected function initFreeTalk():void
      {
      }

      protected function initStarter():void
      {
      }

      public function get npcTaskTalkConfig():Array
      {
         return _npcTaskTalkConfig;
      }

      public function get npcFreeTaskTalkConfig():Array
      {
         return _npcFreeTaskTalkConfig;
      }

      public function get npcStarterTalkConfig():Array
      {
         return _npcStarterTalkConfig;
      }
   }
}
