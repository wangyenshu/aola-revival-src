package mmo.petUI.service
{
   import flash.display.DisplayObject;
   import flash.text.TextField;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.ui.IPetUIService;
   import mmo.interfaces.pet.ui.PetSkillPanel;
   import mmo.interfaces.pet.ui.PetUIServiceEvent;
   import mmo.petUI.petselect.PetSelectPanel;
   import mmo.revival.RLog;

   /**
    * REBUILT PetUIService (pet/petUIservice; the January 2013 module is lost, the copy under its
    * URL is of 2026 and its 选择亚比 a later drawing). Its pet choice is what panels of the era ask it
    * for: 天赋启迪 (activityres/activity130117/geniusedification, ActGeniusMainPanel's 选择亚比) calls
    * showPackagePetSelectPanel and takes the 亚比 from SELECTPANEL_OK's params.pbi; a 超进化's
    * showSuperEvolutionSelectPanel(races) the same among the 亚比 of those races. The panel is the
    * chooser the 2012 modules share (PetSelectPanel, the art of activityres/breakegg's), its question
    * set for what is asked (请先选择一只亚比, the words of the later module's own chooser, when the caller
    * gives none); 取消 is SELECTPANEL_CLOSE. The other pictures (天赋 icons, skill panels)
    * are not asked for by the 2013 game's modules: none.
    */
   public class PetUIService extends EventDispatcher implements IPetUIService
   {
      private var shown:Sprite;

      public function PetUIService()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      /** param1: the title; a TextField gives its words to the panel's own question instead. */
      public function showPackagePetSelectPanel(param1:DisplayObject = null):Sprite
      {
         if (param1 is TextField) return choose(null, TextField(param1).text, null);
         return choose(null, "请先选择一只亚比", param1);
      }

      /** races: the races (or PetBriefInfo) that may be chosen. */
      public function showSuperEvolutionSelectPanel(param1:Array):Sprite
      {
         var may:Function = function(p:PetBriefInfo):Boolean
         {
            for each (var r:* in param1 || [])
               if ((r is PetBriefInfo && PetBriefInfo(r).id == p.id) || (!(r is PetBriefInfo) && int(r) == p.raceId)) return true;
            return false;
         };
         return choose(may, "选择你要超进化的亚比：", null);
      }

      private static function myPets():Array
      {
         try { return (ServiceContainer.getService(IPetDataService) as IPetDataService).getMyPets() || []; }
         catch (e:Error) { RLog.error("petui: pets", e); }
         return [];
      }

      private function choose(may:Function, question:String, title:DisplayObject):Sprite
      {
         close(false);
         var panel:PetSelectPanel = new PetSelectPanel(myPets(), may, question, title, function(p:PetBriefInfo):void
         {
            close(false);
            dispatchEvent(new PetUIServiceEvent(PetUIServiceEvent.SELECTPANEL_OK, {pbi: p}));
         }, function():void { close(true); });
         panel.name = "petSelectPanel";
         shown = panel;
         ModalDialogManager.getInstance().addModalDialog(panel, AlignType.MIDDLE_CENTER, PanelEffect.NONE, true);
         dispatchEvent(new PetUIServiceEvent(PetUIServiceEvent.SELECTPANEL_OPEN, {panel: panel}));
         return panel;
      }

      private function close(tell:Boolean):void
      {
         if (shown != null) ModalDialogManager.getInstance().removeModalDialog(shown);
         shown = null;
         if (tell) dispatchEvent(new PetUIServiceEvent(PetUIServiceEvent.SELECTPANEL_CLOSE, {}));
      }

      public function getGeniusIconByInds(param1:Array):MovieClip { return null; }

      public function getSkillUIById(param1:int):PetSkillPanel { return null; }

      public function getSkillUIByInfo(param1:Object):PetSkillPanel { return null; }

      public function getGeniusStarsByInds(param1:int):Sprite { return null; }

      public function getGeniusIconByName(param1:String):MovieClip { return null; }

      public function getGeniusIconByPDI(param1:PetDetailedInfo):MovieClip { return null; }
   }
}
