package mmo.fbteam.auto
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   
   public class ScenePlayerStepBase
   {
      
      protected var isClicking:Boolean = false;
      
      protected var sceneInfo:SceneInfo = null;
      
      protected var type:String = "";
      
      public function ScenePlayerStepBase()
      {
         super();
         this.sceneInfo = SceneManager.getInstance().loadedSceneInfo;
      }
      
      protected function getObstruction() : Sprite
      {
         return Sprite(this.sceneInfo.scene.getChildByName("obstruction"));
      }
      
      final protected function finishStep() : void
      {
         this.movieFinish(-1,this.type);
      }
      
      protected function movieFinish(param1:int = -1, param2:String = null) : void
      {
         if(null != param2)
         {
            this.type = param2;
         }
         FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,{
            "next":param1,
            "movieName":this.type
         }));
      }
      
      protected function addModalDialogMovieToScene(param1:MovieClip, param2:Function, param3:int = 0, param4:int = 0, param5:Boolean = false) : void
      {
         ModalDialogManager.getInstance().addModalDialog(param1,AlignType.NONE,PanelEffect.NONE,true,param3,param4);
         param1.parent.name = "modalDialogContainer";
         var _loc6_:int = param1.totalFrames;
         param1.addFrameScript(_loc6_ - 1,param2);
         param1.gotoAndPlay(1);
      }
      
      protected function addMovieToScene(param1:MovieClip, param2:Function, param3:int = 0, param4:int = 0) : void
      {
         param1.x = param3;
         param1.y = param4;
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(param1);
         var _loc5_:int = param1.totalFrames;
         param1.addFrameScript(_loc5_ - 1,param2);
         param1.gotoAndPlay(1);
      }
      
      protected function removeModalDialogMovieByName(param1:String) : void
      {
         var _loc2_:Sprite = LayerManager.getBaseTop().getChildByName("modalDialogContainer") as Sprite;
         var _loc3_:DisplayObject = _loc2_.getChildByName(param1) as MovieClip;
         if(_loc3_ != null)
         {
            ModalDialogManager.getInstance().removeModalDialog(_loc3_);
         }
      }
      
      protected function removeChildByName(param1:String) : void
      {
         var _loc2_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.foreGround;
         var _loc3_:DisplayObject = _loc2_.getChildByName(param1);
         DisplayUtil.stopAndRemove(_loc3_);
      }
      
      protected function showAllChild(param1:DisplayObjectContainer, param2:String) : void
      {
         var _loc4_:DisplayObject = null;
         var _loc5_:DisplayObjectContainer = null;
         var _loc3_:int = 0;
         while(_loc3_ < param1.numChildren)
         {
            _loc4_ = param1.getChildAt(_loc3_) as DisplayObject;
            if(_loc4_ is DisplayObjectContainer)
            {
               _loc5_ = _loc4_ as DisplayObjectContainer;
               this.showAllChild(_loc5_,param2);
            }
            if(param2 == _loc4_.name)
            {
            }
            _loc3_++;
         }
      }
   }
}

