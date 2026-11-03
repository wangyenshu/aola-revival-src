package mmo.pet.petride
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.utils.getQualifiedClassName;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.common.member.MemberManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetRideInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.loader.layer.LayerManager;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REBUILT pet/petride (RideService; the January 2013 module is lost, the copy under
    * its URL is of 2021): riding a 亚比, a 蓝宝骑士's 坐骑. The 34 亚比 one could ride are
    * the 2013 interfaces' PetRideInfosMap: each has its ride clothes (10047–10080, the
    * "骑宠" skins skin/a0100xx), the level it must have reached and its speed. A ride
    * (PetExtension 54_12 {pmId, cId}) puts the ride clothes on the player for everyone
    * (the server adds them to the "avatar" user variable) and quickens the player's walk;
    * getting off (54_20) takes them away. The engine draws no ride clothes, so the
    * service shows the 坐骑 itself under the player, from the ride skin's own two
    * layers (a0<id>0_C behind, a0<id>1_C in front; one standing frame, RECONSTRUCTED:
    * the 2013 riding animation is lost). The 2013 training (54_11, 骑乘训练 in the
    * 蓝宝骑士 service) is counted as done (RECONSTRUCTED: the trained flag is lost).
    */
   public class RideService extends EventDispatcher implements IRideService
   {
      private var myRide:int = 0;
      private var myCloth:int = 0;
      private var mySpeed:Number = 1;
      private var _effect:Boolean = true;

      public function RideService()
      {
         super();
      }

      public function init():void
      {
         SocketClient.instance.addEventListener("54_12", onRide);
         SocketClient.instance.addEventListener("54_20", onUnride);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onScene);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /**
       * The 坐骑 the later client added for 亚比 up to 1651 (its PetRideInfosMap: race -> ride
       * clothes, speed, level), which the 2013 map lacks: [race, clothes, speed, level].
       */
      private static const LATER_RIDES:Array = [[1101, 10089, 1.5, 40], [1122, 10087, 1.5, 42], [1350, 10086, 1.5, 40],
         [1423, 10083, 1.3, 40], [1426, 10088, 1.5, 40], [1430, 10081, 1.3, 40], [1448, 10082, 1.3, 40], [1461, 10084, 1.3, 40], [1599, 10085, 1.3, 40]];

      private static function infoOf(race:int):PetRideInfo
      {
         try
         {
            var info:PetRideInfo = PetRideInfosMap.instance.getPetRideInfo(race);
            if (info != null) return info;
         }
         catch (e:Error) {}
         for each (var r:Array in LATER_RIDES) if (int(r[0]) == race) return new PetRideInfo(race, 1, int(r[1]), Number(r[2]), int(r[3]));
         return null;
      }

      public function get getMyRidePetId():int
      {
         return myRide;
      }

      public function get getOtherRidePetId():int
      {
         return 0;
      }

      public function validateRidePetRace():Array
      {
         return [30, 45, 105, 141, 278, 138, 198, 300, 189, 299, 153, 24, 90, 481, 506, 290, 493, 391, 388, 75, 215, 111, 624, 653, 654, 741, 775, 794, 180, 838, 1082, 1126, 1240, 1356,
            1101, 1122, 1350, 1423, 1426, 1430, 1448, 1461, 1599];
      }

      public function validateRideReady(p:PetBriefInfo):Boolean
      {
         return p != null && infoOf(p.raceId) != null;
      }

      public function validatePetRideLevelEnough(p:PetBriefInfo):Boolean
      {
         var info:PetRideInfo = p ? infoOf(p.raceId) : null;
         return info != null && p.level >= info.getLevel;
      }

      public function validatePetIsTranning(p:PetBriefInfo):Boolean
      {
         return true;
      }

      public function hasRideCard():Boolean
      {
         return isMember();
      }

      public function cardIsEffect():Boolean
      {
         return isMember();
      }

      private static function isMember():Boolean
      {
         try { return MemberManager.instance.isMember(); } catch (e:Error) {}
         return false;
      }

      public function get rideServieIsEffect():Boolean
      {
         return _effect;
      }

      public function set rideServieIsEffect(v:Boolean):void
      {
         _effect = v;
      }

      public function get isClientRide():Boolean
      {
         return myRide != 0;
      }

      public function trainPet(p:PetBriefInfo):void
      {
         if (p != null) SocketClient.instance.sendXtMessage("PetExtension", "54_11", {pmId: p.id});
      }

      /** Ride p: a 亚比 of the list, of its level, and the player a 蓝宝骑士. */
      public function ride(p:PetBriefInfo):void
      {
         var info:PetRideInfo = p ? infoOf(p.raceId) : null;
         if (info == null) return say("这只亚比还不能骑乘哦！");
         if (!isMember()) return say("快成为蓝宝石的一员，接受骑乘训练吧！只有蓝宝骑士才能骑乘亚比哦！");
         if (p.level < info.getLevel) return say(p.name + "要到" + info.getLevel + "级才能骑乘哦！");
         if (!_effect) return say("这里不能骑乘亚比哦！");
         SocketClient.instance.sendXtMessage("PetExtension", "54_12", {pmId: p.id, cId: info.getPetRideClothId});
      }

      public function clientRide(p:PetBriefInfo):void
      {
         ride(p);
      }

      public function unRide(p:PetBriefInfo):void
      {
         if (myRide != 0) SocketClient.instance.sendXtMessage("PetExtension", "54_20", {pmId: myRide});
      }

      public function rideToWalk():void
      {
         unRide(null);
      }

      /**
       * The standing frame shown of the ride skin: its two layers' bitmaps of that frame
       * (a0<id>0_C_<n> behind the rider, a0<id>1_C_<n> in front), which share their place
       * on the skin's sheet, so set at the same corner, round the rider's feet.
       */
      private static const MOUNT_FRAME:int = 30;
      private var back:Bitmap;
      private var front:Bitmap;
      private var skinDomain:ApplicationDomain;
      private var skinOf:int;

      private function showMount():void
      {
         hideMount();
         if (myCloth == 0) return;
         var cloth:int = myCloth;
         var put:Function = function(dom:ApplicationDomain):void
         {
            var me:DisplayObjectContainer = PlayerManager.getInstance().myPlayer as DisplayObjectContainer;
            if (me == null || myCloth != cloth || dom == null) return;
            skinDomain = dom;
            skinOf = cloth;
            back = frame(dom, "a0" + cloth + "0_C_" + MOUNT_FRAME);
            front = frame(dom, "a0" + cloth + "1_C_" + MOUNT_FRAME);
            var w:Number = Math.max(back ? back.width : 0, front ? front.width : 0);
            var h:Number = Math.max(back ? back.height : 0, front ? front.height : 0);
            for each (var b:Bitmap in [back, front])
            {
               if (b == null) continue;
               b.x = -w / 2;
               b.y = 18 - h;
            }
            if (back != null) me.addChildAt(back, 0);
            if (front != null) me.addChild(front);
            lift(me, true);
            RLog.log("ride: mount a0" + cloth + " " + int(w) + "x" + int(h));
         };
         if (skinDomain != null && skinOf == cloth) put(skinDomain);
         else ResScheduler.getResource("skin/a0" + cloth, function(content:*):void
         {
            var dom:ApplicationDomain = null;
            try { dom = content.loaderInfo.applicationDomain; } catch (e0:Error) {}
            put(dom || ApplicationDomain.currentDomain);
         }, "", function(e:* = null):void { RLog.log("ride: no skin a0" + cloth); });
      }

      private static function frame(dom:ApplicationDomain, cls:String):Bitmap
      {
         try
         {
            if (!dom.hasDefinition(cls)) return null;
            var bd:BitmapData = new (dom.getDefinition(cls) as Class)(0, 0) as BitmapData;
            return bd != null && bd.width > 4 ? new Bitmap(bd) : null;
         }
         catch (err:Error) { RLog.error("ride: frame " + cls, err); }
         return null;
      }

      /** The rider sits on the 坐骑's back: the avatar raised by LIFT (RECONSTRUCTED), back down on foot. */
      private static const LIFT:int = 55;
      private var lifted:DisplayObject;

      private function lift(me:DisplayObjectContainer, up:Boolean):void
      {
         if (lifted != null)
         {
            lifted.y += LIFT;
            lifted = null;
         }
         if (!up || me == null) return;
         for (var i:int = 0; i < me.numChildren; i++)
         {
            var c:DisplayObject = me.getChildAt(i);
            if (getQualifiedClassName(c).indexOf("SkinProxyContainer") >= 0)
            {
               c.y -= LIFT;
               lifted = c;
               return;
            }
         }
      }

      private function hideMount():void
      {
         lift(null, false);
         for each (var m:Bitmap in [back, front]) if (m != null && m.parent != null) m.parent.removeChild(m);
         back = null;
         front = null;
      }

      private function onRide(e:SocketClientEvent):void
      {
         if (e.params.succ != true)
         {
            if (e.params.msg) say(String(e.params.msg));
            return;
         }
         myRide = int(e.params.pmId);
         myCloth = int(e.params.cId);
         mySpeed = Number(e.params.sp) || 1;
         quicken();
         showMount();
         RLog.log("ride: " + myRide + " (clothes " + myCloth + ", ×" + mySpeed + ")");
      }

      private function onUnride(e:SocketClientEvent):void
      {
         myRide = 0;
         myCloth = 0;
         mySpeed = 1;
         quicken();
         hideMount();
      }

      private function onScene(e:SceneManagerEvent):void
      {
         quicken();
         if (myRide != 0) showMount();
      }

      /** The player's walk at the 坐骑's speed (PlayerBase.WALK_SPEED alone on foot). */
      private function quicken():void
      {
         var me:PlayerBase = PlayerManager.getInstance().myPlayer as PlayerBase;
         if (me != null) me.walkSpeed = Math.round(PlayerBase.WALK_SPEED * (myRide != 0 ? mySpeed : 1));
      }

      private static function say(msg:String):void
      {
         RNotice.show(LayerManager.getBaseTop(), msg);
      }
   }
}
