package mmo.revival.mod
{
   /**
    * A mod's main class (the document class of its SWF) implements this.
    * The game loads the SWF in the 沙盒's 模组 page, reads info and calls
    * start once 开始 is pressed (again on every 开始).
    */
   public interface IMod
   {
      /**
       * {id, name, author, version, description}. id: letters, digits, _ and -
       * (1 to 32): the key of the mod's saved data. name: shown in the panel.
       */
      function get info():Object;

      /** Set the mod up (rooms, 亚比) and enter its first room. */
      function start(game:IModGame):void;
   }
}
