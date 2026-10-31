package mmo.fbservice.fbsuolide.fbsceneplayer.scene1
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer1_3CallEnemy extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var besiege:MovieClip = null;
      
      private var monsterArray:Array = null;
      
      public function SuolidePlayer1_3CallEnemy()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playBesiegeMovie();
      }
      
      private function playBesiegeMovie() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Besiege") as Class;
         this.besiege = new _loc1_();
         this.addModalDialogMovieToScene(this.besiege,this.besiegeFinished);
      }
      
      private function besiegeFinished() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.besiege);
         this.initMonster();
      }
      
      private function initMonster() : void
      {
         var _loc4_:MovieClip = null;
         this.monsterArray = new Array();
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Monster1") as Class;
         var _loc2_:* = new _loc1_() as MovieClip;
         _loc2_.x = 305;
         _loc2_.y = 391;
         this.monsterArray.push(_loc2_);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Monster2") as Class;
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 238;
         _loc2_.y = 440;
         this.monsterArray.push(_loc2_);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Monster3") as Class;
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 372;
         _loc2_.y = 503;
         this.monsterArray.push(_loc2_);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Monster4") as Class;
         _loc2_ = new _loc1_() as MovieClip;
         _loc2_.x = 459;
         _loc2_.y = 440;
         this.monsterArray.push(_loc2_);
         var _loc3_:int = 0;
         while(_loc3_ < this.monsterArray.length)
         {
            _loc4_ = this.monsterArray[_loc3_] as MovieClip;
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc4_);
            _loc4_.addEventListener(MouseEvent.CLICK,this.onMonsterClick);
            _loc4_.buttonMode = true;
            _loc3_++;
         }
      }
      
      private function onMonsterClick(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(1);
      }
      
      private function onEnterFail(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         if(param1.isWin)
         {
            this.removeMonster();
            this.removeObstruction();
            this.movieFinish(-1,this.type);
         }
      }
      
      private function removeMonster() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.monsterArray.length)
         {
            _loc2_ = this.monsterArray[_loc1_] as MovieClip;
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(_loc2_);
            _loc2_.removeEventListener(MouseEvent.CLICK,this.onMonsterClick);
            _loc1_++;
         }
      }
      
      private function removeObstruction() : void
      {
         var _loc1_:Sprite = this.getObstruction();
         var _loc2_:MovieClip = _loc1_.getChildByName("circle") as MovieClip;
         _loc1_.removeChild(_loc2_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
      }
   }
}

