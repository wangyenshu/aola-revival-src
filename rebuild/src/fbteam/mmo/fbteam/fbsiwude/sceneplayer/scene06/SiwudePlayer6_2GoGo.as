package mmo.fbteam.fbsiwude.sceneplayer.scene06
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   import mmo.play.scene.SceneManager;
   
   public class SiwudePlayer6_2GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var GoGo:MovieClip;
      
      private var door:SimpleButton;
      
      public function SiwudePlayer6_2GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.playGoGoMovie();
      }
      
      private function playGoGoMovie() : void
      {
         this.door = this.sceneInfo.scene.backGround.getChildByName("fbsiwude6_door") as SimpleButton;
         this.door.visible = true;
         var _loc1_:Sprite = ArrowHelper.getArrowhead(0);
         _loc1_.x = 320;
         _loc1_.y = 150;
         this.sceneInfo.scene.container.addChild(_loc1_);
         this.door.addEventListener(MouseEvent.CLICK,this.onClickFb6);
      }
      
      private function onClickFb6(param1:MouseEvent) : void
      {
         this.loadScene();
      }
      
      private function loadScene() : void
      {
         var _loc1_:String = TeamHelper.getTeamKey();
         SceneManager.getInstance().loadFB("fbsiwude9","fbsiwude","蚁神巨像",_loc1_);
      }
      
      public function dispose() : void
      {
         this.door.removeEventListener(MouseEvent.CLICK,this.onClickFb6);
      }
   }
}

