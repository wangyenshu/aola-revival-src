package mmo.pet.petride
{
   import flash.display.Sprite;

   /**
    * pet/petridepanel (ServiceConfig "PetRideTrannig", 亚比骑乘训练 of 训练官卢卡斯 in the 蓝宝石要塞): the
    * January 2013 module is lost; its copy of 2021, the same panel (a 亚比 of the bag chosen and
    * trained through IRideService.trainPet), compiled on the 2013 libraries and bound to its own art.
    */
   public class DocPetRidePanel extends Sprite
   {
      public function DocPetRidePanel()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [PetRide, PetRidePanel, PetRideTranningPetBriefCard];
      }
   }
}
