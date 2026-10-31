package mmo.pet.pethatchegg
{
   import flash.display.Sprite;
   import mmo.interfaces.IShowPanel;
   
   /**
    * ERA pet/pethatchegg (December 2010; the 家园's 亚比批量孵化器), rebuilt
    * from its decompiled code onto its own artwork (tools/swf_transplant.py
    * --drop-art-abc) so two things could be added: the eggs' names under them
    * (PetReadyHatchEgg) and the eggs' pictures in the list while they hatch
    * (PetHatchMessage). Everything else is the era code as it was.
    */
   [SWF(width="550", height="400", backgroundColor="#666666", frameRate="12")]
   public class PetHatchEgg extends Sprite implements IShowPanel
   {
      
      public static var panel:PetHatchEggPanel;
      
      public static var isShow:Boolean = false;
      
      public function PetHatchEgg()
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
            panel = new PetHatchEggPanel();
            panel.show();
            isShow = true;
         }
      }
   }
}

