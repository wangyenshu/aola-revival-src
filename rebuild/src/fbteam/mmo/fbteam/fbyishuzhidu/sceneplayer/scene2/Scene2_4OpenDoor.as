package mmo.fbteam.fbyishuzhidu.sceneplayer.scene2
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   
   public class Scene2_4OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const chipsData:Object = {"what":Scene2TempTypes.door_open};
      
      private var tempBack:MovieClip;
      
      private var mcChips:MovieClip;
      
      private var panel:MovieClip;
      
      private var chipsCounter:uint;
      
      private var tempType:String;
      
      public function Scene2_4OpenDoor()
      {
         super();
         this.tempBack = this.sceneInfo.scene.backGround.getChildByName("tempback") as MovieClip;
         this.mcChips = this.tempBack.getChildByName("mcchips") as MovieClip;
         this.mcChips.buttonMode = true;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.tempType = param1;
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.mcChips.addEventListener(MouseEvent.CLICK,this.onClickChips);
         this.initIntroPanel();
      }
      
      private function onClickChips(param1:MouseEvent) : void
      {
         this.mcChips.mouseEnabled = false;
         this.mcChips.mouseChildren = false;
         this.mcChips.removeEventListener(MouseEvent.CLICK,this.onClickChips);
         FBTeamSynchronizedClient.notify(chipsData);
         var _loc2_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.foreGround.getChildByName("et2") as Sprite;
         _loc2_.mouseEnabled = true;
      }
      
      private function showOpenDoorMovie(param1:String, param2:uint) : void
      {
         var action:String = param1;
         var frame:uint = param2;
         this.mcChips.gotoAndPlay(action);
         FBTeamSynchronizedClient.finishBack(chipsData);
         this.mcChips.addFrameScript(frame,function():void
         {
            mcChips.stop();
            DisplayUtil.stopAndRemove(sceneInfo.scene.obStruction.getChildByName("doorblock"));
            sceneInfo.scene.setMapArray();
         });
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && param1.what == Scene2TempTypes.door_open + "")
         {
            this.showOpenDoorMovie("opendoor",this.mcChips.totalFrames - 1);
         }
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && param1.what == Scene2TempTypes.door_open + "")
         {
            this.commFinish();
         }
      }
      
      private function commFinish() : void
      {
         ++this.chipsCounter;
         if(TeamHelper.checkCount(this.chipsCounter))
         {
            this.movieFinish(-1,this.tempType);
         }
      }
      
      private function initIntroPanel() : void
      {
         var _loc2_:Sprite = null;
         var _loc1_:uint = 1;
         while(_loc1_ <= 3)
         {
            _loc2_ = this.tempBack.getChildByName("panel_" + _loc1_) as Sprite;
            _loc2_.buttonMode = true;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClickPanel);
            _loc1_++;
         }
      }
      
      private function onClickPanel(param1:MouseEvent) : void
      {
         var cls:Class = null;
         var evt:MouseEvent = param1;
         var index:uint = parseInt((evt.target.name as String).split("_")[1]);
         if(null == this.panel)
         {
            cls = FBConfig.instence.getClass("mmo.scene.fbyishuzhidu.IntroPanel") as Class;
            this.panel = new cls() as MovieClip;
         }
         this.panel.gotoAndStop(index);
         ModalDialogManager.getInstance().addModalDialog(this.panel);
         this.panel.getChildByName("btnclose").addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
         {
            ModalDialogManager.getInstance().removeModalDialog(panel);
         });
      }
      
      public function dispose() : void
      {
         if(null != this.mcChips)
         {
            this.mcChips.removeEventListener(MouseEvent.CLICK,this.onClickChips);
         }
         this.chipsCounter = 0;
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
      }
   }
}

