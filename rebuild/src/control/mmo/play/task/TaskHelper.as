package mmo.play.task
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;

   /**
    * REBUILT from the later mmo.play.task.TaskHelper (live play.swf) on the
    * January 2013 libraries: the movies ("play"), comics ("show") and
    * interaction panels ("enter") of a quest run by NewBaseTaskInitialler,
    * scene changes and fights. The movie and comic controls are those of the
    * later common's PlayMovieHelper and ShowCartoonHelper (next / previous /
    * close buttons by name; a movie ends on its last frame), loaded with the
    * 2013 SimpleCustomLoader.loadSingleResource.
    */
   public class TaskHelper
   {
      private var _fileRes:Object;

      public function TaskHelper()
      {
         super();
      }

      public function setFileRes(fileRes:Object):void
      {
         this._fileRes = fileRes;
      }

      public function showTaskFinishPanel():void
      {
         if (_fileRes == null || !_fileRes.hasOwnProperty("taskFinishPanel")) return;
         SimpleCustomLoader.loadSingleResource(_fileRes["taskFinishPanel"]["swf"], _fileRes["taskFinishPanel"]["cls"], LoadingSpriteType.DIALOG, "加载中，请稍候……",
            function(p:Object):void
            {
               if (p is IShowPanel) IShowPanel(p).showPanel();
            });
      }

      public function getResAndPlay(type:String, fileKey:String, taskid:int, callback:Function = null):void
      {
         var res:Object = _fileRes ? _fileRes[fileKey] : null;
         if (res == null)
         {
            done(callback);
            return;
         }
         var url:String = res["swf"];
         var cls:String = res["cls"];
         if (Boolean(res["isShowDataPanel"]))
         {
            Panel_Helper.loadResAndShow(url, cls, {callback: callback, ti: taskid});
            return;
         }
         switch (type)
         {
            case "play":
               hidePlayer(true);
               SimpleCustomLoader.loadSingleResource(url, cls, LoadingSpriteType.NONE, "加载中，请稍候……", function(p:Object):void
               {
                  playMovie(p as MovieClip, function():void
                  {
                     hidePlayer(false);
                     done(callback);
                  });
               });
               break;
            case "show":
               SimpleCustomLoader.loadSingleResource(url, cls, LoadingSpriteType.DIALOG, "加载中，请稍候……", function(p:Object):void
               {
                  showCartoon(p as MovieClip, callback);
               });
               break;
            case "enter":
               SimpleCustomLoader.loadSingleResource(url, cls, LoadingSpriteType.DIALOG, "加载中，请稍候……", function(p:Object):void
               {
                  if (p is IShowDataPanel) IShowDataPanel(p).showPanelByData({callback: callback, taskid: taskid});
                  else done(callback);
               });
               break;
            default:
               done(callback);
         }
      }

      /** As the later PlayMovieHelper.playMovie: plays to its last frame; btnNext / btnPre / btnClose by name. */
      private function playMovie(mc:MovieClip, callback:Function):void
      {
         if (mc == null)
         {
            done(callback);
            return;
         }
         var finished:Boolean = false;
         var finish:Function = function():void
         {
            if (finished) return;
            finished = true;
            mc.removeEventListener(MouseEvent.CLICK, onClick);
            mc.stop();
            ModalDialogManager.getInstance().removeModalDialog(mc);
            done(callback);
         };
         var onClick:Function = function(e:MouseEvent):void
         {
            switch (String(e.target.name).split("_")[0])
            {
               case "btnNext":
               case "btnnext":
                  mc.play();
                  break;
               case "btnpre":
               case "btnPre":
               case "btnPrevious":
                  mc.gotoAndStop(mc.currentFrame - 1);
                  break;
               case "btnClose":
               case "btnclose":
                  finish();
                  break;
            }
         };
         mc.gotoAndStop(1);
         mc.addEventListener(MouseEvent.CLICK, onClick);
         mc.addFrameScript(mc.totalFrames - 1, finish);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc, AlignType.NONE, PanelEffect.NONE, true, 0, 0);
         mc.gotoAndPlay(1);
      }

      /** As the later ShowCartoonHelper: a comic turned with its buttons, closed with btnClose. */
      private function showCartoon(mc:MovieClip, callback:Function):void
      {
         if (mc == null)
         {
            done(callback);
            return;
         }
         mc.gotoAndStop(1);
         mc.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            switch (String(e.target.name).split("_")[0])
            {
               case "btnPrevious":
               case "btnPre":
               case "btnpre":
               case "btnprev":
               case "btnPrev":
               case "btnBack":
               case "btnback":
                  mc.prevFrame();
                  break;
               case "btnNext":
               case "btnnext":
                  mc.nextFrame();
                  break;
               case "btnClose":
               case "btnclose":
                  ModalDialogManager.getInstance().removeModalDialog(mc);
                  done(callback);
                  break;
            }
         });
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc, AlignType.NONE, PanelEffect.NONE, true);
      }

      public function switchSceneTo(sceneName:String, callback:Function = null):void
      {
         var sm:SceneManager = SceneManager.getInstance();
         var onSceneInited:Function = function(e:SceneManagerEvent):void
         {
            sm.removeEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
            done(callback);
         };
         sm.addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
         sm.loadScene(sceneName, "default", true);
      }

      /** A fight by handler name (the later TaskHelper.fight: IPetFight.startFight(99, false, {handler})). */
      public function fight(handler:String, callback:Function = null):void
      {
         var fightService:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         if (fightService == null)
         {
            NewDialog.showFailMessage("现在不能进入战斗");
            return;
         }
         var onEnd:Function = function(e:PetFightEvent):void
         {
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END, onEnd);
            done(callback);
         };
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onEnd);
         fightService.startFight(99, false, {handler: handler});
      }

      private function hidePlayer(hide:Boolean):void
      {
         var p:PlayerBase = PlayerManager.getInstance().myPlayer;
         if (p != null) p.visible = !hide;
      }

      private static function done(callback:Function):void
      {
         if (callback != null) callback.apply();
      }
   }
}
