package mmo.game.catchanimalpanel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.zoo.CatchAnimalClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;

   /**
    * REBUILT 动物捕捉 (game/catchanimalpanel, StartPanel; the later copy's code on its art,
    * symbol 137): what the player has of the seven things of the game (CatchAnimalClient
    * 97_104), 进入 (the map of the four 乐园, CatchMap; without 能源石 or a 糖果 the TipsPanel
    * says so), 操作说明 (HelpPanel) and 购买道具. That button opened the 动物乐园购买册
    * (catalog201108, catalog/catchanimalgame), which is lost: CatchShop sells the same seven
    * things (RECONSTRUCTED). The later copy's teaching film for a first visit is left out.
    */
   public class StartPanel extends Sprite
   {
      public static const NAMES:Array = ["能源石", "普通糖果", "美味糖果", "驯服糖果", "高级防护罩", "多重音符", "欢乐炸弹"];
      private static var current:StartPanel;

      public var btnBuy:SimpleButton;
      public var btnClose:SimpleButton;
      public var btnHelp:SimpleButton;
      public var btnOk:SimpleButton;
      public var i1:MovieClip;
      public var i2:MovieClip;
      public var i3:MovieClip;
      public var i4:MovieClip;
      public var i5:MovieClip;
      public var i6:MovieClip;
      public var i7:MovieClip;
      public var item0:TextField;
      public var item1:TextField;
      public var item2:TextField;
      public var item3:TextField;
      public var item4:TextField;
      public var item5:TextField;
      public var item6:TextField;

      /** The panel (mmo.revival.RCatchAnimal loads the module and calls this). map: -1 the
       * map of the four 乐园 after 进入, else that 乐园 at once (the 生态园's fishing spot: 海洋乐园). */
      public static function open(map:int = -1):void
      {
         if (current != null) current.close();
         current = new StartPanel();
         current.map = map;
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      /** The 乐园 进入 goes to (-1: the map to choose one). */
      public var map:int = -1;

      public function StartPanel()
      {
         super();
         name = "catchStart";
         addEventListener(MouseEvent.CLICK, onClick);
         addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
         CatchAnimalClient.instance.addEventListener(CatchAnimalClient.cmdUpdate, ask);
         for (var i:int = 1; i <= 7; i++)
         {
            var icon:Sprite = getChildByName("i" + i) as Sprite;
            if (icon != null) TipsManager.getInstance().addTips(icon, NAMES[i - 1]);
         }
         ask();
      }

      public function close():void
      {
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }

      /** What the player has, asked anew (after a purchase too). */
      public function ask(e:Event = null):void
      {
         CatchAnimalClient.instance.addEventListener(CatchAnimalClient.cmdGetGameItemsGame, onItems);
         CatchAnimalClient.instance.getGameItemGame();
      }

      private function onItems(e:Event):void
      {
         CatchAnimalClient.instance.removeEventListener(CatchAnimalClient.cmdGetGameItemsGame, onItems);
         var n:Array = CatchAnimalClient.instance.itemNum || [];
         for (var i:int = 0; i < CatchAnimalClient.itemTypeNum; i++)
         {
            var t:TextField = getChildByName("item" + i) as TextField;
            if (t != null) t.text = String(int(n[i]));
         }
      }

      private function onRemove(e:Event):void
      {
         removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
         CatchAnimalClient.instance.removeEventListener(CatchAnimalClient.cmdUpdate, ask);
         CatchAnimalClient.instance.removeEventListener(CatchAnimalClient.cmdGetGameItemsGame, onItems);
         if (current == this) current = null;
      }

      private function onClick(e:MouseEvent):void
      {
         switch (e.target.name)
         {
            case "btnClose":
               close();
               break;
            case "btnOk":
               var team:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
               if (team != null && team.getMyTeam() != null)
               {
                  NewDialog.showFailMessage("组队状态不能进入游戏！");
                  return;
               }
               if (!ready()) return;
               if (map >= 0) CatchMap.enter(map, this);
               else ModalDialogManager.getInstance().addModalDialog(new CatchMap(this));
               break;
            case "btnHelp":
               ModalDialogManager.getInstance().addModalDialog(new HelpPanel());
               break;
            case "btnBuy":
               CatchShop.show(this);
               break;
         }
      }

      /** 能源石, and one of the three 糖果. */
      private function ready():Boolean
      {
         var n:Array = CatchAnimalClient.instance.itemNum || [];
         if (int(n[0]) <= 0)
         {
            ModalDialogManager.getInstance().addModalDialog(new TipsPanel(1, this));
            return false;
         }
         if (int(n[1]) <= 0 && int(n[2]) <= 0 && int(n[3]) <= 0)
         {
            ModalDialogManager.getInstance().addModalDialog(new TipsPanel(2, this));
            return false;
         }
         return true;
      }
   }
}
