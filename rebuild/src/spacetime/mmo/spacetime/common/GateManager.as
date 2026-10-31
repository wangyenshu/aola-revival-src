package mmo.spacetime.common
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.SpacetimeClient;
   import mmo.framework.comm.SpacetimeTClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   
   public class GateManager implements IDispose
   {
      
      private static var _instance:GateManager = null;
      
      private var gateFb:MovieClip = null;
      
      private var gateBoss:MovieClip = null;
      
      private var currentGate:MovieClip = null;
      
      private var isDisposed:Boolean = false;
      
      private var isGateOpening:Boolean = false;
      
      public function GateManager()
      {
         super();
         SocketClient.instance.addEventListener(SpacetimeClient.cmdGoNextFloor,this.onlistenNextFloor);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdGoNextFloor,this.onlistenNextFloor);
      }
      
      public static function get instance() : GateManager
      {
         if(null == _instance)
         {
            _instance = new GateManager();
         }
         return _instance;
      }
      
      public function initGate(param1:Boolean) : void
      {
         var domain:ApplicationDomain;
         var isBossGate:Boolean = param1;
         this.isDisposed = false;
         domain = ApplicationDomain.currentDomain;
         if(domain.hasDefinition(ConstType.RES_PREFIX + "Gatefb"))
         {
            this.gateInit(isBossGate);
         }
         else
         {
            ResScheduler.getResource("spacetime/spacetimeres",function(param1:*):void
            {
               if(!isDisposed)
               {
                  gateInit(isBossGate);
               }
            });
         }
      }
      
      public function openDoor() : void
      {
         this.currentGate.gotoAndPlay(1);
         var _loc1_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("removedoor") as MovieClip;
         _loc1_.visible = false;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChildAt(this.currentGate,0);
      }
      
      public function dispose() : void
      {
         if(null != this.currentGate)
         {
            this.currentGate.removeEventListener(MouseEvent.CLICK,this.onGateClick);
            this.currentGate = null;
         }
         if(null != this.gateFb || null != this.gateBoss)
         {
            DisplayUtil.stopAndRemove(this.gateFb);
            DisplayUtil.stopAndRemove(this.gateBoss);
            this.gateFb = null;
            this.gateBoss = null;
         }
         this.isDisposed = true;
      }
      
      private function onlistenNextFloor(param1:SocketClientEvent) : void
      {
         this.isGateOpening = false;
      }
      
      private function gateInit(param1:Boolean) : void
      {
         if(null != this.currentGate)
         {
            this.currentGate.removeEventListener(MouseEvent.CLICK,this.onGateClick);
            if(null != this.currentGate.parent)
            {
               this.currentGate.parent.removeChild(this.currentGate);
            }
         }
         this.currentGate = param1 ? this.bossGateInit() : this.fbGateInit();
         this.currentGate.addEventListener(MouseEvent.CLICK,this.onGateClick);
      }
      
      private function fbGateInit() : MovieClip
      {
         var _loc1_:Class = null;
         if(this.gateFb == null)
         {
            _loc1_ = getDefinitionByName(ConstType.RES_PREFIX + "Gatefb") as Class;
            this.gateFb = new _loc1_() as MovieClip;
            this.gateFb.stop();
         }
         return this.gateFb;
      }
      
      private function bossGateInit() : MovieClip
      {
         var _loc1_:Class = null;
         if(this.gateBoss == null)
         {
            _loc1_ = getDefinitionByName(ConstType.RES_PREFIX + "Gateboss") as Class;
            this.gateBoss = new _loc1_() as MovieClip;
            this.gateBoss.stop();
         }
         return this.gateBoss;
      }
      
      private function onGateClick(param1:MouseEvent) : void
      {
         var _loc3_:ITeamService = null;
         var _loc2_:String = param1.target.name;
         if(!this.isGateOpening && "btnGate" == _loc2_)
         {
            this.isGateOpening = true;
            param1.stopImmediatePropagation();
            _loc3_ = ServiceContainer.getService(ITeamService) as ITeamService;
            if(_loc3_.getMyTeam() != null)
            {
               SpacetimeTClient.instence.nextFloor();
            }
            else
            {
               SpacetimeClient.instence.nextFloor();
            }
         }
      }
   }
}

