package mmo.play.activity.handler.money
{
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.text.TextField;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.Commands;
   import mmo.framework.comm.SocketClient;

   /**
    * REVIVAL (aola-revival). The later engine's MyXingBiHandler (the 2013 engine has none): keeps
    * the text field `txtName` of `container` showing the player's 星币 (UserInfo.xingbi), again
    * on every Commands.onXingBiUpdated, until the container leaves the stage or dispose().
    * 酷跑星世界's 金币 and 星星能量 shops show the 星币 with it.
    */
   public class MyXingBiHandler
   {
      private var _container:DisplayObjectContainer;
      private var _txtName:String;
      private var _autoDispose:Boolean;
      private var _listening:Boolean;

      public function MyXingBiHandler(container:DisplayObjectContainer, txtName:String, autoDispose:Boolean = true)
      {
         super();
         _container = container;
         _txtName = txtName;
         _autoDispose = autoDispose;
         init();
      }

      public function reset(txtName:String, container:DisplayObjectContainer = null):void
      {
         _txtName = txtName;
         if (container != null) _container = container;
         init();
      }

      private function init():void
      {
         if (_container == null || !(_container.getChildByName(_txtName) is TextField)) return;
         if (!_listening)
         {
            _listening = true;
            SocketClient.instance.addEventListener(Commands.onXingBiUpdated, onXingBiUpdated);
            _container.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
         }
         update();
      }

      private function onXingBiUpdated(e:*):void
      {
         update();
      }

      private function update():void
      {
         if (_container == null) return;
         var tf:TextField = _container.getChildByName(_txtName) as TextField;
         if (tf != null) tf.text = String(UserInfo.xingbi);
      }

      private function onRemoved(e:Event):void
      {
         if (_autoDispose) dispose();
      }

      public function dispose():void
      {
         if (_container != null) _container.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
         SocketClient.instance.removeEventListener(Commands.onXingBiUpdated, onXingBiUpdated);
         _listening = false;
         _container = null;
      }
   }
}
