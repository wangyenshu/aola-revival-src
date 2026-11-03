package mmo.robot.robotitem
{
   import flash.display.Sprite;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.robot.robotpanel.IRobotItemPanel;
   import mmo.robot.robotitem.robotmaterial.FeedMaterial;
   import mmo.robot.robotitem.robotmaterial.RobotItemView;

   /**
    * REBUILT robot/robotitem (ServiceConfig "RobotItem", mmo.robot.robotitem.RobotItem):
    * the HELLO物品 panel beside the HELLO's 基本资料 (robot/robotmes). The January 2013
    * module is lost; this follows its copy of July 2016, on that copy's art, with all three
    * of its pages working (the 2016 code had kept only the clothes): 普通物品 (the HELLO's
    * 道具 of RobotItemService, and its 营养饼干), HELLO服装 and the 蓝宝石's HELLO服装.
    */
   public class RobotItem extends Sprite implements IShowPanel, IDispose, IRobotItemPanel
   {
      public var robotPanel:RobotItemPanel;

      public function RobotItem()
      {
         super();
      }

      public function showPanel():void
      {
         if (RobotItemPanel.instance != null && RobotItemPanel.instance.parent != null) return;
         robotPanel = new RobotItemPanel();
         robotPanel.initPanel(robotPanel);
         robotPanel.show();
      }

      public function initItemPanel(host:Sprite):void
      {
         showPanel();
      }

      public function setShowItemType(type:int):void
      {
         if (robotPanel != null) robotPanel.showPage(type);
      }

      public function dispose():void
      {
         if (robotPanel != null) robotPanel.dispose();
         robotPanel = null;
      }

      private static function compileMe():void
      {
         var a:FeedMaterial;
         var b:RobotItemView;
      }
   }
}
