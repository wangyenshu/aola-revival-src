package mmo.thinktower
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.icon.IIconService;
   import mmo.interfaces.thinktower.IThinkTower;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.thinktower.interact.Iinteract;
   import mmo.thinktower.interact.InteractFactory;
   
   /**
    * LATER thinktower/thinktowerservice (ThinkTowerService, the 念之塔 of 风暴星系: 黑暗念之塔), its code
    * decompiled and compiled against the 2013 interfaces, on its art (btnExitHall). The 2011–12
    * module is lost; the seals' scenes of game/ (scene/thinktowerofwater, …fire, …ice, …thunder
    * and …think, 2011–12) ask it for their interactions (TowerInteractType), and 幽冥大殿 for its
    * panel (thinktower/enterpanel). Changed: setControlBarMode for the rebuilt control bar.
    */
   public class ThinkTowerService extends EventDispatcher implements IThinkTower
   {
      
      public static const CONTROL_POINTS:Array = [new Point(8.25,505.05),new Point(128.55,505.05)];
      
      private var btns:Array = null;
      
      private var btnPet:SimpleButton = null;
      
      private var btnLeave:SimpleButton = null;
      
      private var isClicking:Boolean = false;
      
      private var interacts:Array = [];
      
      private var iceCount:int = 0;
      
      public function ThinkTowerService()
      {
         super();
      }
      
      public function setSceneInteract(param1:int, param2:Array, param3:Function) : void
      {
         var _loc4_:Iinteract = InteractFactory.getInstance.getInteract(param1);
         _loc4_.initInterrace(param2,param3);
         this.interacts.push(_loc4_);
      }
      
      public function showEnterPanel() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("thinktower/enterpanel",this.onGet,"mmo.thinktower.panel.EnterPanel");
      }
      
      private function onGet(param1:Sprite) : void
      {
         ProgressFullSprite.close();
         ModalDialogManager.getInstance().addModalDialog(param1);
         ProgressFullSprite.show();
      }
      
      /**
       * In a seal of the tower the map and the icons are put away and the 离开 of the tower stands
       * where the map was (the later module took them from its own control bar, "controlBar" with
       * btnMap and blue_icon: the rebuilt bar's map is btnMap).
       */
      public function setControlBarMode(param1:Boolean) : void
      {
         var left:IIconService = ServiceContainer.getService("IconServiceLeftTop") as IIconService;
         var right:IIconService = ServiceContainer.getService("IconServiceRightTop") as IIconService;
         var layer:DisplayObjectContainer = LayerManager.getBaseControl();
         var map:DisplayObject = find(layer, "btnMap");
         if (map != null) map.visible = !param1;
         var old:DisplayObject = layer.getChildByName("btnexit");
         if (old != null) layer.removeChild(old);
         if (left != null) left.setAllVisable(!param1);
         if (right != null) right.setAllVisable(!param1);
         if (!param1) return;
         var exit:MovieClip = new btnExitHall() as MovieClip;
         exit.name = "btnexit";
         exit.buttonMode = true;
         exit.x = CONTROL_POINTS[0].x;
         exit.y = CONTROL_POINTS[0].y;
         exit.addEventListener(MouseEvent.CLICK, this.onClickExit);
         TipsManager.getInstance().addTips(exit, "离开念之塔");
         layer.addChild(exit);
      }

      private static function find(into:DisplayObjectContainer, name:String):DisplayObject
      {
         if (into == null) return null;
         var d:DisplayObject = into.getChildByName(name);
         if (d != null) return d;
         for (var i:int = 0; i < into.numChildren; i++)
         {
            var c:DisplayObjectContainer = into.getChildAt(i) as DisplayObjectContainer;
            if (c == null) continue;
            d = find(c, name);
            if (d != null) return d;
         }
         return null;
      }

      private function onClickExit(param1:MouseEvent) : void
      {
         this.leave();
      }
      
      private function leave() : void
      {
         SceneManager.getInstance().loadScene("youanmingzhou2");
      }
      
      public function dispose() : void
      {
         var _loc1_:Iinteract = null;
         while(this.interacts.length > 0)
         {
            _loc1_ = this.interacts.pop();
            _loc1_.dispose();
         }
         this.iceCount = 0;
      }
      
      public function get icecount() : int
      {
         return this.iceCount;
      }
      
      public function set icecount(param1:int) : *
      {
         this.iceCount = param1;
      }
   }
}

