package mmo.fbservice.fbsuolide.fbsceneplayer.scene5
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   
   public class SuolidePlayer5_1Npc133Appear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var mc133appear:MovieClip = null;
      
      public function SuolidePlayer5_1Npc133Appear()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
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
               movieFinish(-1,this.type);
            });
         }
      }
      
      public function dispose() : void
      {
      }
   }
}

