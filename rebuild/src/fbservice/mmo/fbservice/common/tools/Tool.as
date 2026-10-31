package mmo.fbservice.common.tools
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   import mmo.loader.layer.LayerManager;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class Tool
   {
      
      private static const stageW:int = 960;
      
      private static const stageH:int = 560;
      
      private static var _instence:Tool = null;
      
      private var transparency:Sprite = null;
      
      public function Tool()
      {
         super();
         _instence = this;
      }
      
      public static function get instence() : Tool
      {
         if(null == _instence)
         {
            _instence = new Tool();
         }
         return _instence;
      }
      
      public static function getTeamKey() : String
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc2_:TeamInfo = _loc1_.getMyTeam();
         if(null == _loc2_)
         {
            return SocketClient.instance.myUserName;
         }
         return _loc2_.key;
      }
      
      public function addTransparency(param1:Number = 0.01) : void
      {
         if(null != this.transparency)
         {
            return;
         }
         this.transparency = new Sprite();
         this.transparency.graphics.beginFill(16777215,param1);
         this.transparency.graphics.drawRect(0,0,stageW,stageH);
         this.transparency.graphics.endFill();
         LayerManager.getBaseTop().addChild(this.transparency);
      }
      
      public function cleanTransparency() : void
      {
         if(null == this.transparency)
         {
            return;
         }
         LayerManager.getBaseTop().removeChild(this.transparency);
         this.transparency = null;
      }
      
      public function hitTestCircle(param1:Point, param2:Point, param3:Number) : Boolean
      {
         var _loc4_:Number = param1.x - param2.x;
         var _loc5_:Number = param1.y - param2.y;
         var _loc6_:Number = _loc4_ * _loc4_ + _loc5_ * _loc5_;
         return _loc6_ <= param3 * param3 ? true : false;
      }
      
      public function hitTestCircleObject(param1:Sprite) : Boolean
      {
         var _loc2_:PlayerBase = PlayerManager.getInstance().myPlayer;
         if(null == _loc2_ || null == param1)
         {
            return false;
         }
         var _loc3_:Point = new Point(_loc2_.x,_loc2_.y);
         var _loc4_:Point = new Point(param1.x,param1.y);
         var _loc5_:Number = param1.width / 2;
         return this.hitTestCircle(_loc3_,_loc4_,_loc5_);
      }
      
      public function getClass(param1:String) : Class
      {
         if(ApplicationDomain.currentDomain.hasDefinition(param1))
         {
            return ApplicationDomain.currentDomain.getDefinition(param1) as Class;
         }
         var _loc2_:ApplicationDomain = this.getSceneApplicationDomain();
         if(_loc2_.hasDefinition(param1))
         {
            return _loc2_.getDefinition(param1) as Class;
         }
         return null;
      }
      
      public function getSceneApplicationDomain() : ApplicationDomain
      {
         return SceneManager.getInstance().loadedSceneInfo.applicationDomain;
      }
   }
}

