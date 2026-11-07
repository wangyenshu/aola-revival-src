package mmo.treemanager.treepanel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;

   /**
    * REBUILT 守护亚比 (yz/panel_res of April 2012, its code on its art, symbol 57): the 亚比 of
    * the bag; one chosen guards the tree, 取消守护亚比 none. onSet(petId): 0 none, -2 closed.
    */
   public class GuardYabiPanel extends MovieClip
   {
      private static const XS:Array = [43.2, 184.8, 43.2, 184.8, 43.2, 184.8];
      private static const YS:Array = [145.85, 145.85, 225.95, 225.95, 303.65, 303.65];

      public var btnOk:SimpleButton;
      public var btnClose:SimpleButton;
      public var mcCancel:MovieClip;

      private var cards:Array = [];
      private var petId:int;
      private var onSet:Function;

      public function GuardYabiPanel(current:int = 0, onSet:Function = null)
      {
         super();
         name = "guardYabiPanel";
         petId = current;
         this.onSet = onSet;
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { done(-2); });
         btnOk.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { done(mcCancel != null && mcCancel.currentFrame == 2 ? 0 : Math.max(0, petId)); });
         if (mcCancel != null)
         {
            mcCancel.gotoAndStop(1);
            mcCancel.buttonMode = true;
            mcCancel.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               mcCancel.gotoAndStop(3 - mcCancel.currentFrame);
               if (mcCancel.currentFrame == 2) choose(-1);
            });
         }
         var pets:Array = [];
         try { pets = (ServiceContainer.getService("PetDataService") as IPetDataService).getMyPets(); } catch (err:Error) {}
         for (var i:int = 0; i < pets.length && i < XS.length; i++)
         {
            var c:PetBriefCard = new PetBriefCard(pets[i] as PetBriefInfo);
            c.x = XS[i];
            c.y = YS[i];
            c.name = "ps" + i;
            c.addEventListener(MouseEvent.CLICK, onCard);
            cards.push(c);
            addChild(c);
         }
         for (i = 0; i < cards.length; i++) if (PetBriefCard(cards[i]).petInfo.id == current) choose(i);
         // Taken away by other means (another panel clearing the modals): as closed.
         addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void { done(-2); });
      }

      private function onCard(e:MouseEvent):void
      {
         if (mcCancel != null) mcCancel.gotoAndStop(1);
         choose(int(String(e.currentTarget.name).charAt(2)));
      }

      private function choose(i:int):void
      {
         for (var k:int = 0; k < cards.length; k++) PetBriefCard(cards[k]).setOnClick(k == i);
         petId = i >= 0 ? PetBriefCard(cards[i]).petInfo.id : 0;
      }

      private function done(id:int):void
      {
         var f:Function = onSet;
         onSet = null;
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (f != null) f(id);
      }
   }
}
