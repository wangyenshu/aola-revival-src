package mmo.fbteam.fbaixi.sceneplayer.scene7
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.*;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.IShowPanel;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi7_1Game extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const gameWindData:Object = {"what":FBAixi_Scene7TempTypes.FBAIXI7_1GAME};
      
      private var btnGameEntrance:SimpleButton = null;
      
      private var mcDoor:MovieClip = null;
      
      public function FBAixi7_1Game()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnGameEntrance = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("gamebtn") as SimpleButton;
         this.mcDoor = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door") as MovieClip;
         this.btnGameEntrance.addEventListener(MouseEvent.CLICK,this.onClickGameEntrance);
         TipsManager.getInstance().addTips(this.mcDoor,"先解开地上的机关才能打开大门！");
         CommonEventDispatcher.instance.addEventListener("SISESUCCEED",this.gameWin);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      private function onClickGameEntrance(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.showGame();
      }
      
      private function showGame() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.Fbaixi7_Game") as Class;
         var _loc2_:IShowPanel = new _loc1_() as IShowPanel;
         _loc2_.showPanel();
      }
      
      private function gameWin(param1:CommonEvent) : void
      {
         if(param1.params.isWin)
         {
            FBTeamSynchronizedClient.notify(this.gameWindData);
         }
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBAixi_Scene7TempTypes.FBAIXI7_1GAME == param1.what)
         {
            this.passGame();
         }
      }
      
      private function passGame() : void
      {
         this.btnGameEntrance.mouseEnabled = false;
         this.movieFinish();
      }
      
      private function disposeEvents() : void
      {
         TipsManager.getInstance().removeTips(this.mcDoor);
         this.btnGameEntrance.removeEventListener(MouseEvent.CLICK,this.onClickGameEntrance);
         CommonEventDispatcher.instance.removeEventListener("SISESUCCEED",this.gameWin);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      public function dispose() : void
      {
         this.disposeEvents();
      }
   }
}

