package mmo.superevolution
{
   import flash.display.Sprite;

   /**
    * REBUILT pet/superevolution (aola-revival): the 超进化机 of its copy of 2015, its code written
    * again for the 2013 libraries and the 亚比 of 2013 (SuperEvolutionPanel).
    */
   public class DocSuperEvolution extends Sprite
   {
      public function DocSuperEvolution()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [SuperEvolutionPanel, EvoPanel, ChoosePetPanel, PetContainer, ItemView, EvolutionMovie, StopClip];
      }
   }
}
