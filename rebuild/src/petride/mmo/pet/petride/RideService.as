package mmo.pet.petride
{
   import flash.events.EventDispatcher;
   import mmo.common.member.MemberManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.SkinPosInfo;
   import mmo.interfaces.avatar.skininfo.SkinInfoFactory;
   import mmo.interfaces.material.clothes.Clothes;
   import mmo.interfaces.material.clothes.ClothesParts;
   import mmo.interfaces.material.clothes.ClothesSideTypes;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetRideInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.loader.layer.LayerManager;
   import mmo.interfaces.movestate.MoveStateType;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.Player;
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
    * (the server adds them to the "avatar" user variable), sets the player riding (the
    * "ms" user variable: MoveStateType.RIDE) and quickens the player's walk; getting off
    * (54_20) takes them away. Riding, the 2013 avatar plays its "r" rows (ActionInfo
    * "ddzr", "ddwr"): the clothes' riding pose, sitting higher, and the ride skin's 坐骑
    * (SkinInfoForRidingPet: rows 10/11, walking 4 frames, standing its stand movie), which
    * draws nothing in the walking rows. The 9 坐骑 the later client added (LATER_RIDES) have
    * their ride clothes added to the 2013 clothes service (addLaterClothes). The 2013 training (54_11, 骑乘训练 in the
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
         addLaterClothes();
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /**
       * The 坐骑 the later client added for 亚比 up to 1651 (its PetRideInfosMap: race -> ride
       * clothes, speed, level), which the 2013 map lacks: [race, clothes, speed, level].
       */
      private static const LATER_RIDES:Array = [[1101, 10089, 1.5, 40], [1122, 10087, 1.5, 42], [1350, 10086, 1.5, 40],
         [1423, 10083, 1.3, 40], [1426, 10088, 1.5, 40], [1430, 10081, 1.3, 40], [1448, 10082, 1.3, 40], [1461, 10084, 1.3, 40], [1599, 10085, 1.3, 40]];

      /** The later ride clothes' names (the later materialdata's, 10083 and 10084 as their pictures are). */
      private static const LATER_NAMES:Object = {10081: "阿波罗", 10082: "星际旋风", 10083: "噬月武神", 10084: "苍炎战神", 10085: "风暴流星",
         10086: "赤魔导士", 10087: "狼王", 10088: "黑炎龙", 10089: "飞天ET"};

      /**
       * The later ride clothes (10081–10089) made known to the 2013 clothes service, as the later
       * materialdata has them (skin/a0100xx: front a0100xx0 and back a0100xx1, the riding layout,
       * two sides): without them a rider of one of these 亚比 sits on nothing, on every client
       * (pet/petride is loaded with the game, so others' riders are drawn too).
       */
      private static function addLaterClothes():void
      {
         try
         {
            var svc:IClothesService = ServiceContainer.getService("ClothesService") as IClothesService;
            if (svc == null) return;
            for each (var r:Array in LATER_RIDES)
            {
               var id:int = int(r[1]);
               if (svc.getClothesDataById(id) != null) continue;
               var file:String = "a0" + id;
               var c:Clothes = new Clothes(id, String(LATER_NAMES[id] || ""), false, 0, false, 1, 0, 0);
               c.parts = [new ClothesParts(file + "0", SkinPosInfo.QI_CHONG__QIAN, SkinInfoFactory.RIDING_PET, ClothesSideTypes.TWO, "4444555566667777"),
                  new ClothesParts(file + "1", SkinPosInfo.QI_CHONG__HOU, SkinInfoFactory.RIDING_PET, ClothesSideTypes.TWO, "4444555566667777")];
               c.fileName = file;
               svc.getClothesDatas()[id] = c;
            }
         }
         catch (e:Error) { RLog.error("ride: the later ride clothes", e); }
      }

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
       * My player on the 坐骑 or off it at once (the server's "ms" user variable tells every
       * client, mine too, a moment later): the riding rows of the clothes and the ride skin.
       */
      private function showMount():void
      {
         var me:Player = PlayerManager.getInstance().myPlayer as Player;
         if (me != null) me.setMovingState(myRide != 0 ? String(MoveStateType.RIDE) : String(MoveStateType.WALK));
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
         showMount();
      }

      private function onScene(e:SceneManagerEvent):void
      {
         addLaterClothes();
         quicken();
         showMount();
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
