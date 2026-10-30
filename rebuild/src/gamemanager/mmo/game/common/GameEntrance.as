package mmo.game.common
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.game.GameManager;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * LATER game entrance (game/gamemanager of 2015, decompiled; its
    * ContainerBase folded in): the game's panel from gameentrancepanel/*
    * with OK (btnok), cancel and close. REBUILT: a game without a surviving
    * panel starts at once.
    */
   public class GameEntrance
   {
      private var gameId:int;
      private var gm:GameManager;
      private var ext:Object;
      private var panel:MovieClip;

      public function GameEntrance(id:int, gm:GameManager, ext:Object)
      {
         super();
         this.gameId = id;
         this.gm = gm;
         this.ext = ext;
      }

      public function tryShowPanel():void
      {
         var res:String = GameMap.getGameEntranceRes(gameId);
         var cls:String = GameMap.getGameEntranceClass(gameId);
         if (res == null || cls == null) return start();
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) return show(cls);
         ProgressFullSprite.show();
         ResScheduler.getResource(res, function(r:*):void
         {
            ProgressFullSprite.close();
            if (ApplicationDomain.currentDomain.hasDefinition(cls)) show(cls);
            else start();
         }, "", function(e:*):void
         {
            ProgressFullSprite.close();
            start();
         });
      }

      private function start():void
      {
         gm.cancelGameKey();
         gm.loadGame(gameId, ext);
      }

      private function show(cls:String):void
      {
         try
         {
            var c:Class = getDefinitionByName(cls) as Class;
            panel = new c() as MovieClip;
         }
         catch (e:Error)
         {
            panel = null;
         }
         if (panel == null) return start();
         gm.cancelGameKey();
         var ok:SimpleButton = panel.getChildByName("btnok") as SimpleButton;
         var cancel:SimpleButton = panel.getChildByName("btncancel") as SimpleButton;
         var close:SimpleButton = panel.getChildByName("btnclose") as SimpleButton;
         if (ok == null) return start();
         ok.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { closePanel(); gm.loadGame(gameId, ext); });
         if (cancel) cancel.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { closePanel(); });
         if (close) close.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { closePanel(); });
         ModalDialogManager.getInstance().addModalDialog(panel, AlignType.NONE, PanelEffect.NONE, true, 0, 0, true);
      }

      private function closePanel():void
      {
         if (panel != null) ModalDialogManager.getInstance().removeModalDialog(panel);
      }
   }
}
