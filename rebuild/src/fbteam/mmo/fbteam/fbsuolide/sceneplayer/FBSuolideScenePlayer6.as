package mmo.fbteam.fbsuolide.sceneplayer
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene06.FBSuolide_Scene6TempTypes;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.sceneplayer.ScenePetAvatar;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolideScenePlayer6 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide6";
      
      private var what:String = "6";
      
      private var sysData:Object = {"what":FBSuolide_Scene6TempTypes.fb6_suolide_init_scene};
      
      private var soilMonsters:Array;
      
      private var woodMonsters:Array;
      
      private var monsters:Array;
      
      private var notHelpWoodTimes:int = 0;
      
      private var notHelpSoilTimes:int = 0;
      
      private var flag:int = 0;
      
      private var flash:MovieClip;
      
      private var fightFlag:Boolean = false;
      
      private var funs:Array = [];
      
      private var _tasknpcS:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      
      public function FBSuolideScenePlayer6()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.soilMonsters = new Array();
         this.woodMonsters = new Array();
         this.funs = [this.initfightWithWood,this.initfightWithSoil];
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && param1.what == this.what)
         {
            if(param1.data.info == "#")
            {
               this.funs[param1.data.step].apply();
            }
            else
            {
               this.currentMovieFinish(param1.data.step,param1.data.info);
            }
         }
      }
      
      private function onAction(param1:TaskEvent) : void
      {
         switch(param1.params.action)
         {
            case "fbsuolide6_clickSoil_ok":
               this.notify(0,"#");
               break;
            case "fbsuolide6_clickWood_ok":
               this.notify(1,"#");
               break;
            case "fbsuolide6_fightWithSoilWin_":
            case "fbsuolide6_fightWithWoodWin_":
               this.notify(7,"fb6_suolide_exit_appear");
         }
      }
      
      override public function updataInfo(param1:String, param2:Function = null, param3:Object = null) : void
      {
         switch(param1)
         {
            case FbSuolideCommandConst.FB6_SUOLIDE_INIT_SCENE:
               this.initScene();
               break;
            case FbSuolideCommandConst.FB6_SUOLIDE_WOODENPET_TO_ENEMY:
               this.initfightWithWood();
               break;
            case FbSuolideCommandConst.FB6_SUOLIDE_SOILPET_TO_ENEMY:
               this.initfightWithSoil();
               break;
            case FbSuolideCommandConst.FB6_SUOLIDE_EXIT_APPEAR:
               this.exitAppear();
         }
      }
      
      private function initScene() : void
      {
         this.addMonsterToScene();
         this.hideFBEntrances();
      }
      
      private function addMonsterToScene() : void
      {
         this.monsters = new Array();
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide6.SoilMonster") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         _loc2_.x = 750;
         _loc2_.y = 200;
         this.soilMonsters.push(_loc2_);
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 750;
         _loc2_.y = 300;
         this.soilMonsters.push(_loc2_);
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 750;
         _loc2_.y = 400;
         this.soilMonsters.push(_loc2_);
         _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsuolide6.WoodMonster") as Class;
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 150;
         _loc2_.y = 200;
         this.woodMonsters.push(_loc2_);
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 150;
         _loc2_.y = 300;
         this.woodMonsters.push(_loc2_);
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 150;
         _loc2_.y = 400;
         this.woodMonsters.push(_loc2_);
         var _loc3_:* = 0;
         while(_loc3_ < 3)
         {
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.soilMonsters[_loc3_]);
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.woodMonsters[_loc3_]);
            this.soilMonsters[_loc3_].addEventListener(MouseEvent.CLICK,this.onSoilMonsterClick);
            this.woodMonsters[_loc3_].addEventListener(MouseEvent.CLICK,this.onWoodMonsterClick);
            _loc3_++;
         }
      }
      
      private function hideFBEntrances() : void
      {
         var _loc1_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door7") as MovieClip;
         _loc1_.visible = false;
         var _loc2_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door8") as MovieClip;
         _loc2_.visible = false;
      }
      
      private function notify(param1:int, param2:String) : void
      {
         FBTeamSynchronizedClient.notify({
            "step":param1,
            "info":param2,
            "what":this.what
         });
      }
      
      private function onWoodMonsterClick(param1:MouseEvent) : void
      {
         this.notify(1,"fbsuolide6_clickSoil");
      }
      
      private function onSoilMonsterClick(param1:MouseEvent) : void
      {
         this.notify(2,"fbsuolide6_clickWood");
      }
      
      private function initfightWithWood() : void
      {
         var _loc2_:ScenePetAvatar = null;
         if(this.fightFlag)
         {
            return;
         }
         var _loc1_:* = 0;
         while(_loc1_ < 3)
         {
            this.fightFlag = true;
            if(SceneManager.getInstance().loadedSceneInfo.scene.container.contains(this.woodMonsters[_loc1_]))
            {
               SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.woodMonsters[_loc1_]);
            }
            _loc2_ = new ScenePetAvatar(60,new Point(150,(2 + _loc1_) * 100),this.fightWithWood);
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc2_);
            _loc2_.x = 150;
            _loc2_.y = (2 + _loc1_) * 100;
            this.monsters.push(_loc2_);
            _loc1_++;
         }
      }
      
      private function fightWithWood(param1:MouseEvent) : void
      {
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(1);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightWoodEnd);
      }
      
      private function onFightWoodEnd(param1:PetFightEvent) : void
      {
         if(param1.isWin)
         {
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightWoodEnd);
            this._tasknpcS.showNpcPanelFreely("fbsuolide6_fightWithWoodWin",135);
            this.flag = 1;
         }
      }
      
      private function initfightWithSoil() : void
      {
         var _loc2_:ScenePetAvatar = null;
         if(this.fightFlag)
         {
            return;
         }
         var _loc1_:* = 0;
         while(_loc1_ < 3)
         {
            this.fightFlag = true;
            if(SceneManager.getInstance().loadedSceneInfo.scene.container.contains(this.soilMonsters[_loc1_]))
            {
               SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.soilMonsters[_loc1_]);
            }
            _loc2_ = new ScenePetAvatar(72,new Point(750,(2 + _loc1_) * 100),this.fightWithSoil);
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc2_);
            _loc2_.x = 750;
            _loc2_.y = (2 + _loc1_) * 100;
            this.monsters.push(_loc2_);
            _loc1_++;
         }
      }
      
      private function fightWithSoil(param1:MouseEvent) : void
      {
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(2);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightSoilEnd);
      }
      
      private function removeMonsters() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.monsters.length)
         {
            DisplayUtil.stopAndRemove(this.monsters[_loc1_]);
            _loc1_++;
         }
      }
      
      private function onFightSoilEnd(param1:PetFightEvent) : void
      {
         if(param1.isWin)
         {
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightSoilEnd);
            this._tasknpcS.showNpcPanelFreely("fbsuolide6_fightWithSoilWin",134);
            this.flag = 0;
         }
      }
      
      private function initFlashMovie() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide6.Flash") as Class;
         this.flash = new _loc1_();
         this.flash.scaleX = 0.2;
         this.flash.scaleY = 0.2;
         var _loc2_:int = this.flash.totalFrames;
         this.flash.addFrameScript(_loc2_ - 1,this.flashScript);
      }
      
      private function flashScript() : void
      {
         DisplayUtil.stopAndRemove(this.flash);
         this.flash = null;
      }
      
      private function exitAppear() : void
      {
         var _loc1_:int = 0;
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         this.removeMonsters();
         this.initFlashMovie();
         if(this.flag)
         {
            this.removeObstruction("maskByXiong2");
            _loc2_ = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door7") as MovieClip;
            _loc2_.visible = true;
            this.flag = 0;
            this.showFlash(450,110);
            this.flash.gotoAndPlay(1);
         }
         else
         {
            this.removeObstruction("maskByXiong1");
            _loc3_ = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door8") as MovieClip;
            _loc3_.visible = true;
            this.showFlash(22,188);
            this.flash.gotoAndPlay(1);
         }
      }
      
      private function showFlash(param1:int, param2:int) : void
      {
         this.flash.x = param1;
         this.flash.y = param2;
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.flash);
      }
      
      private function removeObstruction(param1:String) : void
      {
         var _loc2_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.getChildByName("obstruction") as MovieClip;
         var _loc3_:MovieClip = _loc2_.getChildByName(param1) as MovieClip;
         DisplayUtil.stopAndRemove(_loc3_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
      }
      
      override public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightSoilEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightWoodEnd);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
   }
}

