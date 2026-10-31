package mmo.dailyactivity
{
   import flash.events.MouseEvent;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.pet.data.PetClothesMap;
   import mmo.play.player.sceneplayer.ScenePlayer;

   /**
    * A 守护者 standing in its scene: a scene player dressed in the 亚比's
    * scene "clothes" (PetClothesMap, as the era viparena ArenaPetGenerator
    * dresses its bosses; the 2013 boss pictures dailyactivity/dailyboss<id>
    * are lost). A click asks which of its forms to fight (BossPanel).
    */
   public class BossAvatar extends ScenePlayer
   {
      public var boss:Object;
      private var onPick:Function;

      public function BossAvatar(boss:Object, view:int, onPick:Function)
      {
         super("guardian_" + boss.scene + "_" + boss.part);
         name = "guardian_" + boss.part;
         this.boss = boss;
         this.onPick = onPick;
         var clothes:int = PetClothesMap.getClothesId(view);
         if (clothes == 0) clothes = 20060;
         var info:AvatarInfo = new AvatarInfo();
         info.setAvatarInfoWithString(String(clothes));
         setAvatar(info);
         try { setNickName("守护者 " + boss.name); } catch (e:Error) {}
         buttonMode = true;
      }

      override protected function onClickPlayer(e:MouseEvent):void
      {
         e.stopPropagation();
         if (onPick != null) onPick(boss);
      }
   }
}
