package mmo.pet.dataservice
{
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.follow.PetFollowEvent;
   import flash.events.EventDispatcher;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.data.PlayerBriefInfo;
   import mmo.revival.RLog;

   /**
    * REBUILT pet/petdataservice (mmo.pet.dataservice.PetDataService,
    * IPetDataService): the player's 亚比. Speaks the 2013 PetClient protocol
    * (PocketMonsterExtension): loadPMMaster 1101 -> 2101 (PlayerBriefInfo),
    * viewAllPM 1212 -> 2212 {pmList: [PetBriefInfo], pms: "curId#…"},
    * viewSinglePM 1211 -> 2211 {pm: PetDetailedInfo}, new pet 2201, current
    * pet 2221; the data classes of the 2013 interfaces parse the replies.
    * Written to the 2013 interface after the later module's flow.
    */
   public class PetDataService extends EventDispatcher implements IPetDataService
   {
      private static var _instance:PetDataService;
      private var myInfo:PlayerBriefInfo;
      private var myPets:Array = [];
      private var details:Object = {};
      private var selectPetId:int = -1;
      private var followPetId:int = -1;
      private var ridePetId:int = -1;
      private var inited:Boolean;

      public function PetDataService()
      {
         super();
         _instance = this;
      }

      public static function get instance():PetDataService
      {
         return _instance;
      }

      public function init():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener(String(PetClient.RSPN_LOAD_PM_MASTER), onLoadMaster);
         sc.addEventListener(String(PetClient.RSPN_VIEW_ALL_PM), onViewAllPet);
         sc.addEventListener(String(PetClient.RSPN_VIEW_SINGLE_PM), onViewSinglePet);
         sc.addEventListener(String(PetClient.RSPN_NEW_PM), onNewPet);
         sc.addEventListener(String(PetClient.RSPN_SET_CURRENT_PM), onSetCurrentPet);
         sc.addEventListener(String(PetClient.RSPN_PM_LEVELUP), onLevelUp);
         CommonEventDispatcher.instance.addEventListener(PetFollowEvent.SET_FOLLOW, onSetFollow);
         CommonEventDispatcher.instance.addEventListener(PetFollowEvent.SET_UNFOLLOW, onUnFollow);
         // The following 亚比 at login: user variable "p" = "raceId,viewId,petId,…" ("0#0#0": none).
         try
         {
            var pv:Array = String(sc.currentUser.getVariable("p") || "").split(",");
            if (pv.length > 2 && int(pv[2]) > 0) followPetId = int(pv[2]);
         }
         catch (err:Error) {}
         PetClient.instance.loadPMMaster();
      }

      private function onLoadMaster(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(String(PetClient.RSPN_LOAD_PM_MASTER), onLoadMaster);
         myInfo = new PlayerBriefInfo();
         try { myInfo.parseInfo(e.params); } catch (err:Error) { RLog.error("pet master", err); }
         PetClient.instance.viewAllPM();
      }

      private function onViewAllPet(e:SocketClientEvent):void
      {
         myPets = [];
         var cur:int = int(String(e.params.pms || "").split("#")[0]);
         for each (var o:Object in (e.params.pmList as Array) || [])
         {
            var p:PetBriefInfo = new PetBriefInfo();
            try { p.parseInfo(o); } catch (err:Error) { RLog.error("pet brief", err); continue; }
            if (p.id == cur) myPets.unshift(p);
            else myPets.push(p);
         }
         if (myInfo != null && myPets.length > 0) myInfo.curPM = myPets[0];
         if (selectPetId < 0 && myPets.length > 0) selectPetId = PetBriefInfo(myPets[0]).id;
         dispatchEvent(new PetDataServiceEvent(PetDataServiceEvent.RSPN_VIEW_ALL_PM, e.params));
         if (!inited)
         {
            inited = true;
            dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
            if (myPets.length == 0) StarterOffer.watch(this);
         }
      }

      private function onViewSinglePet(e:SocketClientEvent):void
      {
         var d:PetDetailedInfo = new PetDetailedInfo();
         try { d.parseInfo(e.params.pm); } catch (err:Error) { RLog.error("pet detail", err); return; }
         details[d.id] = d;
         var i:int = indexOf(d.id);
         if (i >= 0) myPets[i] = d;
         if (myInfo && myInfo.curPM && myInfo.curPM.id == d.id) myInfo.curPM.updateInfo(d);
         dispatchEvent(new PetDataServiceEvent(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM, e.params));
      }

      private function onNewPet(e:SocketClientEvent):void
      {
         if (e.params.msg != undefined) return;
         var d:PetDetailedInfo = new PetDetailedInfo();
         try { d.parseInfo(e.params.pm); } catch (err:Error) { RLog.error("new pet", err); return; }
         details[d.id] = d;
         if (myPets.length < 6) myPets.push(d);
         if (myInfo)
         {
            myInfo.addPMCountInClient();
            if (myPets.length == 1) myInfo.curPM = d;
         }
         if (selectPetId < 0) selectPetId = d.id;
         dispatchEvent(new PetDataServiceEvent("rspn_new_pm", e.params));
      }

      private function onSetCurrentPet(e:SocketClientEvent):void
      {
         var i:int = indexOf(int(e.params.id));
         if (i > 0)
         {
            var first:* = myPets[0];
            myPets[0] = myPets[i];
            myPets[i] = first;
         }
         if (myInfo && myPets.length) myInfo.curPM = myPets[0];
         dispatchEvent(new PetDataServiceEvent(PetDataServiceEvent.RSPN_SET_CURRENT_PM, e.params));
      }

      private function onLevelUp(e:SocketClientEvent):void
      {
         dispatchEvent(new PetDataServiceEvent(PetDataServiceEvent.RSPN_PM_LEVELUP, e.params));
      }

      private function indexOf(id:int):int
      {
         for (var i:int = 0; i < myPets.length; i++) if (PetBriefInfo(myPets[i]).id == id) return i;
         return -1;
      }

      // ---------------------------------------------------------------- IPetDataService

      public function getMyInfo():PlayerBriefInfo
      {
         return myInfo;
      }

      public function getMyPets():Array
      {
         return myPets;
      }

      public function getPetByPetId(id:int):PetBriefInfo
      {
         var i:int = indexOf(id);
         return i >= 0 ? myPets[i] : null;
      }

      public function getPetDetailedInfoById(id:int):PetDetailedInfo
      {
         return details[id] as PetDetailedInfo;
      }

      public function hasAvailablePet():Boolean
      {
         for each (var p:PetBriefInfo in myPets) if (p.curHp > 0) return true;
         return false;
      }

      public function checkPetIsEmpty():Boolean
      {
         return myPets.length == 0;
      }

      public function checkSinglePetPPIsFull(p:PetBriefInfo):Boolean
      {
         return true;
      }

      public function checkAllPetPPIsFull():Boolean
      {
         return true;
      }

      public function checkAllPetHPIsFull():Boolean
      {
         for each (var p:PetBriefInfo in myPets) if (p.curHp < p.maxHp) return false;
         return true;
      }

      public function setCurPmHpPPFull():void
      {
         if (myInfo && myInfo.curPM) myInfo.curPM.setHpPPFullInClient();
      }

      public function setAllPmHpPPFull():void
      {
         for each (var p:PetBriefInfo in myPets) p.setHpPPFullInClient();
      }

      public function recureAllPet(callback:Function = null):void
      {
         setAllPmHpPPFull();
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_heal", {});
         if (callback != null) callback();
      }

      public function deletePetByPetId(id:int):void
      {
         var i:int = indexOf(id);
         if (i >= 0) myPets.splice(i, 1);
         if (myInfo) myInfo.decPMCountInClient();
      }

      public function getSelectPetId():int
      {
         return selectPetId;
      }

      public function setSelectPetId(id:int):void
      {
         selectPetId = id;
         dispatchEvent(new PetDataServiceEvent(PetDataServiceEvent.SELECTE_CHAGNE, {id: id}));
      }

      private function onSetFollow(e:PetFollowEvent):void
      {
         followPetId = e.followPetId;
      }

      private function onUnFollow(e:PetFollowEvent):void
      {
         followPetId = -1;
      }

      public function getCurFollowPetId():int
      {
         return followPetId;
      }

      public function setCurFollowPetId(id:int):void
      {
         followPetId = id;
      }

      public function getCurRidePetId():int
      {
         return ridePetId;
      }

      public function setCurRidePetId(id:int):void
      {
         ridePetId = id;
      }

      public function setPMExp(exp:int):void
      {
         if (myInfo) myInfo.pmExp = exp;
      }
   }
}
