package mmo.fbteam.common
{
   import flash.events.EventDispatcher;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.configure.FbWildPetConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.fbteam.dataobject.FBPetInfo;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.pet.fight.IWildPet;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class FbWildPetManager extends EventDispatcher implements IDispose
   {
      
      private static var _instance:FbWildPetManager = null;
      
      private var wildPetService:IWildPet = null;
      
      private var allPetLoc:Object = FbWildPetConfig.PETS_LOCATION_CLONE;
      
      private var unAutoScenes:Array = FbWildPetConfig.UNAUTO_SCENES_CLONE;
      
      private var hasCurrentWildPet:Boolean = false;
      
      private var currentWildPets:Array = null;
      
      private var currentWildPetsLoc:Array = null;
      
      private var currentDelPets:Array = null;
      
      public function FbWildPetManager()
      {
         super();
      }
      
      public static function get instance() : FbWildPetManager
      {
         if(_instance == null)
         {
            _instance = new FbWildPetManager();
         }
         return _instance;
      }
      
      private function getFbWildPetInfo() : void
      {
         this.currentWildPets = [];
         this.currentDelPets = [];
         SocketClient.instance.addEventListener(FbClient.cmdGetFbWildPet,this.onGetFbWildPetInfo);
         FbClient.instance.getFbWildPet(null);
      }
      
      private function onGetFbWildPetInfo(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdGetFbWildPet,this.onGetFbWildPetInfo);
         var _loc2_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         if(this.allPetLoc.hasOwnProperty(_loc2_))
         {
            this.hasCurrentWildPet = true;
            this.currentWildPetsLoc = this.allPetLoc[_loc2_] as Array;
            this.petsInit(param1);
            if(this.isAutoScene())
            {
               this.addCurrentPets(this.currentWildPets);
            }
         }
         else
         {
            this.hasCurrentWildPet = false;
         }
      }
      
      private function petsInit(param1:SocketClientEvent) : void
      {
         var _loc5_:Object = null;
         var _loc2_:Array = param1.params.pms as Array;
         this.currentWildPets = [];
         var _loc3_:Array = [];
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length && this.currentWildPets.length < this.currentWildPetsLoc.length)
         {
            _loc5_ = _loc2_[_loc4_];
            if(_loc3_.indexOf(_loc5_.id) == -1)
            {
               this.currentWildPets.push(new FBPetInfo(_loc5_.raceId,_loc5_.id,_loc5_.lv,this.currentWildPetsLoc[_loc3_.length]));
               _loc3_.push(_loc5_.id);
            }
            _loc4_++;
         }
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         this.wildPetService.dispose();
         if(Boolean(param1.isWin) || Boolean(param1.isEscape))
         {
            if(param1.isWin)
            {
               this.delPet(param1.raceId,param1.id);
               this.notifyDel(param1.raceId,param1.id);
            }
            this.addCurrentPets(this.currentWildPets);
         }
      }
      
      private function notifyDel(param1:int, param2:int) : void
      {
         var _loc3_:Object = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_START,
            "scene":SceneManager.getInstance().loadedSceneInfo.sceneName,
            "raceId":param1,
            "id":param2
         };
         TeamSynchronizedClient.notify(_loc3_);
      }
      
      private function delPet(param1:int, param2:int) : void
      {
         var _loc5_:FBPetInfo = null;
         if(this.checkDel(param1,param2))
         {
            return;
         }
         var _loc3_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         var _loc4_:* = int(this.currentWildPets.length - 1);
         while(_loc4_ >= 0)
         {
            _loc5_ = this.currentWildPets[_loc4_] as FBPetInfo;
            if(_loc5_.isSamePet(param1,param2))
            {
               this.currentDelPets.push(this.currentWildPets[_loc4_]);
               this.currentWildPets.splice(_loc4_,1);
               this.currentWildPetsLoc.splice(_loc4_,1);
            }
            _loc4_--;
         }
         if(this.currentWildPets.length == 0)
         {
            this.hasCurrentWildPet = false;
            delete this.allPetLoc[SceneManager.getInstance().loadedSceneInfo.sceneName];
            this.dispatchEvent(new FbEvent(FbEvent.ON_KILL_ALL_MONSTER,{}));
         }
      }
      
      private function checkDel(param1:int, param2:int) : Boolean
      {
         var _loc3_:FBPetInfo = null;
         for each(_loc3_ in this.currentDelPets)
         {
            if(_loc3_.isSamePet(param1,param2))
            {
               return true;
            }
         }
         return false;
      }
      
      private function addCurrentPets(param1:Array) : void
      {
         if(this.hasCurrentWildPet && this.currentWildPetsLoc.length != 0 && this.currentWildPets.length != 0)
         {
            CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
            this.wildPetService.generatePetsAtCurrentScene(param1);
         }
         else
         {
            this.hasCurrentWildPet = false;
         }
      }
      
      private function isAutoScene() : Boolean
      {
         return this.unAutoScenes.indexOf(SceneManager.getInstance().loadedSceneInfo.sceneName) == -1;
      }
      
      public function init() : void
      {
         this.wildPetService = ServiceContainer.getService(IWildPet) as IWildPet;
      }
      
      public function updatePetInfo() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         this.getFbWildPetInfo();
      }
      
      public function generateCurrentScenePets() : void
      {
         this.addCurrentPets(this.currentWildPets);
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.removeEventListener(FbClient.cmdGetFbWildPet,this.onGetFbWildPetInfo);
         _instance = null;
      }
   }
}

