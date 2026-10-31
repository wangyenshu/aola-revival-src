package mmo.scene.starland
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.zoo.CatchAnimalClient;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneManager;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * LATER scene/ecologicalpark (生态园): the 2020 copy's code compiled
    * against the 2013 interfaces, on its own art (the January 2013 scene is
    * lost). Its entrances are those of the 2013 map (十字大道, 蓝宝石要塞,
    * 奥拉运动场). Its three game spots open the 生态园's games of the
    * January 2013 config.xml (game rooms owned by ecologicalpark), through
    * SceneManager.loadGame as the era scenes do: the 保卫战 board (pvzgame)
    * the three 保卫战 games (gamePvZ 动物保卫战, gameGuardNut 天空保卫战,
    * gameSeaDefend 海底保卫战; the later scene arrows of all three point at
    * that board, the panel it opened is lost and is drawn here), the 动物捕捉
    * spot (game) gameCatchAnimal, and the fishing spot (btngamecatchfish;
    * 捕鱼达人 came later) the 海底保卫战 too. The later code's activities (比巴卜, 卡牌, 职业 panels,
    * the zoo door of 2014's 动物公会) are left out.
    */
   public class EcologicalParkRevived extends SceneBase
   {
      private static const DEFENCE:Array = [
         ["gamePvZ", "动物保卫战"], ["gameGuardNut", "天空保卫战"], ["gameSeaDefend", "海底保卫战"]];
      private static const locationKey:String = "fromecologicalpark";
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      public function EcologicalParkRevived()
      {
         super(300, 360);
         addInitLocation("fromstarland", new Point(170, 420));
         addInitLocation("frombluesquare", new Point(540, 180));
         addInitLocation("fromchamberofcommerce", new Point(660, 450));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         var tips:TipsManager = TipsManager.getInstance();
         var e1:InteractiveObject = foreground.et1 as InteractiveObject;
         tips.addTips(e1, "十字大道");
         addEntrances(e1, "crossroad", locationKey, null, FaceDirectionTypes.FACERIGHTDOWN);
         var e2:InteractiveObject = foreground.et2 as InteractiveObject;
         tips.addTips(e2, "蓝宝石要塞");
         addEntrances(e2, "bluesquare", locationKey, null, FaceDirectionTypes.FACERIGHTUP);
         var e3:InteractiveObject = foreground.et3 as InteractiveObject;
         tips.addTips(e3, "奥拉运动场");
         addEntrances(e3, "gymnasium", locationKey, null, FaceDirectionTypes.FACERIGHTDOWN);
         game(background.pvzgame, "保卫战", "");
         game(background.game, "动物捕捉", "gameCatchAnimal");
         game(backGround.getChildByName("btngamecatchfish"), "海底保卫战", "gameSeaDefend");
      }

      private function game(spot:*, tip:String, room:String):void
      {
         var io:InteractiveObject = spot as InteractiveObject;
         if (io == null) return;
         TipsManager.getInstance().addTips(io, tip);
         if (io is MovieClip) MovieClip(io).buttonMode = true;
         io.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            var team:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
            if (team != null && team.getMyTeam() != null)
            {
               NewDialog.showFailMessage("组队状态不能进入游戏！");
               return;
            }
            if (room == "")
            {
               chooseDefence();
               return;
            }
            if (room != "gameCatchAnimal")
            {
               SceneManager.getInstance().loadGame(room);
               return;
            }
            // 动物捕捉 reads its tools from CatchAnimalClient (97_104) and
            // is entered on the server first (97_100), as the later
            // catchanimalpanel does before it loads the game.
            CatchAnimalClient.instance.getGameItemGame();
            SocketClient.instance.addEventListener(CatchAnimalClient.cmdEnterGame, function entered(ev:SocketClientEvent):void
            {
               SocketClient.instance.removeEventListener(CatchAnimalClient.cmdEnterGame, entered);
               if (ev.params.res) SceneManager.getInstance().loadGame(room);
               else NewDialog.showFailMessage("进入游戏失败。");
            });
            CatchAnimalClient.instance.enterGame();
         });
      }

      /** The 保卫战 board's choice of the three games (drawn in the look of the rebuilt panels). */
      private function chooseDefence():void
      {
         var top:Sprite = new Sprite();
         top.name = "defenceChooser";
         var close:Function = function():void { if (top.parent) top.parent.removeChild(top); };
         top.addChild(RUI.dim(close));
         var box:Sprite = RUI.panel(300, 270, "保卫战", close, "defenceClose");
         box.x = (960 - 300) / 2;
         box.y = (560 - 270) / 2 - 10;
         top.addChild(box);
         for (var i:int = 0; i < DEFENCE.length; i++)
         {
            var row:Array = DEFENCE[i];
            var b:Sprite = RUI.button(row[1], pick(String(row[0]), close), 180, 40, 0xFFC45A, 0xF07812, "defence_" + row[0]);
            b.x = (300 - 180) / 2;
            b.y = 70 + i * 60;
            box.addChild(b);
         }
         LayerManager.getBaseTop().addChild(top);
      }

      private function pick(room:String, close:Function):Function
      {
         return function():void
         {
            close();
            SceneManager.getInstance().loadGame(room);
         };
      }
   }
}
