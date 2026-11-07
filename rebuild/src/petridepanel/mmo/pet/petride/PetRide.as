package mmo.pet.petride
{
   import flash.display.Sprite;
   import mmo.interfaces.IShowPanel;
   
   public class PetRide extends Sprite implements IShowPanel
   {
      
      public static var panel:PetRidePanel;
      
      public static var isShow:Boolean = false;
      
      public function PetRide()
      {
         super();
      }
      
      public function showPanel() : void
      {
         if(isShow)
         {
            panel.dispose();
         }
         else
         {
            panel = new PetRidePanel();
            panel.show();
            isShow = true;
         }
      }
   }
}

