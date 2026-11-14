package mmo.pet.petitem
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.revival.RLog;

   /**
    * REBUILT pet/petitem (ServiceConfig "PetItem", mmo.pet.petitem.PetItem, IShowPanel):
    * the 亚比道具 page of the 亚比背包, where the bag's items are used on the 亚比 it
    * shows. The January 2013 module is lost; its later copy (the only one left) is
    * of the later libraries, and gives this one its art (the page, symbol 668, and
    * its squares, 706). The code is new: PetItemPanel lists the items, PetItemUse
    * asks and sends 14_12 (server: petitems.ts).
    *
    * The pet bag (rebuilt pet/petpackage) puts the page in place of its 信息 page
    * (createPage); showPanel opens the bag on it.
    */
   public class PetItem extends Sprite implements IShowPanel
   {
      public function PetItem()
      {
         super();
      }

      /** The page for the bag: petId() gives the id of the 亚比 it shows (or -1). */
      public function createPage(petId:Function):DisplayObject
      {
         var p:PetItemPanel = new PetItemPanel();
         p.init(petId);
         return p;
      }

      /**
       * The page's art alone for another page of the bag (its 装扮 tab, ClothPage): the
       * twenty squares p_0…p_19 and the pager (prevBtn, nextBtn, pageTxt), nothing in them.
       */
      public function createGrid():DisplayObject
      {
         return new PetItemPanel();
      }

      /** One square of the page alone (txtNum, mcRedDot), for what another page puts in it. */
      public function createSquare():Sprite
      {
         return new ItemView(null, null);
      }

      public function showPanel():void
      {
         ServiceContainer.instance.tryGetService("NewPetPackage", function(svc:IService, o:Object = null):void
         {
            try
            {
               IShowPanel(svc).showPanel();
               if ("showItemPage" in svc) Object(svc).showItemPage();
            }
            catch (e:Error) { RLog.error("petitem open bag", e); }
         });
      }
   }
}
