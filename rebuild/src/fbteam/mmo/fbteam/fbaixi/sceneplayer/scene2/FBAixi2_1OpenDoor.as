package mmo.fbteam.fbaixi.sceneplayer.scene2
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.FbWildPetManager;
   import mmo.interfaces.fb.FbEvent;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi2_1OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var wholeDoors:Array = [];
      
      private var doors:Array = [];
      
      private var doorsAreas:Array = [];
      
      private var doorCount:int = 0;
      
      private var et2:MovieClip = null;
      
      private var et3:MovieClip = null;
      
      public function FBAixi2_1OpenDoor()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.initEt();
         FbWildPetManager.instance.generateCurrentScenePets();
         FbWildPetManager.instance.addEventListener(FbEvent.ON_KILL_ALL_MONSTER,this.onAllMonsterKilled);
      }
      
      private function initEt() : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:Sprite = null;
         var _loc6_:MovieClip = null;
         var _loc1_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.foreGround;
         this.et2 = _loc1_.getChildByName("et2") as MovieClip;
         this.et3 = _loc1_.getChildByName("et3") as MovieClip;
         var _loc2_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.container;
         var _loc3_:int = 0;
         while(_loc3_ < 2)
         {
            _loc4_ = _loc2_.getChildByName("door" + _loc3_) as MovieClip;
            _loc4_.mouseChildren = false;
            this.wholeDoors.push(_loc4_);
            _loc5_ = this.getObstruction().getChildByName("move" + _loc3_) as Sprite;
            this.doorsAreas.push(_loc5_);
            _loc6_ = _loc4_.getChildByName("guang") as MovieClip;
            this.doors.push(_loc6_);
            _loc3_++;
         }
         this.addEtTips();
      }
      
      private function setTips(param1:Array, param2:Boolean = false) : void
      {
         var _loc3_:InteractiveObject = null;
         for each(_loc3_ in param1)
         {
            if(null != _loc3_)
            {
               if(param2)
               {
                  TipsManager.getInstance().removeTips(_loc3_);
               }
               else
               {
                  TipsManager.getInstance().removeTips(_loc3_);
                  TipsManager.getInstance().addTips(_loc3_,"需要先打败埃黑多夫和冰沙斗士才能打开通道哦!");
               }
            }
         }
      }
      
      private function addEtTips() : void
      {
         this.setTips([this.et2,this.et3],false);
         this.setTips(this.wholeDoors,false);
      }
      
      private function removeEtTips() : void
      {
         this.setTips([this.et2,this.et3],true);
         this.setTips(this.wholeDoors,true);
      }
      
      private function onAllMonsterKilled(param1:FbEvent) : void
      {
         var _loc2_:MovieClip = null;
         for each(_loc2_ in this.doors)
         {
            this.tryRemoveDoor(_loc2_);
         }
      }
      
      private function tryRemoveDoor(param1:MovieClip) : void
      {
         var door:MovieClip = param1;
         door.addFrameScript(door.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(door);
            ++doorCount;
            tryRemoveDoorAreas();
         });
         door.gotoAndPlay(2);
      }
      
      private function tryRemoveDoorAreas() : void
      {
         var _loc1_:Sprite = null;
         if(2 == this.doorCount)
         {
            for each(_loc1_ in this.doorsAreas)
            {
               DisplayUtil.stopAndRemove(_loc1_);
               this.removeEtTips();
            }
            SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
         }
      }
      
      public function dispose() : void
      {
         this.removeEtTips();
         FbWildPetManager.instance.removeEventListener(FbEvent.ON_KILL_ALL_MONSTER,this.onAllMonsterKilled);
      }
   }
}

