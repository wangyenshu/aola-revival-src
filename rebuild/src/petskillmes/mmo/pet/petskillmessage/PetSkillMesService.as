package mmo.pet.petskillmessage
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.data.IPetSkillMesService;

   /**
    * REBUILT pet/petskillmesservice (mmo.pet.petskillmessage.PetSkillMesService,
    * IPetSkillMesService): what the era panels ask about a 亚比 or a skill,
    * answered with the fields of the later module's objects (getPetMes:
    * id, pname, attribute, attribute2, evolution [{level, raceId}], exptype;
    * getPetSkillMes: id, pname, power, aim, pp, attribute, type, descriptor).
    * The January 2013 module is lost and the live one is a 2026 rework on the
    * later IPMService; the data are the revival's 亚比 and skill tables
    * (PetMesData, tools/gen_petmes.py). Egg pictures are petegg/egg<race>,
    * else the egg of the 亚比's attribute (petegg/egg<attribute>).
    */
   public class PetSkillMesService extends EventDispatcher implements IPetSkillMesService
   {
      public function PetSkillMesService()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      private static function row(race:int):Array
      {
         var r:Array = PetMesData.pets[String(race)] as Array;
         // Variants of a task or boss 亚比 (variant * 10000 + species) are the species.
         if (r == null && race > 10000) r = PetMesData.pets[String(race % 10000)] as Array;
         return r;
      }

      private static function evolution(s:String):Array
      {
         var out:Array = [];
         for each (var part:String in s.split("#"))
         {
            var lr:Array = part.split("-");
            out.push({level: int(lr[0]), raceId: int(lr[1])});
         }
         return out;
      }

      public function getPetMes(param1:int):Object
      {
         var r:Array = row(param1);
         if (r == null) return {id: String(param1), pname: "亚比" + param1, attribute: "0", attribute2: "0", evolution: [{level: 0, raceId: param1}], exptype: "2", type: 0};
         return {id: String(param1), pname: String(r[0]), attribute: String(r[1]), attribute2: String(r[2]), evolution: evolution(String(r[3])),
            exptype: String(r[4] || "2"), type: int(r[1]), height: "", weight: "", catchRate1: "", catchRate2: "", setfreetype: "", defaultskill: ""};
      }

      public function getPetNextForm(param1:int):Object
      {
         var line:Array = getPetMes(param1).evolution;
         for (var i:int = 0; i < line.length - 1; i++)
         {
            if (line[i].raceId == param1)
            {
               var n:Object = line[i + 1];
               n.name = getPetMes(n.raceId).pname;
               return n;
            }
         }
         return null;
      }

      public function getPetSkillMes(param1:int):Object
      {
         var s:Array = PetMesData.skills[String(param1)] as Array;
         if (s == null) return {id: String(param1), pname: "技能" + param1, power: "0", aim: "100", pp: "0", attribute: "0", type: "0", descriptor: "", getdesc: ""};
         return {id: String(param1), pname: String(s[0]), power: String(s[1]), aim: String(s[2]), pp: String(s[3]), attribute: String(s[4]),
            type: String(s[5]), range: "", descriptor: String(s[6]), getdesc: String(s[6]), skill1: null, skill2: null};
      }

      public function getPetMaxexpByRaceIdAndLevel(param1:int, param2:int):int
      {
         var table:Array = PetMesData.exp[getPetMes(param1).exptype] as Array;
         if (table == null) return 0;
         return int(table[Math.max(0, Math.min(table.length - 1, param2))]);
      }

      /** The attribute table of the 2013 battle is the server's (battle.ts); the panels only show it. */
      public function compareAttributeRelation(param1:int, param2:int, param3:int = -1):int
      {
         return 0;
      }

      public function getAllPetRaceId():Array
      {
         var out:Array = [];
         for (var k:String in PetMesData.pets) out.push(int(k));
         out.sort(Array.NUMERIC);
         return out;
      }

      public function getPetAttributeTipsByRaceId(param1:int):String
      {
         return getPetAttributeTipsByattributeId(int(getPetMes(param1).attribute));
      }

      public function getPetAttributeTipsByattributeId(param1:int):String
      {
         // The attribute names of the era, as the later PMAttributeMap lists them (0–22).
         var names:Array = ["普通", "格斗", "飞行", "毒", "爬行", "土", "虫", "数码", "机械", "火", "水", "木", "电", "神秘", "冰", "上古", "暗黑", "数码2", "光明", "龙", "圣灵", "神兵", "王"];
         return param1 >= 0 && param1 < names.length ? names[param1] + "系" : "";
      }

      public function getMaxRaceIdByEggId(param1:int):int
      {
         var line:Array = getPetMes(param1).evolution;
         return line.length ? int(line[line.length - 1].raceId) : param1;
      }

      public function getPetEggIcon(param1:int):Sprite
      {
         return new EggIcon(param1 >= 0 && param1 <= 17 ? [param1] : []);
      }

      public function getPetAttributeIconByRaceId(param1:int, param2:int = 1):Sprite
      {
         return new Sprite();
      }

      public function getPetEggIconByRaceId(param1:int):Sprite
      {
         return new EggIcon([param1, int(getPetMes(param1).attribute)]);
      }

      public function getPetPhase(param1:int):int
      {
         var line:Array = getPetMes(param1).evolution;
         for (var i:int = 0; i < line.length; i++) if (line[i].raceId == param1) return i;
         return 0;
      }

      public function getSkillAttributeIcon(param1:int):Sprite
      {
         return new Sprite();
      }
   }
}
