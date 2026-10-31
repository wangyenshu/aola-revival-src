package mmo.fbteam.fbsuolide.sceneplayer.scene04
{
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide4_2FightAnubis extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene4TempTypes.FBSuolide4_2FightAnubis};
      
      private var sysData2:Object = {"what":FBSuolide_Scene4TempTypes.FBSuolide4_2FightAnubis_1};
      
      private var anubis:SimpleButton = null;
      
      public function FBSuolide4_2FightAnubis()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.initCurStep,this.sysData,"fb_suolide4_talk_1_end");
         this.setNotify(finishStep,this.sysData2);
      }
      
      private function initCurStep() : void
      {
         this.getPars();
         if(TeamHelper.isCaptain())
         {
            this.fightWithAnubis();
         }
      }
      
      private function getPars() : void
      {
         this.anubis = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("anubis") as SimpleButton;
         this.anubis.addEventListener(MouseEvent.CLICK,this.onclick);
      }
      
      private function fightWithAnubis() : void
      {
         this.isClicking = true;
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         _loc1_.fightInCopy(1);
      }
      
      private function removeFightListener() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         this.isClicking = false;
      }
      
      private function onEnterFail(param1:PetFightEvent) : void
      {
         this.removeFightListener();
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         this.removeFightListener();
         if(param1.isWin)
         {
            this.notify(this.sysData2);
         }
      }
      
      private function onclick(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         param1.stopImmediatePropagation();
         this.fightWithAnubis();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

