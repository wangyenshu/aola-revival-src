package mmo.petUI.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.ui.*;
   import mmo.interfaces.pet.ui.IPetUIService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetUIService. Module pet/petUIservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.ui.IPetUIService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetUIService extends EventDispatcher implements IPetUIService
   {
      public function PetUIService()
      {
         super();
      }

      public function getGeniusIconByInds(param1:Array) : MovieClip
      {
         RLog.stub("PetUIService.getGeniusIconByInds");
         return null;
      }

      public function getSkillUIById(param1:int) : PetSkillPanel
      {
         RLog.stub("PetUIService.getSkillUIById");
         return null;
      }

      public function showPackagePetSelectPanel(param1:DisplayObject = null) : Sprite
      {
         RLog.stub("PetUIService.showPackagePetSelectPanel");
         return null;
      }

      public function getSkillUIByInfo(param1:Object) : PetSkillPanel
      {
         RLog.stub("PetUIService.getSkillUIByInfo");
         return null;
      }

      public function getGeniusStarsByInds(param1:int) : Sprite
      {
         RLog.stub("PetUIService.getGeniusStarsByInds");
         return null;
      }

      public function getGeniusIconByName(param1:String) : MovieClip
      {
         RLog.stub("PetUIService.getGeniusIconByName");
         return null;
      }

      public function showSuperEvolutionSelectPanel(param1:Array) : Sprite
      {
         RLog.stub("PetUIService.showSuperEvolutionSelectPanel");
         return null;
      }

      public function getGeniusIconByPDI(param1:PetDetailedInfo) : MovieClip
      {
         RLog.stub("PetUIService.getGeniusIconByPDI");
         return null;
      }

      public function init() : void
      {
         RLog.stub("PetUIService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
