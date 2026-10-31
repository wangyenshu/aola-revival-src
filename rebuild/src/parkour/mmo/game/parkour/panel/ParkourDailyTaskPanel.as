package mmo.game.parkour.panel
{
   import mmo.common.ProgressFullSprite;
   import mmo.common.parse.Parse;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourDailyTaskConfig;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.dailytask.ParkourDailyTaskData;
   import mmo.game.parkour.data.dailytask.ParkourDailyTaskInfo;
   import mmo.game.parkour.panel.ui.ParkourDailyTaskScrollComponent;
   
   public class ParkourDailyTaskPanel extends ParkourPanelBase
   {
      
      private var infos:Array = [];
      
      private var scrollComponent:ParkourDailyTaskScrollComponent;
      
      public function ParkourDailyTaskPanel()
      {
         super(ParkourResConfig.DailyTaskPanel);
      }
      
      override protected function onShowPanel() : void
      {
         this.scrollComponent = new ParkourDailyTaskScrollComponent(panel.mcTask);
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdCheckDailyTask,this.onCmdCheckDailyTask);
         ParkourClient.checkDailyTask();
      }
      
      private function onCmdCheckDailyTask(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdCheckDailyTask,this.onCmdCheckDailyTask);
         var _loc2_:Array = this.parseTaskDatas(param1.params);
         this.scrollComponent.updateInfos(_loc2_);
         showThisPanel();
      }
      
      private function parseTaskDatas(param1:Object) : Array
      {
         var _loc7_:int = 0;
         var _loc8_:ParkourDailyTaskInfo = null;
         var _loc9_:ParkourDailyTaskData = null;
         var _loc2_:Array = [0,1,2,3,4].concat(param1.rt);
         var _loc3_:Array = (param1.rds as String).split(",");
         var _loc4_:Array = Parse.parseIntToArray(param1.rs,ParkourConfig.AllDailyTask);
         var _loc5_:Array = [];
         var _loc6_:int = 0;
         while(_loc6_ < _loc2_.length)
         {
            _loc7_ = int(_loc2_[_loc6_]);
            _loc8_ = ParkourDailyTaskConfig.getTaskInfo(_loc7_);
            _loc9_ = new ParkourDailyTaskData(_loc8_);
            _loc9_.progress = _loc3_[_loc7_];
            _loc9_.hadGet = _loc4_[_loc7_];
            _loc5_.push(_loc9_);
            _loc6_++;
         }
         return _loc5_;
      }
      
      override protected function onClickTarget(param1:String) : void
      {
      }
      
      override protected function onDispose() : void
      {
         this.scrollComponent.dispose();
      }
   }
}

