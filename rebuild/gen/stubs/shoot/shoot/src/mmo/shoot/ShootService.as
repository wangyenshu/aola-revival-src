package mmo.shoot
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.changeable.*;
   import mmo.interfaces.changeable.IChangeableCollection;
   import mmo.interfaces.material.*;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.shoot.*;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.data.ShootCard;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.shoot.handler.IShootTargetHandler;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ShootService. Module shoot/shoot.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.shoot.IShootService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ShootService extends EventDispatcher implements IShootService
   {
      private var _shootable:Boolean = false;
      private var _isReady:Boolean = false;
      private var _materialType:int = 0;
      public function ShootService()
      {
         super();
      }

      public function get shootable() : Boolean
      {
         RLog.stub("ShootService.shootable");
         return this._shootable;
      }

      public function shootReady(param1:int, param2:DisplayObject = null, param3:Boolean = true) : void
      {
         RLog.stub("ShootService.shootReady");
      }

      public function getCard(param1:int) : ShootCard
      {
         RLog.stub("ShootService.getCard");
         return null;
      }

      public function cardFilter(param1:Array, param2:String = "该射击卡暂时不能使用！") : void
      {
         RLog.stub("ShootService.cardFilter");
      }

      public function unReady() : void
      {
         RLog.stub("ShootService.unReady");
      }

      public function getCardView(param1:int) : Sprite
      {
         RLog.stub("ShootService.getCardView");
         return null;
      }

      public function shootReadWithoutIcon(param1:int, param2:Boolean = true) : void
      {
         RLog.stub("ShootService.shootReadWithoutIcon");
      }

      public function getFilterNotice() : String
      {
         RLog.stub("ShootService.getFilterNotice");
         return "";
      }

      public function registerDefaultTarget(param1:TargetInfo) : void
      {
         RLog.stub("ShootService.registerDefaultTarget");
      }

      public function setIsImmuneFromEffect(param1:Boolean) : void
      {
         RLog.stub("ShootService.setIsImmuneFromEffect");
      }

      public function set shootable(param1:Boolean) : void
      {
         this._shootable = param1;
      }

      public function removeCardFilter() : void
      {
         RLog.stub("ShootService.removeCardFilter");
      }

      public function registerTarget(param1:IShootTargetHandler) : void
      {
         RLog.stub("ShootService.registerTarget");
      }

      public function removeTarget(param1:int, param2:String) : void
      {
         RLog.stub("ShootService.removeTarget");
      }

      public function get isReady() : Boolean
      {
         RLog.stub("ShootService.isReady");
         return this._isReady;
      }

      public function getFilterArray() : Array
      {
         RLog.stub("ShootService.getFilterArray");
         return [];
      }

      public function getShootButton() : Sprite
      {
         RLog.stub("ShootService.getShootButton");
         return null;
      }

      public function setReplaceEffectById(param1:int) : void
      {
         RLog.stub("ShootService.setReplaceEffectById");
      }

      public function clearTarget() : void
      {
         RLog.stub("ShootService.clearTarget");
      }

      public function shoot(param1:TargetInfo) : void
      {
         RLog.stub("ShootService.shoot");
      }

      public function get materialType() : int
      {
         RLog.stub("ShootService.materialType");
         return this._materialType;
      }

      public function getView(param1:int) : DisplayObject
      {
         RLog.stub("ShootService.getView");
         return null;
      }

      public function getMaterialsMap() : Object
      {
         RLog.stub("ShootService.getMaterialsMap");
         return {};
      }

      public function hasMaterial(param1:int) : Boolean
      {
         RLog.stub("ShootService.hasMaterial");
         return false;
      }

      public function getMyMaterials() : Array
      {
         RLog.stub("ShootService.getMyMaterials");
         return [];
      }

      public function getMyMaterialById(param1:int) : UserMaterial
      {
         RLog.stub("ShootService.getMyMaterialById");
         return null;
      }

      public function getNewUserMaterial(param1:int, param2:int, param3:int) : UserMaterial
      {
         RLog.stub("ShootService.getNewUserMaterial");
         return null;
      }

      public function getMaterialById(param1:int) : Material
      {
         RLog.stub("ShootService.getMaterialById");
         return null;
      }

      public function init() : void
      {
         RLog.stub("ShootService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      public function addObject(param1:IChangeableObject) : void
      {
         RLog.stub("ShootService.addObject");
      }

      public function removeObject(param1:IChangeableObject) : void
      {
         RLog.stub("ShootService.removeObject");
      }

      public function getObjects() : Array
      {
         RLog.stub("ShootService.getObjects");
         return [];
      }

   }
}
