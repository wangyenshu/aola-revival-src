package mmo.fbteam.fbaixi.sceneplayer.scene6
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.FbWildPetManager;
   import mmo.interfaces.fb.FbEvent;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi6_2OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var door:MovieClip;
      
      private var move:MovieClip;
      
      public function FBAixi6_2OpenDoor()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.init();
      }
      
      private function init() : void
      {
         var _loc1_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.container;
         this.door = _loc1_.getChildByName("guang1") as MovieClip;
         TipsManager.getInstance().addTips(this.door,"要打败所有怪物才能打开通道哦!");
         this.move = this.getObstruction().getChildByName("move1") as MovieClip;
         FbWildPetManager.instance.generateCurrentScenePets();
         FbWildPetManager.instance.addEventListener(FbEvent.ON_KILL_ALL_MONSTER,this.onKilledAllMonster);
      }
      
      private function onKilledAllMonster(param1:FbEvent) : void
      {
         var evt:FbEvent = param1;
         this.door.addFrameScript(this.door.totalFrames - 1,function():void
         {
            TipsManager.getInstance().removeTips(door);
            DisplayUtil.stopAndRemove(door);
            DisplayUtil.stopAndRemove(move);
            SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
         });
         this.door.gotoAndPlay(2);
      }
      
      public function dispose() : void
      {
         FbWildPetManager.instance.removeEventListener(FbEvent.ON_KILL_ALL_MONSTER,this.onKilledAllMonster);
      }
   }
}

