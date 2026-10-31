package mmo.petfightnew
{
   /**
    * REBUILT: the bosses' films of the battle (bossfightmovie/boss<file>.swf,
    * classes mmo.petfight.boss.<name>): played as the fight opens (OPENING, or
    * REVIVE for a boss's second life), when the boss falls under half or a
    * quarter of its HP (HALF_HP, QUARTER_HP) and when the player's 亚比 falls
    * under a quarter (MY_QUARTER_HP). Taken from the later client's
    * NewBossMovieConfig, the entries whose file is an era one in game/ (the
    * 2013 battle module that played them is lost). Keys: the boss's id as the
    * fight names it (variant * 10000 + species).
    */
   public class BossFilmConfig
   {
      public static const OPENING:String = "OPENING";
      public static const REVIVE:String = "REVIVE";
      public static const HALF_HP:String = "HALF_HP";
      public static const QUARTER_HP:String = "QUARTER_HP";
      public static const MY_QUARTER_HP:String = "MY_QUARTER_HP";

      private static const films:Object = {
         999: ["999", {OPENING: "Opening999", QUARTER_HP: "QuarterHp999", MY_QUARTER_HP: "MyQuarterHp999"}],
         10087: ["10087", {OPENING: "Opening10087"}],
         10090: ["10090", {OPENING: "Opening10090"}],
         10105: ["10105", {OPENING: "Opening10105", HALF_HP: "HalfHp10105", QUARTER_HP: "QuarterHp10105"}],
         10111: ["10111", {OPENING: "Opening10111", HALF_HP: "HalfHp10111", QUARTER_HP: "QuarterHp10111"}],
         10219: ["__219", {OPENING: "Opening__219"}],
         10333: ["10333", {OPENING: "Opening10333"}],
         10469: ["10469", {OPENING: "Opening10469", QUARTER_HP: "QuarterHp10469"}],
         10472: ["10469", {QUARTER_HP: "QuarterHp10472"}],
         10475: ["10475", {OPENING: "Opening10475", QUARTER_HP: "QuarterHp10475"}],
         10493: ["10493", {OPENING: "Opening10493", HALF_HP: "HalfHp10493", QUARTER_HP: "QuarterHp10493"}],
         10633: ["10633", {OPENING: "Opening10633", HALF_HP: "HalfHp10633"}],
         10744: ["10744", {OPENING: "Opening10744"}],
         10787: ["10787", {OPENING: "Opening10787"}],
         10828: ["10828", {OPENING: "Opening10828"}],
         10840: ["10840", {OPENING: "Opening10840"}],
         10944: ["10944", {OPENING: "Opening10944"}],
         10976: ["10976", {OPENING: "Opening10976"}],
         10999: ["999", {OPENING: "Opening999", QUARTER_HP: "QuarterHp999", MY_QUARTER_HP: "MyQuarterHp999"}],
         11087: ["11087", {OPENING: "Opening11087"}],
         11090: ["11090", {OPENING: "Opening11090"}],
         11320: ["11320", {OPENING: "Opening11320", REVIVE: "Revive11320"}],
         11322: ["11322", {REVIVE: "Revive11322"}],
         11523: ["11523", {OPENING: "Opening11523"}],
         12087: ["12087", {HALF_HP: "Opening12087"}],
         12090: ["12090", {HALF_HP: "Opening12090"}],
         12523: ["12523", {OPENING: "Opening12523"}],
         13523: ["13523", {OPENING: "Opening13523"}],
         14523: ["14523", {OPENING: "Opening14523", HALF_HP: "HalfHp14523"}],
         20087: ["20087", {OPENING: "Opening20087", HALF_HP: "HalfHp20087"}],
         20090: ["20090", {OPENING: "Opening20090"}],
         20317: ["10317", {HALF_HP: "HalfHp10317", QUARTER_HP: "QuarterHp10317"}],
         20418: ["20418", {OPENING: "Opening20418", HALF_HP: "HalfHp20418", QUARTER_HP: "QuarterHp20418"}],
         20427: ["20427", {OPENING: "Opening20427"}],
         20475: ["10475", {QUARTER_HP: "QuarterHp20475"}],
         20605: ["20605", {OPENING: "Opening20605"}],
         20744: ["20744", {OPENING: "Opening20744", HALF_HP: "HalfHp20744"}],
         20828: ["20828", {OPENING: "Opening20828", HALF_HP: "HalfHp20828"}],
         21309: ["21309", {OPENING: "Opening21309"}],
         30219: ["__219", {OPENING: "Opening__219"}],
         30304: ["30304", {OPENING: "Opening30304"}],
         40219: ["__219", {OPENING: "Opening__219"}],
         40320: ["40320", {OPENING: "Opening40320", HALF_HP: "HalfHp40320"}],
         60301: ["60301", {OPENING: "Opening60301"}],
         60322: ["60322", {OPENING: "Opening60322"}],
         80026: ["80026", {OPENING: "Opening80026"}],
         80027: ["80026", {OPENING: "Opening80026"}],
         80056: ["80056", {OPENING: "Opening80056"}],
         80057: ["80056", {OPENING: "Opening80056"}],
         80171: ["80056", {OPENING: "Opening80056"}],
         80185: ["80185", {OPENING: "Opening80185"}],
         80186: ["80185", {OPENING: "Opening80185"}],
         120218: ["120218", {OPENING: "Opening120218"}],
         120219: ["120219", {OPENING: "Opening120219"}],
         170010: ["170010", {OPENING: "Opening170010"}],
         180162: ["180162", {OPENING: "Opening180162"}]
      };

      /** [file, {kind: class name}] of a boss, or null. */
      public static function get(id:int):Array
      {
         return films[id] as Array;
      }
   }
}
