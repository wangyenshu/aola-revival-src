package mmo.family.common
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.CanCloseSprite;
   import mmo.interfaces.ICatalogManager;
   import mmo.interfaces.IService;
   import mmo.interfaces.family.*;
   import mmo.interfaces.family.IFamilyService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FamilyService. Module family/familyservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.family.IFamilyService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FamilyService extends EventDispatcher implements IFamilyService
   {
      public function FamilyService()
      {
         super();
      }

      public function getMyFamiliesPanel() : CanCloseSprite
      {
         RLog.stub("FamilyService.getMyFamiliesPanel");
         return null;
      }

      public function hideFamilyQueryPanel() : void
      {
         RLog.stub("FamilyService.hideFamilyQueryPanel");
      }

      public function showModalFamilyCard(param1:int) : void
      {
         RLog.stub("FamilyService.showModalFamilyCard");
      }

      public function showFamilySearchResult(param1:Object) : void
      {
         RLog.stub("FamilyService.showFamilySearchResult");
      }

      public function showFamilyMemberView(param1:int) : void
      {
         RLog.stub("FamilyService.showFamilyMemberView");
      }

      public function hideFamilySearchResult() : void
      {
         RLog.stub("FamilyService.hideFamilySearchResult");
      }

      public function setWord(param1:Sprite, param2:String) : void
      {
         RLog.stub("FamilyService.setWord");
      }

      public function getBadge(param1:int, param2:int = -1, param3:String = "") : Sprite
      {
         RLog.stub("FamilyService.getBadge");
         return null;
      }

      public function joinFamily(param1:int, param2:int) : void
      {
         RLog.stub("FamilyService.joinFamily");
      }

      public function getFamilyComityIcon(param1:int, param2:Boolean = true, param3:int = -1) : DisplayObject
      {
         RLog.stub("FamilyService.getFamilyComityIcon");
         return null;
      }

      public function showFamilyCard(param1:int, param2:int = 0) : void
      {
         RLog.stub("FamilyService.showFamilyCard");
      }

      public function showFamilyCardByName(param1:String, param2:int = 0) : void
      {
         RLog.stub("FamilyService.showFamilyCardByName");
      }

      public function familyInvite(param1:int, param2:String) : void
      {
         RLog.stub("FamilyService.familyInvite");
      }

      public function applyColor(param1:Sprite, param2:int) : void
      {
         RLog.stub("FamilyService.applyColor");
      }

      public function getBuyFurnitureCatalog(param1:int) : ICatalogManager
      {
         RLog.stub("FamilyService.getBuyFurnitureCatalog");
         return null;
      }

      public function displayFamilyComityIcon(param1:DisplayObject, param2:int, param3:Boolean = true) : void
      {
         RLog.stub("FamilyService.displayFamilyComityIcon");
      }

      public function showFamilyQueryPanel(param1:String = "", param2:String = "") : void
      {
         RLog.stub("FamilyService.showFamilyQueryPanel");
      }

   }
}
