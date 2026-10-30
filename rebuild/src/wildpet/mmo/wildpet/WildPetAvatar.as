package mmo.wildpet
{
   import flash.display.DisplayObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.filters.GlowFilter;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getTimer;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient2;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.antiaddiction.IAntiAddiction;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.PetClothesMap;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.RoundPointStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;

   /**
    * REBUILT. A wild 亚比 in a scene: a scene player dressed in the 亚比's scene
    * "clothes" (PetClothesMap; 20068 when unmapped, as the later ScenePetBase
    * does), wandering around its point. Pointing at it shows "Lv.min～max name";
    * clicking walks the player to it (the scene's own click walk), and once
    * the player reaches it PetClient2.startPKWithRobot(raceId) (54_2) starts
    * the battle, after the anti-addiction check of the later ScenePetBase.
    * Where the scene can't be walked up to the 亚比, the battle starts from
    * as near as the player gets. A 亚比 whose scene skin is lost (朵朵兔's
    * skin/a000059 is in no archive) stands in as its era large icon
    * (peticon<race>_L), so it can still be seen and clicked.
    */
   public class WildPetAvatar extends ScenePlayer
   {
      private static const REACH:int = 45;
      private static const CHASE_MS:int = 15000;

      private var raceId:int;
      private var levelText:String;
      private var title:Sprite;
      private var chaseUntil:int;
      private var walked:Boolean;
      private var walkedAt:int;
      private var artCheck:Timer;

      public function WildPetAvatar(name:String, raceId:int, level:String)
      {
         super(name);
         this.raceId = raceId;
         this.levelText = level;
         setNickNameVisible(false);
         var clothes:int = PetClothesMap.getClothesId(raceId);
         if (clothes <= 0) clothes = 20068;
         var info:AvatarInfo = new AvatarInfo();
         info.setAvatarInfoWithString(String(clothes));
         setAvatar(info);
         walkSpeed = 2;
         addEventListener(MouseEvent.ROLL_OVER, onOver);
         addEventListener(MouseEvent.ROLL_OUT, onOut);
         artCheck = new Timer(4000, 1);
         artCheck.addEventListener(TimerEvent.TIMER, checkArt);
         artCheck.start();
      }

      /** No skin drawn after a while: show the 亚比's large icon instead. */
      private function checkArt(e:TimerEvent):void
      {
         artCheck = null;
         if (isDisposed) return;
         var art:DisplayObject = avatarSprite;
         if (art != null && art.height >= 8) return;
         var cls:String = "mmo.pet.peticon" + raceId + "_L";
         var self:WildPetAvatar = this;
         var put:Function = function(... a):void
         {
            if (isDisposed || !ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var d:DisplayObject = new (getDefinitionByName(cls) as Class)() as DisplayObject;
            var r:Rectangle = d.getBounds(d);
            var k:Number = Math.min(1, 70 / Math.max(1, r.height));
            d.scaleX = d.scaleY = k;
            d.x = -(r.left + r.width / 2) * k;
            d.y = -r.bottom * k + 6;
            var holder:Sprite = new Sprite();
            holder.name = "standIn";
            holder.addChild(d);
            self.addChildAt(holder, 0);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("peticon/peticon" + raceId, put, cls, function(e:* = null):void {});
      }

      public function get race():int
      {
         return raceId;
      }

      public function wander(center:Point, radius:int):void
      {
         setStrategy(new RoundPointStrategy(center, radius, 4000, 4000));
      }

      private function petName():String
      {
         try
         {
            var dict:IPetDictionaryDataService = ServiceContainer.getService("PetDictionaryDataService") as IPetDictionaryDataService;
            var item:PetDictionaryDataItem = dict ? dict.getDataItemByRaceId(raceId) : null;
            if (item != null) return item.petName;
         }
         catch (err:Error) {}
         return "亚比";
      }

      private function onOver(e:MouseEvent):void
      {
         if (title == null)
         {
            title = new Sprite();
            title.mouseEnabled = title.mouseChildren = false;
            var tf:TextField = new TextField();
            tf.defaultTextFormat = new TextFormat("宋体", 12, 0xFFFFFF, true);
            tf.autoSize = TextFieldAutoSize.LEFT;
            tf.selectable = false;
            tf.text = "Lv." + levelText + " " + petName();
            tf.filters = [new GlowFilter(0x0B4E54, 1, 3, 3, 6)];
            var bg:Shape = new Shape();
            bg.graphics.lineStyle(1, 0x66FFFF);
            bg.graphics.beginFill(0x105D64, 0.85);
            bg.graphics.drawRoundRect(-4, -1, tf.width + 8, tf.height + 2, 10, 10);
            title.addChild(bg);
            title.addChild(tf);
            title.x = -tf.width / 2;
            title.y = -top - tf.height - 10;
         }
         addChild(title);
      }

      private function onOut(e:MouseEvent):void
      {
         if (title && title.parent) title.parent.removeChild(title);
      }

      /** The scene walks the player to the click; meet it there. */
      override protected function onClickPlayer(e:MouseEvent):void
      {
         if (!canFight()) return;
         chaseUntil = getTimer() + CHASE_MS;
         walked = false;
         // (The 亚比 may be walking: its own step listener is on ENTER_FRAME too.)
         addEventListener(Event.ENTER_FRAME, onChase);
      }

      private function canFight():Boolean
      {
         var aa:IAntiAddiction = ServiceContainer.getService("AntiAddictionService") as IAntiAddiction;
         if (aa != null && aa.getAvailableTime() <= 0)
         {
            NewDialog.showFailMessage("小奥拉今天的体力消耗很大，无法进行对战，还是进行一些轻松的活动吧！");
            return false;
         }
         var data:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         if (data != null && data.checkPetIsEmpty())
         {
            NewDialog.showFailMessage("你还没有亚比，先去领取一只亚比吧！");
            return false;
         }
         return true;
      }

      private function onChase(e:Event):void
      {
         var me:PlayerBase = PlayerManager.getInstance().myPlayer;
         if (me == null || isDisposed || getTimer() > chaseUntil)
         {
            removeEventListener(Event.ENTER_FRAME, onChase);
            return;
         }
         var dx:Number = me.x - x, dy:Number = me.y - y;
         // Close enough, or stopped as near as the scene lets the player come.
         if (dx * dx + dy * dy <= REACH * REACH || (walked && !me.isMoving() && getTimer() - walkedAt > 600))
         {
            removeEventListener(Event.ENTER_FRAME, onChase);
            me.stop();
            setStrategy(null);
            stop();
            CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL, onFail);
            PetClient2.instance.startPKWithRobot(raceId);
         }
         else if (!me.isMoving())
         {
            me.walkTo(int(x), int(y));
            walked = true;
            walkedAt = getTimer();
         }
      }

      private function onFail(e:PetFightEvent):void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL, onFail);
         if (!isDisposed) wander(new Point(x, y), 50);
      }

      override public function dispose():void
      {
         removeEventListener(Event.ENTER_FRAME, onChase);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL, onFail);
         if (artCheck) artCheck.stop();
         artCheck = null;
         setStrategy(null);
         super.dispose();
         if (parent) parent.removeChild(this);
      }
   }
}
