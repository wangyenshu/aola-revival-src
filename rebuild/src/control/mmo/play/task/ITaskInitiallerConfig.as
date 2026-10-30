package mmo.play.task
{
   /**
    * LATER interface (the live play.swf's mmo.play.task, decompiled; unchanged):
    * the tables of a quest run by NewBaseTaskInitialler (tasks 2298 and 2314,
    * whose scripts survive only as their 2018 uploads).
    */
   public interface ITaskInitiallerConfig
   {
      
      function getNpcsByTaskIdAndScene(param1:int, param2:String) : Array;
      
      function getNpcsByTaskId(param1:int) : Array;
      
      function getNpcPosByScene(param1:String, param2:String) : Object;
      
      function getAllNpc() : Array;
      
      function getNpcsAfterAction(param1:String) : Array;
      
      function getStartTaskId() : int;
      
      function getEndTaskId() : int;
      
      function getNpcPanelKeyByTaskId(param1:int) : String;
      
      function getNpcPanelKeyByResName(param1:String) : String;
      
      function isShowFinishPanel() : Boolean;
      
      function getFightHandlerByFightObjectKey(param1:String) : String;
      
      function getFileData() : Object;
   }
}

