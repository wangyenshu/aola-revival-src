package mmo.weekly
{
   import flash.events.EventDispatcher;
   import mmo.config.ConfigReader;
   import mmo.interfaces.IService;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.IBookService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.weekly.IWeeklyService;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RNotice;

   /**
    * REBUILT baseservice/weekly (ServiceConfig "WeeklyService"): the 奥拉周刊.
    * The January 2013 module is lost; the copy under its URL is of July 2013.
    * As that one does, showLastestWeekly opens the issue config.xml names
    * (<weekly>, weekly127 in January 2013) as a catalog book
    * (IBookService.showCatalog / showCatalogAt), except during the first
    * newbie tasks (135, 140, 150). Issue 127 was not archived; then the
    * newest earlier issue with surviving pages is opened (WeeklyIssues, from
    * tools/gen_bconfig.py), with a word about it.
    */
   public class WeeklyService extends EventDispatcher implements IWeeklyService
   {
      public function WeeklyService()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function showLastestWeekly(pageNum:int = -1, logKey:String = "104"):void
      {
         try
         {
            var ts:ITaskService = ServiceContainer.getService("TaskService") as ITaskService;
            if (ts != null && (ts.isUserTaskDoing(135) || ts.isUserTaskDoing(140) || ts.isUserTaskDoing(150))) return;
         }
         catch (e:Error) {}
         var wanted:String = ConfigReader.instance.xmlDocument ? String(ConfigReader.instance.xmlDocument.weekly) : "";
         var n:int = int(wanted.replace(/\D/g, ""));
         var have:int = 0;
         for each (var i:int in WeeklyIssues.ISSUES) if (i <= n || n == 0) have = Math.max(have, i);
         if (have == 0)
         {
            RNotice.show(LayerManager.getBaseTop(), "奥拉周刊没有保存下来。");
            return;
         }
         var no:String = "weekly" + have;
         ServiceContainer.instance.tryGetService(IBookService, function(svc:IBookService, o:Object):void
         {
            if (pageNum < 0) svc.showCatalog(no);
            else svc.showCatalogAt(no, pageNum);
            if (have != n && n > 0)
               RNotice.show(LayerManager.getBaseTop(), "第" + n + "期奥拉周刊没有保存下来，这是第" + have + "期留下的几页。", 4);
         });
      }
   }
}
