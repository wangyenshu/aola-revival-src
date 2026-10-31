package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import mmo.fbteam.common.ScreenLock;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide8_2AndroidAppear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene8TempTypes.FBSuolide8_2AndroidAppear};
      
      private var sysData2:Object = {"what":FBSuolide_Scene8TempTypes.FBSuolide8_2AndroidAppear + "1"};
      
      private var Mummy_appaer:MovieClip = null;
      
      private var Android_appear:MovieClip = null;
      
      private var Coffin_open:MovieClip = null;
      
      private var p1:MovieClip = null;
      
      private var p2:MovieClip = null;
      
      private var mummy_machine:MovieClip = null;
      
      private var petid:int = 1;
      
      public function FBSuolide8_2AndroidAppear()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setNotify(this.afterWin,this.sysData2);
         this.setSycFunWithKeyAndAction(this.playAndroidAppear,this.sysData,"fb_suolide8_talk_2_end");
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
         if(TeamHelper.isCaptain())
         {
            ScreenLock.lock();
         }
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_android_appear") as Class;
         this.Android_appear = new _loc1_() as MovieClip;
         this.Android_appear.addFrameScript(this.Android_appear.totalFrames - 1,this.Android_appear_end);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.Android_appear);
         this.Android_appear.gotoAndPlay(1);
      }
      
      private function Android_appear_end() : void
      {
         if(TeamHelper.isCaptain())
         {
            ScreenLock.unlock();
         }
         DisplayUtil.stopAndRemove(this.Android_appear);
         var _loc1_:Class = null;
         _loc1_ = SceneManager.getInstance().loadedSceneInfo.applicationDomain.getDefinition("mmo.scene.fbsuolide.Fbsuolide8_coffin_open") as Class;
         this.Coffin_open = new _loc1_() as MovieClip;
         this.Coffin_open.x = 493.5;
         this.Coffin_open.y = 488.85;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.Coffin_open);
         _loc1_ = SceneManager.getInstance().loadedSceneInfo.applicationDomain.getDefinition("mmo.scene.fbsuolide.Fbsuolide8_p1") as Class;
         this.p1 = new _loc1_() as MovieClip;
         this.p1.name = "fb8_p1";
         this.p1.x = 641.5;
         this.p1.y = 272.65;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.p1);
         _loc1_ = SceneManager.getInstance().loadedSceneInfo.applicationDomain.getDefinition("mmo.scene.fbsuolide.Fbsuolide8_p2") as Class;
         this.p2 = new _loc1_() as MovieClip;
         this.p2.name = "fb8_p2";
         this.p2.x = 410.25;
         this.p2.y = 333.75;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.p2);
         _loc1_ = SceneManager.getInstance().loadedSceneInfo.applicationDomain.getDefinition("mmo.scene.fbsuolide.Fbsuolide8_falao") as Class;
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
         if(!(!param1.isWin && !param1.isEscape))
         {
            if(param1.isWin)
            {
               this.mummy_machine.removeEventListener(MouseEvent.CLICK,this.fightWithMummy);
               this.notify(this.sysData2);
            }
         }
      }
      
      private function afterWin() : void
      {
         this.finishStep();
      }
      
      private function removeFightListener() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         this.isClicking = false;
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

