package mmo.game.parkour.common.panel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.loader.common.datastructures.ResourceObject;
   
   public class ParkourPanelBase extends Sprite implements IShowPanel, IDispose
   {
      
      private var _panel:MovieClip;
      
      private var myResourceObj:ResourceObject;
      
      public function ParkourPanelBase(param1:ResourceObject)
      {
         super();
         this.myResourceObj = param1;
      }
      
      public function showPanel() : void
      {
         var _loc1_:Class = null;
         if(ApplicationDomain.currentDomain.hasDefinition(this.myResourceObj.clsName))
         {
            _loc1_ = ApplicationDomain.currentDomain.getDefinition(this.myResourceObj.clsName) as Class;
            this.showContent(new _loc1_() as MovieClip);
         }
         else
         {
            // aola-revival: the 2013 loader's loadSingleResource (into the current domain, as
            // the later SimpleCLParam with ResDomain(currentDomain) asked) for loadSingleRes.
            SimpleCustomLoader.loadSingleResource(this.myResourceObj.resPath,this.myResourceObj.clsName,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"正在下载，请稍候……",this.showContent);
         }
      }
      
      private function showContent(param1:MovieClip, param2:ApplicationDomain = null) : void
      {
         this._panel = param1;
         addChild(this._panel);
         this.onShowPanel();
      }
      
      final protected function get panel() : MovieClip
      {
         return this._panel;
      }
      
      protected function onShowPanel() : void
      {
         throw new Error("onShowPanel need override");
      }
      
      final protected function showThisPanel() : void
      {
         addEventListener(MouseEvent.CLICK,this.onClick);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnClose" || _loc2_ == "btnclose")
         {
            this.onClickClose();
            this.close();
         }
         else
         {
            this.onClickTarget(_loc2_);
         }
      }
      
      protected function onClickClose() : void
      {
      }
      
      protected function onClickTarget(param1:String) : void
      {
      }
      
      protected function onDispose() : void
      {
      }
      
      final protected function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function dispose() : void
      {
         this.onDispose();
         removeEventListener(MouseEvent.CLICK,this.onClick);
      }
   }
}

