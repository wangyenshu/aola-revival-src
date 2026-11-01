package mmo.pm.service
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.pm.data.PMCustomData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.revival.RLog;

   /**
    * REBUILT pet/pmservice (PMService). The January 2013 module is lost and the
    * live one is a 2026 rework on later interfaces. This hands out the 2013
    * PMCustomData (interfaces library): its four maps of rows, PMData by race,
    * PMExp by experience type, PMAttDef by attribute and PMSkill by skill, in
    * the columns of the 2013 PMExcelMap. The rows are the revival's tables
    * (PMTables, tools/gen_pmservice.py from revival/pmdata.json). Panels of the
    * era read names and numbers here, as the 天赋启迪 王者无敌榜 its 亚比's names
    * (customData.pmDataMap.getPM(race).pmName).
    *
    * addPM (the revival's, docs/MODDING.md): a mod's 亚比, known while the
    * page runs.
    */
   public class PMService extends EventDispatcher implements IPMService
   {
      private var _customData:PMCustomData = null;
      /** The PMDataMap's own object: rows added later are found by getPM. */
      private var pmRows:Object = {};

      public function PMService()
      {
         super();
      }

      public function init():void
      {
         var skills:Object = {};
         var exp:Object = {};
         var att:Object = {};
         try
         {
            for each (var p:Array in PMTables.pms) pmRows[p[0]] = PMTables.newPM(p);
            for each (var s:Array in PMTables.skills) skills[s[0]] = PMTables.newSkill(s);
            for (var t:String in PMTables.exp) exp[t] = PMTables.newExp(PMTables.exp[t] as Array);
            for (var a:String in PMTables.attDef) att[a] = PMTables.newAttDef(PMTables.attDef[a] as Array);
         }
         catch (e:Error) { RLog.error("PMService tables", e); }
         _customData = new PMCustomData();
         _customData.initData(pmRows, exp, att, skills);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function get customData():PMCustomData
      {
         return _customData;
      }

      /**
       * The revival's: a mod's 亚比 (race 900001–999999), so the panels that ask
       * here find its name, attributes, stats and skills while its mod runs.
       * stats: [hp, attack, defence, special attack, special defence, speed];
       * learn: [[level, skill], …].
       */
      public function addPM(race:int, name:String, attr1:int, attr2:int, stats:Array, learn:Array, expType:String = "2"):void
      {
         if (race < 900001 || race > 999999) return;
         var r:Array = [];
         for (var i:int = 0; i < PMTables.PM_COLUMNS; i++) r.push("");
         r[0] = String(race);
         r[1] = name;
         for (i = 0; i < 6; i++) r[4 + i] = String(stats && i < stats.length ? int(stats[i]) : 0);
         for (i = 0; i < 6; i++) r[10 + i] = "0";
         r[16] = String(attr1);
         r[17] = String(attr2);
         r[20] = "0";
         r[21] = expType || "2";
         r[24] = r[25] = "NA";
         r[26] = "0-" + race;
         var parts:Array = [];
         for each (var l:Array in learn || []) if (l != null && l.length > 1) parts.push(int(l[0]) + "-" + int(l[1]));
         r[29] = parts.join("#");
         pmRows[r[0]] = PMTables.newPM(r);
      }
   }
}
