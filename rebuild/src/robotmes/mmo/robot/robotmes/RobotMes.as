package mmo.robot.robotmes
{
   import flash.display.Sprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.floatpanel.FloatPanelManager;
   import mmo.framework.comm.RobotClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.robot.IRobotService;
   import mmo.interfaces.robot.RobotEvent;
   import mmo.interfaces.robot.robotpanel.IRobotItemPanel;
   import mmo.interfaces.robot.robotpanel.RobotPanelEvent;
   import mmo.interfaces.robot.robotpanel.RobotPanelEventDispatcher;
   import mmo.revival.RLog;

   /**
    * REBUILT robot/robotmes (ServiceConfig "RobotMes", mmo.robot.robotmes.RobotMes,
    * showPanel): the panel of one's own HELLO, 基本资料. The January 2013 module
    * is lost; its copy of November 2015 keeps the panel (RobotMesPanel, the art
    * this module is built on) but no longer opens it itself. Here showPanel asks
    * the HELLO (RobotClient.getRobot, 2-0) and shows the panel with what comes
    * back, and beside it the HELLO's 道具 / 装扮 (RobotItem, robot/robotitem),
    * which closes with it (RobotPanelEvent.CLOSEROBOTMESPANEL), as the later
    * panels do.
    */
   public class RobotMes extends Sprite implements IShowPanel, IDispose
   {
      public static var panel:RobotMesPanel;
      public static var isShow:Boolean = false;

      private var robotService:IRobotService;

      public function RobotMes()
      {
         super();
      }

      public function showPanel():void
      {
         if (panel != null && panel.parent != null) return;
         robotService = ServiceContainer.getService("RobotDataService") as IRobotService;
         if (robotService == null) return;
         robotService.addEventListener(RobotEvent.GETROBOT, onRobot);
         RobotClient.instance.getRobot();
      }

      private function onRobot(e:RobotEvent):void
      {
         robotService.removeEventListener(RobotEvent.GETROBOT, onRobot);
         var o:Object = e.params;
         if (o == null || o.has === 0 || o.n == null)
         {
            NewDialog.showFailMessage("你还没有HELLO哦！完成新手任务，普伦博士会送你一只。");
            return;
         }
         try
         {
            panel = new RobotMesPanel(o);
            FloatPanelManager.getInstance().addFloatPanel(panel, 100, 60, panel.tuopanel, 1);
            isShow = true;
         }
         catch (err:Error)
         {
            RLog.error("robotmes", err);
            return;
         }
         ServiceContainer.instance.tryGetService("RobotItem", function(svc:IService, x:Object = null):void
         {
            try
            {
               if (svc is IShowPanel) IShowPanel(svc).showPanel();
               else if (svc is IRobotItemPanel) IRobotItemPanel(svc).initItemPanel(null);
            }
            catch (err2:Error) { RLog.error("robotmes items", err2); }
         });
      }

      /** The panel was closed: the HELLO's 道具 / 装扮 beside it go too. */
      public static function closed():void
      {
         isShow = false;
         panel = null;
         RobotPanelEventDispatcher.getInstance().dispatchEvent(new RobotPanelEvent(RobotPanelEvent.CLOSEROBOTMESPANEL));
      }

      public function dispose():void
      {
         if (robotService != null) robotService.removeEventListener(RobotEvent.GETROBOT, onRobot);
      }
   }
}
