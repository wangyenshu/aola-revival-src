package mmo.fbteam.fbsuolide.sceneplayer.scene05
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide5_1Npc133Appear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var mc133appear:MovieClip = null;
      
      public function FBSuolide5_1Npc133Appear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.npc133Appear();
      }
      
      private function npc133Appear() : void
      {
         this.mc133appear = this.sceneInfo.scene.container.getChildByName("mc_133appear") as MovieClip;
         this.addMc133FrameScript();
         this.mc133appear.gotoAndPlay(1);
      }
      
      private function addMc133FrameScript() : void
      {
         if(null != this.mc133appear)
         {
            this.mc133appear.addFrameScript(77 - 1,function():void
            {
               mc133appear.stop();
               finishStep();
            });
         }
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

