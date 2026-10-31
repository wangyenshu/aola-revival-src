package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.AlignType;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.sceneplayer.ScenePetAvatar;
   import mmo.play.scene.SceneManager;
   
   public class SuolideScenePlayer6 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide6";
      
      private var soilMonsters:Array;
      
      private var woodMonsters:Array;
      
      private var monsters:Array;
      
      private var notHelpWoodTimes:int = 0;
      
      private var notHelpSoilTimes:int = 0;
      
      private var flag:int = 0;
      
      private var flash:MovieClip;
      
      private var fightFlag:Boolean = false;
      
      public function SuolideScenePlayer6()
      {
         super();
         var _loc1_:IFbService = ServiceContainer.instance.getService(IFbService) as IFbService;
         var _loc2_:DisplayObject = _loc1_.addFollower(29999);
      }
      
      override public function init() : void
      {
         super.init();
         this.soilMonsters = new Array();
         this.woodMonsters = new Array();
      }
      
      override public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
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
            case FbSuolideCommandConst.FB6_FBSUOLIDE6_NOTHELPWOODFIVETIMES:
            case FbSuolideCommandConst.FB6_FBSUOLIDE6_NOTHELPSOILFIVETIMES:
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
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide6.SoilMonster") as Class;
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
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide6.WoodMonster") as Class;
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
      
      private function onWoodMonsterClick(param1:MouseEvent) : void
      {
         this.movieFinish(1,"fbsuolide6_clickSoil");
      }
      
      private function onSoilMonsterClick(param1:MouseEvent) : void
      {
         this.movieFinish(2,"fbsuolide6_clickWood");
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
            if(param1.params.raceId != 30060)
            {
               return;
            }
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightWoodEnd);
            this.movieFinish(8,"fbsuolide6_fightWithWoodWin");
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
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.monsters[_loc1_]);
            _loc1_++;
         }
      }
      
      private function onFightSoilEnd(param1:PetFightEvent) : void
      {
         if(param1.isWin)
         {
            if(param1.params.raceId != 30072)
            {
               return;
            }
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightSoilEnd);
            this.movieFinish(7,"fbsuolide6_fightWithSoilWin");
            this.flag = 0;
         }
      }
      
      private function notHelpWood() : void
      {
         if(++this.notHelpWoodTimes > 4)
         {
            this.movieFinish(9,"fbsuolide6_notHelpWoodFiveTimes");
         }
      }
      
      private function notHelpSoil() : void
      {
         if(++this.notHelpSoilTimes > 4)
         {
            this.movieFinish(10,"fbsuolide6_notHelpSoilFiveTimes");
         }
      }
      
      private function initFlashMovie() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide6.Flash") as Class;
         this.flash = new _loc1_();
         this.flash.scaleX = 0.2;
         this.flash.scaleY = 0.2;
         var _loc2_:int = this.flash.totalFrames;
         this.flash.addFrameScript(_loc2_ - 1,this.flashScript);
      }
      
      private function flashScript() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.flash);
         this.flash = null;
      }
      
      private function exitAppear() : void
      {
         var _loc1_:int = 0;
         var _loc3_:MovieClip = null;
         var _loc4_:MovieClip = null;
         this.removeMonsters();
         this.initFlashMovie();
         if(this.flag)
         {
            this.removeObstruction("maskByXiong2");
            _loc3_ = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door7") as MovieClip;
            _loc3_.visible = true;
            this.flag = 0;
            ModalDialogManager.getInstance().addModalDialog(this.flash,AlignType.NONE,PanelEffect.NONE,true,450,110);
            this.flash.gotoAndPlay(1);
         }
         else
         {
            this.removeObstruction("maskByXiong1");
            _loc4_ = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door8") as MovieClip;
            _loc4_.visible = true;
            ModalDialogManager.getInstance().addModalDialog(this.flash,AlignType.NONE,PanelEffect.NONE,true,22,188);
            this.flash.gotoAndPlay(1);
         }
         _loc1_ = 0;
         while(_loc1_ < 3)
         {
            this.soilMonsters[_loc1_].removeEventListener(MouseEvent.CLICK,this.onSoilMonsterClick);
            this.woodMonsters[_loc1_].removeEventListener(MouseEvent.CLICK,this.onWoodMonsterClick);
            _loc1_++;
         }
         var _loc2_:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         if(Boolean(_loc2_.isUserTaskDoing(567)) && Boolean(_loc2_.isUserTaskDoing(574)))
         {
            TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":574}));
         }
      }
      
      private function removeObstruction(param1:String) : void
      {
         var _loc2_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.getChildByName("obstruction") as MovieClip;
         var _loc3_:MovieClip = _loc2_.getChildByName(param1) as MovieClip;
         _loc2_.removeChild(_loc3_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
      }
      
      override public function dispose() : void
      {
         this.isClicking = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightSoilEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightWoodEnd);
         var _loc1_:* = 0;
         while(_loc1_ < 3)
         {
            this.soilMonsters[_loc1_].removeEventListener(MouseEvent.CLICK,this.onSoilMonsterClick);
            this.woodMonsters[_loc1_].removeEventListener(MouseEvent.CLICK,this.onWoodMonsterClick);
            _loc1_++;
         }
      }
   }
}

