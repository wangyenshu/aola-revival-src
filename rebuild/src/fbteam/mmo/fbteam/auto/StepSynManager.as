package mmo.fbteam.auto
{
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamMemberInfo;
   import mmo.interfaces.team.TeamServiceEvent;
   
   public class StepSynManager implements IDispose
   {
      
      private static var _instance:StepSynManager = null;
      
      private const synData:Object = {"what":FBTeamCommonTypes.STEP_END};
      
      private var teamService:ITeamService = null;
      
      private var finishCount:int = 0;
      
      private var finishNames:Array = [];
      
      private var callback:Function = null;
      
      private var funObj:Object = null;
      
      private var args:Array = null;
      
      private var isSyning:Boolean = false;
      
      public function StepSynManager()
      {
         super();
         this.teamService = ServiceContainer.getService(ITeamService) as ITeamService;
      }
      
      public static function get instance() : StepSynManager
      {
         if(null == _instance)
         {
            _instance = new StepSynManager();
         }
         return _instance;
      }
      
      public function init() : void
      {
         this.initListener();
      }
      
      public function dispose() : void
      {
         this.disposeListener();
         _instance = null;
      }
      
      public function synStep(param1:Function, param2:Object, param3:Array) : void
      {
         this.callback = param1;
         this.funObj = param2;
         this.args = param3;
         this.isSyning = true;
         FBTeamSynchronizedClient.notifyBack(this.synData);
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBTeamCommonTypes.STEP_END == param1.what)
         {
            ++this.finishCount;
            this.finishNames.push(param1.userName);
            this.checkFinish();
         }
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(this.isSyning && TeamHelper.getTeamKey() == param1.teamKey && FBTeamCommonTypes.STEP_END == param1.what)
         {
            this.callback.apply(this.funObj,this.args);
            this.reset();
         }
      }
      
      private function onMemberLeave(param1:TeamServiceEvent) : void
      {
         var _loc2_:TeamMemberInfo = param1.params.member as TeamMemberInfo;
         if(this.finishNames.indexOf(_loc2_.userName) != -1)
         {
            --this.finishCount;
         }
         else
         {
            this.checkFinish();
         }
      }
      
      private function checkFinish() : void
      {
         if(TeamHelper.checkCount(this.finishCount) && null != this.callback)
         {
            FBTeamSynchronizedClient.finishBack(this.synData);
         }
      }
      
      private function reset() : void
      {
         this.finishCount = 0;
         this.callback = null;
         this.funObj = null;
         this.args = null;
         this.isSyning = false;
      }
      
      private function initListener() : void
      {
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.teamService.addEventListener(TeamServiceEvent.onMemberLeave,this.onMemberLeave);
      }
      
      private function disposeListener() : void
      {
         this.reset();
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.teamService.removeEventListener(TeamServiceEvent.onMemberLeave,this.onMemberLeave);
      }
   }
}

