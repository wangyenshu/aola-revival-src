package mmo.fbteam.fbyishuzhidu.sceneplayer.scene3
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class YishuzhiduPlayer3_1ClickGrass extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var count:int = 0;
      
      private var count1:int = 0;
      
      private var dinosaurFoot:MovieClip;
      
      private const stepAction:int = 4;
      
      private const stepEnd:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":this.stepAction
      };
      
      private var isClick:Boolean = false;
      
      public function YishuzhiduPlayer3_1ClickGrass()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.actionShow);
         (this.sceneInfo.scene.backGround.getChildByName("door") as MovieClip).visible = false;
         (this.sceneInfo.scene.foreGround.getChildByName("et2") as Sprite).y = (this.sceneInfo.scene.foreGround.getChildByName("et2") as Sprite).y + 500;
         this.dinosaurFoot = this.sceneInfo.scene.backGround.getChildByName("dinosaurFoot") as MovieClip;
         this.dinosaurFoot.buttonMode = true;
         this.dinosaurFoot.addEventListener(MouseEvent.CLICK,this.clickDinosaurFoot);
         this.dinosaurFoot.addFrameScript(50,this.frame51,100,this.frame101);
      }
      
      private function frame51() : void
      {
         this.dinosaurFoot.stop();
         this.isClick = false;
      }
      
      private function frame101() : void
      {
         this.dinosaurFoot.stop();
         this.movieFinish();
         TeamSynchronizedClient.notify(this.stepEnd);
         this.dinosaurFoot.removeEventListener(MouseEvent.CLICK,this.clickDinosaurFoot);
      }
      
      private function clickDinosaurFoot(param1:MouseEvent) : void
      {
         if(this.isClick)
         {
            return;
         }
         this.isClick = true;
         ++this.count;
         if(this.count == 1)
         {
            this.dinosaurFoot.gotoAndPlay(2);
         }
         else if(this.count == 2)
         {
            this.dinosaurFoot.gotoAndPlay(52);
         }
      }
      
      private function actionShow(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         var _loc5_:int = int(param1.params.obj.what);
         if(TeamHelper.getTeamKey() != _loc3_)
         {
            return;
         }
         if(_loc2_ == TeamSynchronizedClient.cmdNotify && _loc4_ == FBTeamCommonTypes.TYPE_END && _loc5_ == this.stepAction)
         {
            this.movieFinish();
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.actionShow);
         if(this.dinosaurFoot != null)
         {
            this.dinosaurFoot.removeEventListener(MouseEvent.CLICK,this.clickDinosaurFoot);
         }
      }
   }
}

