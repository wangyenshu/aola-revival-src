package mmo.config
{
   import flash.display.Sprite;
   import mmo.reader.BConfigData;

   /**
    * REBUILT mmo.config.ConfigEmbed (in the later client config/config.swf):
    * the embedded configurations later catalog modules read. Only the book
    * list is filled (era pages, tools/gen_bconfig.py); the task tables belong
    * to the task engine and stay empty here.
    */
   public class ConfigEmbed extends Sprite
   {
      public static var bconfig:XMLList = new XMLList(BConfigData.BCONFIG);
      public static var tconfig:XML = <config><scene/></config>;
      public static var weeklyConfig:XML = <config/>;
      public static var weeklyPetInfooModifyConfig:XML = <config/>;
      public static var editorTaskConfig:Object = {taskDefines: [], npc: {}, area: {}};

      public function ConfigEmbed()
      {
         super();
      }
   }
}
