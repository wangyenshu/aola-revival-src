package mmo.play.player.sceneplayer
{
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.pet.data.PetClothesMap;
   import mmo.play.player.movable.strategy.RoundPointStrategy;
   import mmo.revival.RLog;

   /**
    * REBUILT (the 2013 engine class is lost). A 亚比 standing in a scene for a
    * scene's own script: new ScenePetAvatar(race, point, onClick) dresses a
    * scene player in the 亚比's scene "clothes" (PetClothesMap; 20068 when
    * unmapped, as the wild 亚比 do), lets it wander a little round the point
    * and calls onClick(event) when it is clicked (上古之境's 龙族大法师,
    * 倒立金字塔's wood and soil monsters, which then start their battles).
    */
   public class ScenePetAvatar extends ScenePlayer
   {
      private var race:int;
      private var onClick:Function;

      public function ScenePetAvatar(race:int, point:Point = null, onClick:Function = null)
      {
         super("scenepet_" + race);
         this.race = race;
         this.onClick = onClick;
         try { setNickNameVisible(false); } catch (e:Error) {}
         var clothes:int = PetClothesMap.getClothesId(race % 10000);
         if (clothes <= 0) clothes = 20068;
         var info:AvatarInfo = new AvatarInfo();
         info.setAvatarInfoWithString(String(clothes));
         setAvatar(info);
         buttonMode = true;
         if (point != null)
         {
            x = point.x;
            y = point.y;
            try { setStrategy(new RoundPointStrategy(point, 30, 2000, 5000)); } catch (e2:Error) { RLog.error("scene pet " + race, e2); }
         }
      }

      public function get raceId():int
      {
         return race;
      }

      override protected function onClickPlayer(e:MouseEvent):void
      {
         e.stopPropagation();
         if (onClick == null) return;
         try { onClick(e); } catch (err:Error) { RLog.error("scene pet " + race + " click", err); }
      }
   }
}
