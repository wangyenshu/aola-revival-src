package mmo.treemanager
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.material.plant.UserPlant;
   import mmo.interfaces.treemanager.*;
   import mmo.interfaces.treemanager.ITreeManager;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TreeManager. Module yz/treemanager.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.treemanager.ITreeManager) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TreeManager extends EventDispatcher implements ITreeManager
   {
      public function TreeManager()
      {
         super();
      }

      public function disposeTree(param1:int) : void
      {
         RLog.stub("TreeManager.disposeTree");
      }

      public function initTree(param1:Object, param2:UserPlant) : void
      {
         RLog.stub("TreeManager.initTree");
      }

   }
}
