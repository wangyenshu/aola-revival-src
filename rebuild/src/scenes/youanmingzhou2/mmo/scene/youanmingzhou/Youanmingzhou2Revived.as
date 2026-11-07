package mmo.scene.youanmingzhou
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.utils.getDefinitionByName;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.scenearrow.ISceneArrowService;
   import mmo.interfaces.thinktower.IThinkTower;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT scene/youanmingzhou2 (幽冥大殿): the code of the later copy (2016) on its art, with
    * its tower as it was in 2011–12: the 念之塔 (黑暗念之塔) is entered here, its seals chosen in
    * ThinkTowerService's panel (thinktower/enterpanel: 水之封印, 火之封印, 冰之封印, 雷之封印 and,
    * once the four are open, 念之大厅). The later copy sent its tower to a 念之大厅 of 2016 (an
    * empty room, thinktowerofnian); its own unused handler still opened the panel.
    */
   public class Youanmingzhou2Revived extends SceneBase
   {
      public var background:MovieClip;
      public var overlap:MovieClip;
      public var foreground:MovieClip;
      public var topground:MovieClip;
      public var obstruction:MovieClip;

      public function Youanmingzhou2Revived()
      {
         super(300, 450);
         this.addInitLocation("fromScene1To2", new Point(170, 370));
         this.addInitLocation("you3toYou2", new Point(400, 400));
         this.addInitLocation("fromThinkTowerOfNian", new Point(512, 139));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         TipsManager.getInstance().addTips(this.foreground.et1, "幽冥前殿");
         this.addEntrances(this.foreground.et1, "youanmingzhou1", "fromScene2To1", null, FaceDirectionTypes.FACELEFTDOWN);
         TipsManager.getInstance().addTips(this.background.etBtn, "选择之殿");
         SimpleButton(this.background.etBtn).addEventListener(MouseEvent.CLICK, this.changeScene);
         TipsManager.getInstance().addTips(this.overlap.btnThinkTower, "念之塔");
         SimpleButton(this.overlap.btnThinkTower).addEventListener(MouseEvent.CLICK, this.onClickTower);
      }

      private function changeScene(evt:MouseEvent):void
      {
         SimpleButton(this.background.etBtn).removeEventListener(MouseEvent.CLICK, this.changeScene);
         var mc:MovieClip;
         try { mc = new (getDefinitionByName("mmo.scene.youanmingzhou.ChangeSceneMovie") as Class)() as MovieClip; } catch (e:Error) {}
         if (mc == null)
         {
            SceneManager.getInstance().loadScene("choicetemple", "from2ToChoiceTemple", false, false, FaceDirectionTypes.FACELEFTDOWN);
            return;
         }
         mc.addFrameScript(mc.totalFrames - 1, function():void
         {
            mc.stop();
            ModalDialogManager.getInstance().removeModalDialog(mc);
            SceneManager.getInstance().loadScene("choicetemple", "from2ToChoiceTemple", false, false, FaceDirectionTypes.FACELEFTDOWN);
         });
         ModalDialogManager.getInstance().addModalDialog(mc, AlignType.NONE);
         mc.gotoAndPlay(1);
      }

      private function onClickTower(evt:MouseEvent):void
      {
         try { (ServiceContainer.getService(ISceneArrowService) as ISceneArrowService).removeArrow("youanmingzhou2_sb_20120823_darknian"); } catch (e:Error) {}
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService("ThinkTowerService", function(svc:IService, o:Object):void
         {
            ProgressFullSprite.close();
            try { IThinkTower(svc).showEnterPanel(); } catch (err:Error) { RLog.error("念之塔", err); }
         });
      }

      override protected function onLeaveRoom():void
      {
         super.onLeaveRoom();
         SimpleButton(this.background.etBtn).removeEventListener(MouseEvent.CLICK, this.changeScene);
         SimpleButton(this.overlap.btnThinkTower).removeEventListener(MouseEvent.CLICK, this.onClickTower);
      }
   }
}
