package mmo.robot.robotitem.robotmaterial
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.viewloader.ViewLoader;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.material.robot.UserRobotItem;
   import mmo.interfaces.robot.robotpanel.RobotPanelEvent;
   import mmo.interfaces.robot.robotpanel.RobotPanelEventDispatcher;

   /**
    * LATER (robot/robotitem 2016, symbol 6): one HELLO 道具 with its count. A click
    * asks, then uses one (RobotClient.useItem, 2-5 {ii}): 能量晶石 feeds the HELLO,
    * the other 晶石 (经验分配, 经验加成, 亚比训练, 技能唤醒) give it their skill.
    */
   public class RobotItemView extends Sprite
   {
      public var txtNum:TextField;

      private var item:UserRobotItem;

      private static const TIPS:Object = {
         1: "HELLO的基本食物，可以给HELLO填肚子的哦。",
         2: "让HELLO学会经验分配，把它保管的经验分给亚比。",
         5: "让HELLO学会经验加成，亚比战斗获得的经验更多。",
         6: "让HELLO学会亚比训练。",
         7: "让HELLO学会亚比技能替换。"
      };

      public function RobotItemView(u:UserRobotItem)
      {
         super();
         item = u;
         var id:int = u.materialId;
         var v:DisplayObject = ViewLoader.instance.getViewCustom("mmo.robotitem.view" + id, "robotitem/view" + id, 53, 53);
         addChildAt(v, 0);
         if (txtNum) txtNum.text = String(u.quantity);
         TipsManager.getInstance().addComplexTips(this, u.material.name, TIPS[id] || "");
         buttonMode = true;
         addEventListener(MouseEvent.CLICK, onClick);
      }

      private function onClick(e:MouseEvent):void
      {
         NewDialog.getCofirmDialog("你确定要给HELLO使用" + item.material.name + "吗？", function(d:ModalDialog):void
         {
            d.addEventListener(ModalDialogEvent.OK, onOk);
            d.show();
         });
      }

      private function onOk(e:ModalDialogEvent):void
      {
         SocketClient.instance.addEventListener(RobotClient.cmdUseItem, onUsed);
         ProgressFullSprite.show();
         RobotClient.instance.useItem(item.materialId);
      }

      private function onUsed(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(RobotClient.cmdUseItem, onUsed);
         ProgressFullSprite.close();
         if (int(e.params.res) == 1) NewDialog.showSucceedMessage(e.params.msg ? String(e.params.msg) : "主人对HELLO最好了，HELLO最喜欢主人了！");
         else NewDialog.showFailMessage(e.params.msg ? String(e.params.msg) : "现在不能使用这个道具哦。");
         RobotPanelEventDispatcher.getInstance().dispatchEvent(new RobotPanelEvent(RobotPanelEvent.UPDATEITEM));
         RobotClient.instance.getRobot();
      }
   }
}
