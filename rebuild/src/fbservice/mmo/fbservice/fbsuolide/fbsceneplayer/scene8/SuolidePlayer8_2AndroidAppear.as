package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer8_2AndroidAppear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var Mummy_appaer:MovieClip = null;
      
      private var Android_appear:MovieClip = null;
      
      private var Coffin_open:MovieClip = null;
      
      private var p1:MovieClip = null;
      
      private var p2:MovieClip = null;
      
      private var mummy_machine:MovieClip = null;
      
      private var petid:int = 1;
      
      public function SuolidePlayer8_2AndroidAppear()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playAndroidAppear();
      }
      
      private function getPars() : void
      {
         this.Mummy_appaer = this.sceneInfo.scene.foreGround.getChildByName("fbsuolide8_mummy_appaer") as MovieClip;
      }
      
      private function playAndroidAppear() : void
      {
         if(this.Mummy_appaer.parent != null)
         {
            this.Mummy_appaer.parent.removeChild(this.Mummy_appaer);
         }
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_android_appear") as Class;
         this.Android_appear = new _loc1_() as MovieClip;
         this.Android_appear.addFrameScript(this.Android_appear.totalFrames - 1,this.Android_appear_end);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.Android_appear);
         this.Android_appear.gotoAndPlay(1);
      }
      
      private function Android_appear_end() : void
      {
         Tool.instence.cleanTransparency();
         DisplayUtil.stopAndRemove(this.Android_appear);
         var _loc1_:Class = null;
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_coffin_open") as Class;
         this.Coffin_open = new _loc1_() as MovieClip;
         this.Coffin_open.x = 493.5;
         this.Coffin_open.y = 488.85;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.Coffin_open);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_p1") as Class;
         this.p1 = new _loc1_() as MovieClip;
         this.p1.name = "fb8_p1";
         this.p1.x = 641.5;
         this.p1.y = 272.65;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.p1);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_p2") as Class;
         this.p2 = new _loc1_() as MovieClip;
         this.p2.name = "fb8_p2";
         this.p2.x = 410.25;
         this.p2.y = 333.75;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.p2);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_falao") as Class;
         this.mummy_machine = new _loc1_() as MovieClip;
         this.mummy_machine.name = "fb8_mummy_machine";
         this.mummy_machine.x = 495.2;
         this.mummy_machine.y = 273.55;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.mummy_machine);
         this.mummy_machine.addEventListener(MouseEvent.CLICK,this.fightWithMummy);
      }
      
      private function fightWithMummy(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         param1.stopImmediatePropagation();
         this.isClicking = true;
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         _loc2_.fightInCopy(this.petid);
      }
      
      private function onFightFail(param1:PetFightEvent) : void
      {
         this.removeFightListener();
      }
      
      private function fightEnd(param1:PetFightEvent) : void
      {
         this.removeFightListener();
         if(param1.id != this.petid)
         {
            return;
         }
         if(!(!param1.isWin && !param1.isEscape))
         {
            if(param1.isWin)
            {
               this.mummy_machine.removeEventListener(MouseEvent.CLICK,this.fightWithMummy);
               this.movieFinish(-1,this.type);
            }
         }
      }
      
      private function removeFightListener() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         this.isClicking = false;
      }
      
      public function dispose() : void
      {
         this.removeFightListener();
      }
   }
}

