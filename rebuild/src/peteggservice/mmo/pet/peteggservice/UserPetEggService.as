package mmo.pet.peteggservice
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import mmo.framework.comm.PetEggClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.parse.ASObjectArrayParse;
   import mmo.interfaces.pet.petegg.IUserPetEggService;
   import mmo.interfaces.pet.petegg.PatchEggs;
   import mmo.interfaces.pet.petegg.UserPetEgg;

   /**
    * REBUILT UserPetEggService (pet/peteggservice; the January 2013 module is
    * lost), after the later one: the eggs being hatched, by hatching kind
    * (UserPetEgg.STATE_*), as the server's getHatchEggs replies ("1-2" {st, os,
    * es}) give them; panels read them with getEggs (an empty batch rather than
    * the stand-in's null). The later robot hatching and its checker are not
    * part of the 2013 game: addChecker and removeChecker do nothing.
    */
   public class UserPetEggService extends EventDispatcher implements IUserPetEggService
   {
      private var eggs:Object = {};

      public function UserPetEggService()
      {
         super();
      }

      public function init():void
      {
         SocketClient.instance.addEventListener(PetEggClient.cmdGetHatchEggs, onGetHatchEggs);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function getEggs(state:int):PatchEggs
      {
         if (eggs[state] == null) eggs[state] = new PatchEggs();
         return eggs[state] as PatchEggs;
      }

      public function showPetEggOnlineOrOfflinePanel(key:String):void
      {
      }

      public function addChecker():void
      {
      }

      public function removeChecker():void
      {
      }

      private function onGetHatchEggs(e:SocketClientEvent):void
      {
         var st:int = int(e.params.st);
         var os:int = e.params.os != null ? int(e.params.os) : UserPetEgg.STATE_OFFLINE_HATCH;
         var batch:PatchEggs = getEggs(os);
         batch.clear();
         if (st == 2) batch.eggs = ASObjectArrayParse.parseArray(e.params.es, UserPetEgg);
         dispatchEvent(new Event("UserPetEggUpdate"));
      }
   }
}
