package mmo.spacetime.common
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   
   public class ControlBarManager
   {
      
      private static var _instance:ControlBarManager = null;
      
      private var barContainer:Sprite = null;
      
      private var bar:Sprite = null;
      
      private var isCommonMode:Boolean = false;
      
      public function ControlBarManager()
      {
         super();
      }
      
      public static function get instance() : ControlBarManager
      {
         if(null == _instance)
         {
            _instance = new ControlBarManager();
         }
         return _instance;
      }
      
      public function switchToSpacetimeMode() : void
      {
         var domain:ApplicationDomain;
         DisplayUtil.stopAndRemove(this.barContainer);
         LayerManager.getBaseControl().visible = false;
         this.barContainer = new Sprite();
         SceneManager.getInstance().loadedSceneInfo.scene.topGround.addChild(this.barContainer);
         domain = ApplicationDomain.currentDomain;
         if(domain.hasDefinition("mmo.spacetime.ControlBar"))
         {
            this.addControlBar();
         }
         else
         {
            ResScheduler.getResource("spacetime/spacetimeres",function(param1:*):void
            {
               addControlBar();
            });
         }
         this.isCommonMode = false;
      }
      
      public function swithcToCommonMode() : void
      {
         if(this.isCommonMode)
         {
            return;
         }
         this.resetControlBar();
         this.isCommonMode = true;
      }
      
      private function resetControlBar() : void
      {
         if(!LayerManager.getBaseControl().visible || null != this.barContainer)
         {
            LayerManager.getBaseControl().visible = true;
            if(null != this.bar)
            {
               this.bar.removeEventListener(MouseEvent.CLICK,this.onClickControlBar);
               this.bar = null;
            }
            DisplayUtil.stopAndRemove(this.barContainer);
            this.barContainer = null;
         }
      }
      
      private function addControlBar() : void
      {
         if(null == this.barContainer)
         {
            return;
         }
         var _loc1_:Class = getDefinitionByName("mmo.spacetime.ControlBar") as Class;
         this.bar = new _loc1_() as Sprite;
         this.bar.addEventListener(MouseEvent.CLICK,this.onClickControlBar);
         this.barContainer.addChild(this.bar);
      }
      
      private function onClickControlBar(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.target as SimpleButton;
         if(_loc2_ == null)
         {
            return;
         }
         switch(_loc2_.name)
         {
            case "btnPet":
               param1.stopImmediatePropagation();
               this.showPetPanel();
               break;
            case "btnLeave":
               param1.stopImmediatePropagation();
               SceneManager.getInstance().loadPreviousScene();
         }
      }
      
      private function showPetPanel() : void
      {
         ServiceContainer.instance.tryGetService("PetPackage",function(param1:IShowPanel, param2:Object):void
         {
            param1.showPanel();
         });
      }
   }
}

