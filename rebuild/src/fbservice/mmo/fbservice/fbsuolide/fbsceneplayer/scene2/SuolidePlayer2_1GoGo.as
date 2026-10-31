package mmo.fbservice.fbsuolide.fbsceneplayer.scene2
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   
   public class SuolidePlayer2_1GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      public function SuolidePlayer2_1GoGo()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.arrowheadChange(param1,param2,param3,param4);
      }
      
      private function arrowheadChange(param1:String, param2:Boolean, param3:Function, param4:Object) : void
      {
         var fire:MovieClip = null;
         var type:String = param1;
         var b:Boolean = param2;
         var callbck:Function = param3;
         var agrs:Object = param4;
         fire = this.sceneInfo.scene.backGround.getChildByName("mc_fire") as MovieClip;
         if(b)
         {
            fire.addFrameScript(fire.totalFrames - 1,function():void
            {
               fire.stop();
               movieFinish(-1,type);
            });
            fire.gotoAndPlay(2);
         }
         else
         {
            fire.gotoAndStop(1);
         }
      }
      
      public function dispose() : void
      {
      }
   }
}

