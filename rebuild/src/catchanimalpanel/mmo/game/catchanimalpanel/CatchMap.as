package mmo.game.catchanimalpanel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.zoo.CatchAnimalClient;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT 动物捕捉地图 (the later copy's GameMap on its art, symbol 410): 大地乐园 (map0),
    * 天空乐园 (map1), 海洋乐园 (map2) and 狗狗之家 (map3). The game (game/catchanimal) reads
    * the place chosen from GameMap.whichMap (the 2013 CatchAnimalClient keeps it as
    * playingLevel too). Named apart from GameMap: the game's SWF carries a GameMap of its own.
    */
   public class CatchMap extends Sprite
   {
      public var btnClose:SimpleButton;
      public var map0:SimpleButton;
      public var map1:SimpleButton;
      public var map2:SimpleButton;
      public var map3:SimpleButton;

      private var start:StartPanel;

      public function CatchMap(from:StartPanel = null)
      {
         super();
         name = "catchMap";
         start = from;
         addEventListener(MouseEvent.CLICK, onClick);
      }

      private function onClick(e:MouseEvent):void
      {
         var n:String = String(e.target.name);
         if (n == "btnClose")
         {
            ModalDialogManager.getInstance().removeModalDialog(this);
            return;
         }
         if (n.indexOf("map") != 0) return;
         enter(int(n.charAt(3)), start, this);
      }

      /** Into the game at that 乐园 (the server lets one in first: CatchAnimalClient 97_100). */
      public static function enter(which:int, from:StartPanel, mapPanel:CatchMap = null):void
      {
         // The class the game reads, whichever copy of it the domain holds (the game carries one too).
         try
         {
            var G:Object = ApplicationDomain.currentDomain.getDefinition("mmo.game.catchanimalpanel.GameMap");
            G.whichMap = which;
            G.isTeachingMovieNeeded = false;
         }
         catch (err:Error) {}
         try { CatchAnimalClient.instance.playingLevel = which; } catch (err:Error) {}
         ProgressFullSprite.show();
         var onEnterGame:Function = function(e:SocketClientEvent):void
         {
            ProgressFullSprite.close();
            SocketClient.instance.removeEventListener(CatchAnimalClient.cmdEnterGame, onEnterGame);
            if (!e.params.res)
            {
               NewDialog.showFailMessage("进入游戏失败。");
               return;
            }
            if (mapPanel != null && mapPanel.parent != null) ModalDialogManager.getInstance().removeModalDialog(mapPanel);
            if (from != null) from.close();
            SceneManager.getInstance().pushPreviousRoomName("ecologicalpark");
            SceneManager.getInstance().loadGame("gameCatchAnimal");
         };
         SocketClient.instance.addEventListener(CatchAnimalClient.cmdEnterGame, onEnterGame);
         CatchAnimalClient.instance.enterGame();
      }
   }
}
