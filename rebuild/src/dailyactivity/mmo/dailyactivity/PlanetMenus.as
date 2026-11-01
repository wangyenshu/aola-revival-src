package mmo.dailyactivity
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;

   /**
    * REBUILT: the NPC menus of the 2012 planets' activities. The January 2013
    * task/tasknpc and its menu table are lost; the later tasknpc keeps them
    * (config/npc/NpcMenu, npcMenuConfig) and the activities' own code waits for
    * their actions. Each scene's NPCs get their menu entries as choices of
    * their talk (ITaskNpcService.addNpcInteraction):
    *  - 达黑黑 (516, 海枯之山, put there by the scene's 召唤达黑黑): its story,
    *    猜弹珠 and how to get 弹珠, answered by rarepets/raredaheihei's DaHeiHeiInitialler;
    *  - 独角兽守护者 (459, 独角兽密林, after the three light balls): 独角兽的王者之路,
    *    answered by unicorn/skyunicornservice (the 宣传 panel).
    */
   public class PlanetMenus
   {
      private static const MENUS:Object = {
         haikustar4: [[516, "达黑黑的故事", "516_daHeiHeiStory"], [516, "和达黑黑猜弹珠", "516_playBalls"], [516, "如何获得弹珠", "516_howToGetBalls"]],
         unicornstar3: [[459, "独角兽的王者之路", "459_SkyUnicornBringUp"]]
      };

      public static function onScene(sceneName:String):void
      {
         var list:Array = MENUS[sceneName] as Array;
         if (list == null) return;
         var ns:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         if (ns == null) return;
         for each (var m:Array in list) ns.addNpcInteraction(int(m[0]), String(m[1]), String(m[2]));
      }
   }
}
