package mmo.petfollow
{
   import flash.display.DisplayObject;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.SkinPosInfo;
   import mmo.interfaces.avatar.SkinInfo;
   import mmo.interfaces.avatar.skininfo.SkinInfoFactory;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.material.clothes.Clothes;
   import mmo.interfaces.material.clothes.ClothesParts;
   import mmo.interfaces.material.clothes.ClothesSideTypes;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.revival.RLog;
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
    * Clicking it names the 亚比 and its owner. The 亚比 one could not get in
    * 2012–13 (迅猛龙 400, 邪念 605 … 57 in all) have no scene clothes: they follow
    * as their large picture (peticon<id>_L), scaled to a follower's size, instead
    * of in 雪咪兔's clothes.
    */
   import mmo.revival.RDef;

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

      private var look:DisplayObject;

      public function setPetView(dress:String = ""):void
      {
         var clothes:int = PetClothesMap.getClothesId(viewId);
         // A 亚比 after the 2013 tables (PetClothesExtra): its later scene clothes, made known.
         if (clothes == 0) clothes = extraClothes(viewId);
         if (clothes == 0)
         {
            showPicture();
            return;
         }
         var info:AvatarInfo = new AvatarInfo();
         info.setAvatarInfoWithString(dress != null && dress != "" ? clothes + ";" + dress : String(clothes));
         setAvatar(info);
      }

      /** The later clothes of a 亚比 (PetClothesExtra), added to the 2013 clothes service once; 0: none. */
      private static function extraClothes(race:int):int
      {
         var row:Array = null;
         for each (var r:Array in PetClothesExtra.ROWS) if (int(r[0]) == race) { row = r; break; }
         if (row == null) return 0;
         var id:int = int(row[1]);
         try
         {
            var svc:IClothesService = ServiceContainer.getService("ClothesService") as IClothesService;
            if (svc == null) return 0;
            if (svc.getClothesDataById(id) != null) return id;
            var c:Clothes = new Clothes(id, String(row[2]), false, 0, false, 1, 0, 0);
            var part:ClothesParts = new ClothesParts(String(row[3]), int(SkinPosInfo[row[4]]), SkinInfoFactory[row[5]] as SkinInfo, int(ClothesSideTypes[row[6]]), String(row[7]));
            c.parts = [part];
            c.fileName = String(row[8]);
            svc.getClothesDatas()[id] = c;
            return id;
         }
         catch (e:Error) { RLog.error("follow: clothes " + id + " of 亚比 " + race, e); }
         return 0;
      }

      /** No scene clothes: the 亚比's large picture, its feet where the follower stands. */
      private function showPicture():void
      {
         var cls:String = "mmo.pet.peticon" + viewId + "_L";
         var put:Function = function(... a):void
         {
            if (look != null || !RDef.has(cls)) return;
            var C:Class = RDef.get(cls);
            look = new C() as DisplayObject;
            if (look == null) return;
            var b:Rectangle = look.getBounds(look);
            var k:Number = Math.min(1, 75 / Math.max(1, b.height));
            look.scaleX = look.scaleY = k;
            look.x = -(b.left + b.width / 2) * k;
            look.y = -b.bottom * k;
            addChild(look);
         };
         if (RDef.has(cls)) put();
         else ResScheduler.getResource("peticon/peticon" + viewId, put, cls, function(e:* = null):void {});
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
