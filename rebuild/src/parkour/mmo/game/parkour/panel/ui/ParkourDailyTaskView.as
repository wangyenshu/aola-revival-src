package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.dailytask.ParkourDailyTaskData;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourDailyTaskView extends MovieClip
   {
      
      private var view:MovieClip;
      
      private var data:ParkourDailyTaskData;
      
      public function ParkourDailyTaskView()
      {
         super();
         this.view = ParkourResConfig.createView(ParkourResConfig.ClsNameOfDailyTaskView) as MovieClip;
         addChild(this.view);
         addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      public function showInfo(param1:ParkourDailyTaskData) : void
      {
         visible = param1 != null;
         if(param1 == null)
         {
            return;
         }
         this.data = param1;
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc1_:MovieClip = this.view.getChildByName("mcFinish") as MovieClip;
         var _loc2_:int = this.data.hadFinish ? 2 : 1;
         _loc1_.gotoAndStop(_loc2_);
         var _loc3_:MovieClip = this.view.getChildByName("mcGet") as MovieClip;
         var _loc4_:MovieClip = this.view.getChildByName("mcTaskDes") as MovieClip;
         var _loc5_:TextField = this.view.getChildByName("txtProgress") as TextField;
         var _loc6_:MovieClip = this.view.getChildByName("mcProgress") as MovieClip;
         if(!this.data.hadFinish)
         {
            ParkourHelper.grayMcButton(_loc3_,"你还没完成该任务哦!");
         }
         else
         {
            ParkourHelper.setMcButton(_loc3_,this.data.hadGet,"你已经领取过该任务的奖励了!");
         }
         _loc4_.gotoAndStop(this.data.info.id + 1);
         _loc5_.text = this.data.progress + "/" + this.data.info.maxProgress;
         var _loc7_:int = this.data.progress * _loc6_.totalFrames / this.data.info.maxProgress + 1;
         _loc6_.gotoAndStop(_loc7_);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnGet")
         {
            ProgressFullSprite.show();
            SocketClient.instance.addEventListener(ParkourClient.CmdGetDailyTaskReward,this.onCmdGetReward);
            ParkourClient.getDailyTaskReward(this.data.info.id);
         }
      }
      
      private function onCmdGetReward(param1:SocketClientEvent) : void
      {
         ParkourUserData.instance.onTaskDone();
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdGetDailyTaskReward,this.onCmdGetReward);
         var _loc2_:Array = param1.params.bn;
         var _loc3_:Array = param1.params.gBn;
         this.data.hadGet = true;
         this.refresh();
         ParkourHelper.showBnAndGBn(_loc2_,_loc3_);
      }
      
      public function dispose() : void
      {
         removeEventListener(MouseEvent.CLICK,this.onClick);
      }
   }
}

