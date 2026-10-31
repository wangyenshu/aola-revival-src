package mmo.fbteam.fbsuolide.sceneplayer
{
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   
   public class FBSuolideScenePlayerBase extends ScenePlayerStepBase
   {
      
      private var actionObj:Object = {};
      
      private var sycObj:Object = {};
      
      private var sycAction:Object = {};
      
      private var backData:Object = {};
      
      public function FBSuolideScenePlayerBase()
      {
         super();
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey)
         {
            if(this.sycObj[param1.what] != null)
            {
               if(param1.data.par != null)
               {
                  this.sycObj[param1.what].fun.apply(null,[param1.data.par]);
               }
               else
               {
                  this.sycObj[param1.what].fun.apply();
               }
            }
         }
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(this.backData[param1.what] != null && this.backData[param1.what].what == param1.what)
         {
            this.backData[param1.what].fun.apply();
         }
      }
      
      protected function setBackNotify(param1:Function, param2:Object, param3:Boolean = false) : void
      {
         this.backData[param2.what] = param2;
         this.backData[param2.what].fun = param1;
         if(param3)
         {
            this.notifyBack(param2);
         }
      }
      
      protected function setSycFunWithKeyAndAction(param1:Function, param2:Object, param3:String) : void
      {
         this.sycAction[param3] = param2;
         this.setNotify(param1,param2);
      }
      
      protected function setNotify(param1:Function, param2:Object, param3:Boolean = false) : void
      {
         this.sycObj[param2.what] = param2;
         this.sycObj[param2.what].fun = param1;
         if(param3)
         {
            this.notify(param2);
         }
      }
      
      protected function addNotifyParams(param1:Object, param2:Object) : void
      {
         this.sycObj[param1.what].par = param2;
      }
      
      protected function notify(param1:Object) : void
      {
         FBTeamSynchronizedClient.notify(this.sycObj[param1.what]);
      }
      
      protected function notifyBack(param1:Object) : void
      {
         FBTeamSynchronizedClient.notifyBack(this.backData[param1.what]);
      }
      
      protected function doFunWithAction(param1:Function, param2:String) : void
      {
         this.actionObj[param2] = param1;
      }
      
      protected function onAction(param1:TaskEvent) : void
      {
         if(this.sycAction[param1.params.action] != null)
         {
            FBTeamSynchronizedClient.notify(this.sycAction[param1.params.action]);
         }
         if(this.actionObj[param1.params.action] != null)
         {
            this.actionObj[param1.params.action].apply();
         }
         var _loc2_:* = param1.params.action;
         switch(0)
         {
         }
      }
      
      protected function disposeEvt() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
      }
   }
}

