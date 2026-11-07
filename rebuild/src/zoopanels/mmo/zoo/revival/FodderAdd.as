package mmo.zoo.revival
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;

   /** REBUILT (the era AddFodderPanel's art): how many of a thing go into the 饲料机. */
   public class FodderAdd extends MovieClip
   {
      public var btnCancel:SimpleButton;
      public var btnClose:SimpleButton;
      public var btnNext:SimpleButton;
      public var btnOk:SimpleButton;
      public var btnPrev:SimpleButton;
      public var ct:MovieClip;
      public var txtDesc:TextField;
      public var txtName:TextField;
      public var txtNumber:TextField;
      public var txtOneDesc:TextField;
      public var txtTip:TextField;

      private var points:int;
      private var most:int;
      private var done:Function;

      /** most: as many as fill the machine (and no more than one has); done(n). */
      public function FodderAdd(u:UserItem, points:int, fill:int, done:Function)
      {
         super();
         stop();
         this.points = points;
         this.most = Math.max(1, Math.min(u.available, fill));
         this.done = done;
         txtName.text = u.material.name;
         txtNumber.restrict = "0-9";
         txtNumber.text = "1";
         txtOneDesc.text = "说明：每个" + u.material.name + "可以转化为" + points + "点饲料";
         if (txtTip != null) txtTip.text = "";
         try
         {
            var v:DisplayObject = (ServiceContainer.getService(IItemService) as IItemService).getView(u.materialId);
            if (v != null && ct != null)
            {
               DisplayUtil.scaleDisplay(v, 60, 60);
               ct.addChild(v);
            }
         }
         catch (e:Error) {}
         btnPrev.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { set(count - 1); });
         btnNext.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { set(count + 1); });
         txtNumber.addEventListener(Event.CHANGE, function(e:Event):void { set(int(txtNumber.text)); });
         btnOk.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { var n:int = count; close(); done(n); });
         btnCancel.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         set(1);
      }

      private function get count():int
      {
         return int(txtNumber.text);
      }

      private function set(n:int):void
      {
         n = Math.max(1, Math.min(most, n));
         txtNumber.text = String(n);
         txtDesc.text = "可添加" + n * points + "点饲料";
         btnPrev.alpha = n > 1 ? 1 : 0.4;
         btnNext.alpha = n < most ? 1 : 0.4;
      }

      private function close():void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}
