package mmo.fbteam.fbaixi.sceneplayer.scene3
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.FbWildPetManager;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi3_1OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var door1Pets:Array = [10421,10415,120421,120415];
      
      private var killCount:int = 0;
      
      private var doors:Array = [];
      
      private var doorsAreas:Array = [];
      
      private var et1:MovieClip = null;
      
      public function FBAixi3_1OpenDoor()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:Sprite = null;
         this.type = param1;
         this.initEt();
         var _loc4_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.container;
         var _loc5_:int = 0;
         while(_loc5_ < 2)
         {
            _loc6_ = _loc4_.getChildByName("guang" + _loc5_) as MovieClip;
            _loc7_ = this.getObstruction().getChildByName("move" + _loc5_) as Sprite;
            this.doors.push(_loc6_);
            this.doorsAreas.push(_loc7_);
            _loc5_++;
         }
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         FbWildPetManager.instance.addEventListener(FbEvent.ON_KILL_ALL_MONSTER,this.onAllMonsterKilled);
      }
      
      private function initEt() : void
      {
         var _loc1_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.foreGround;
         this.et1 = _loc1_.getChildByName("et1") as MovieClip;
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(Boolean(param1.isWin) && this.door1Pets.indexOf(param1.raceId) != -1)
         {
            ++this.killCount;
            if(3 == this.killCount)
            {
               CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
               this.tryRemoveDoor(this.doors[0],this.doorsAreas[0]);
            }
         }
      }
      
      private function onAllMonsterKilled(param1:FbEvent) : void
      {
         this.tryRemoveDoor(this.doors[1],this.doorsAreas[1]);
         this.addMapArrow();
      }
      
      private function tryRemoveDoor(param1:MovieClip, param2:Sprite) : void
      {
         var door:MovieClip = param1;
         var doorArea:Sprite = param2;
         door.addFrameScript(door.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(door);
            DisplayUtil.stopAndRemove(doorArea);
            SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
         });
         door.gotoAndPlay(2);
      }
      
      private function addMapArrow() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.FBAixi3_Arrow") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(_loc2_);
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         FbWildPetManager.instance.removeEventListener(FbEvent.ON_KILL_ALL_MONSTER,this.onAllMonsterKilled);
      }
   }
}

