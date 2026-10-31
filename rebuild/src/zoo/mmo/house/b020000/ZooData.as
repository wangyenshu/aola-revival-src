package mmo.house.b020000
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;

   /**
    * The zoo's data on the client: the era ZooAnimalData through the material
    * service (type 12; race ids give the Animal itself, with its mature name,
    * stars, home, hours to grow and what it may turn into), the animals'
    * pictures (zoopeticon/peticonsmall<race> young, peticonlarge<race> grown,
    * as the era ZooIconLoader loads them), and the ZooExtension commands.
    */
   public class ZooData
   {
      public static const EXT:String = "ZooExtension";
      public static const ANIMAL_TYPE:int = 12;
      public static const RACES:int = 40;
      /** ZooItemData 饲料 the zoo sells: [item id, name, 晶币, what it does]. Prices RECONSTRUCTED (server zoo.ts FODDER). */
      public static const FODDER:Array = [
         [5, "初级加速饲料", 200, "成熟时间缩短1小时"],
         [6, "中级加速饲料", 1000, "成熟时间缩短6小时"],
         [7, "高级加速饲料", 3000, "成熟时间缩短24小时"],
         [1, "普通变异饲料", 1000, "变异概率增加10%，每只幼仔只能用1次"],
         [2, "一星变异饲料", 2000, "一星幼仔100%变异"],
         [3, "二星变异饲料", 4000, "二星以下幼仔100%变异"],
         [4, "三星变异饲料", 6000, "三星以下幼仔100%变异"],
         [8, "四星变异饲料", 8000, "四星以下幼仔100%变异"]
      ];

      public static function send(cmd:String, params:Object = null):void
      {
         SocketClient.instance.sendXtMessage(EXT, cmd, params || {});
      }

      /** The era Animal of this race (name, matureName, starNum, position, matureTime, evoNameArr, evoRateArr, gainWay, dec), or null. */
      public static function animal(race:int):Object
      {
         try
         {
            var f:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            var s:IMaterialService = f ? f.getService(ANIMAL_TYPE) : null;
            return s ? s.getMaterialById(race) : null;
         }
         catch (e:Error) { RLog.error("zoo animal " + race, e); }
         return null;
      }

      public static function nameOf(race:int, grown:Boolean = false):String
      {
         var a:Object = animal(race);
         if (a == null) return "动物" + race;
         return grown ? String(a.matureName) : String(a.name);
      }

      public static function stars(race:int):String
      {
         var a:Object = animal(race);
         var n:int = a ? int(a.starNum) : 1;
         var s:String = "";
         for (var i:int = 0; i < n; i++) s += "★";
         return s;
      }

      /** What a young one may turn into: "蝴蝶伊奴 25%" (or two of them). */
      public static function mutations(race:int, extra:int = -1):String
      {
         var a:Object = animal(race);
         if (a == null) return "";
         var names:Array = a.evoNameArr as Array || [];
         var rates:Array = a.evoRateArr as Array || [];
         var out:Array = [];
         for (var i:int = 0; i < names.length; i++) out.push(names[i] + " " + (extra >= 0 && i == 0 ? extra : int(rates[i])) + "%");
         return out.join("、");
      }

      public static function hoursText(seconds:int):String
      {
         if (seconds <= 0) return "已经长大了";
         var h:int = int(seconds / 3600);
         var m:int = Math.ceil((seconds % 3600) / 60);
         if (m == 60) { h++; m = 0; }
         return "还要" + (h > 0 ? h + "小时" : "") + (m > 0 || h == 0 ? m + "分钟" : "");
      }

      /** The animal's picture, fitted into size x size, centred on 0, 0 with its feet at 0. */
      public static function picture(race:int, grown:Boolean, size:Number, into:Sprite):void
      {
         var path:String = "zoopeticon/peticon" + (grown ? "large" : "small") + race;
         var cls:String = "mmo.zoo.pet.PetIcon" + (grown ? "Large" : "Small") + race;
         var put:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var v:DisplayObject = new C() as DisplayObject;
            if (v == null) return;
            while (into.numChildren) into.removeChildAt(0);
            DisplayUtil.scaleDisplay(v, size, size);
            var holder:Sprite = new Sprite();
            holder.addChild(v);
            var b:* = v.getBounds(holder);
            v.x -= b.x + b.width / 2;
            v.y -= b.y + b.height;
            into.addChild(holder);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource(path, put, cls, function(e:* = null):void { RLog.log("zoo: no picture " + path); });
      }
   }
}
