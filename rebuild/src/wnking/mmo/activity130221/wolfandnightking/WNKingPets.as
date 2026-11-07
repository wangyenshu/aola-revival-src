package mmo.activity130221.wolfandnightking
{
   import mmo.common.dialog.NewDialog;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;

   /**
    * REBUILT: the panels' 背包, 治疗 and 远程仓库 buttons. The surviving copy calls the later
    * mmo.common.act_operation.PetFunctionShortcut, which the 2013 libraries lack; these open the
    * January 2013 services instead (ServiceConfig NewPetPackage, PetWareHouse).
    */
   public class WNKingPets
   {
      public static function tryCure():void
      {
         var data:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         if (data.checkPetIsEmpty())
         {
            NewDialog.showMessage("你的背包里没有亚比哦！");
            return;
         }
         if (data.checkAllPetHPIsFull() && data.checkAllPetPPIsFull())
         {
            NewDialog.showMessage("你背包里的亚比已经充满活力，不需要治疗哦！");
            return;
         }
         data.recureAllPet();
      }

      public static function openPetPackage():void
      {
         open("NewPetPackage");
      }

      public static function tryOpenPetStore():void
      {
         open("PetWareHouse");
      }

      private static function open(name:String):void
      {
         ServiceContainer.instance.tryGetService(name, function(svc:IService, o:Object = null):void
         {
            if (svc is IShowPanel) IShowPanel(svc).showPanel();
         });
      }
   }
}
