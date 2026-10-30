package mmo.petfollow
{
   import flash.events.MouseEvent;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.pet.data.PetClothesMap;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.ScenePlayer;

   /**
    * REBUILT. The following 亚比: a scene player dressed in the 亚比's scene
    * "clothes" (PetClothesMap: view id -> clothes id, 20060 when unmapped,
    * e.g. 吉拉 4 -> 20123 -> skin/a000123.swf), walked by FollowSlowlyStrategy.
    * Clicking it names the 亚比 and its owner.
    */
   public class PetFollowAvatar extends ScenePlayer
   {
      private var raceId:int;
      private var viewId:int;
      private var petId:int;
      private var owner:String;
      private var ind:String;

      public function PetFollowAvatar(name:String, raceId:int, viewId:int, petId:int, owner:String, ind:String)
      {
         super(name);
         this.raceId = raceId;
         this.viewId = viewId;
         this.petId = petId;
         this.owner = owner;
         this.ind = ind;
         setNickNameVisible(false);
      }

      public function setPetView(dress:String = ""):void
      {
         var clothes:int = PetClothesMap.getClothesId(viewId);
         if (clothes == 0) clothes = 20060;
         var info:AvatarInfo = new AvatarInfo();
         info.setAvatarInfoWithString(dress != null && dress != "" ? clothes + ";" + dress : String(clothes));
         setAvatar(info);
      }

      override protected function onClickPlayer(e:MouseEvent):void
      {
         e.stopPropagation();
         var petName:String = "亚比";
         try
         {
            var dict:IPetDictionaryDataService = ServiceContainer.getService("PetDictionaryDataService") as IPetDictionaryDataService;
            var item:PetDictionaryDataItem = dict ? dict.getDataItemByRaceId(raceId) : null;
            if (item != null) petName = item.petName;
         }
         catch (err:Error) {}
         var who:String = owner;
         var p:Player = PlayerManager.getInstance().playerList[owner] as Player;
         if (p != null) who = p.nickName;
         say(owner == SocketClient.instance.myUserName ? "我是你的" + petName + "！" : "我是" + who + "的" + petName + "！", 3);
      }
   }
}
