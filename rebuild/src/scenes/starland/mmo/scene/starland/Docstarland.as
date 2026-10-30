package mmo.scene.starland
{
   import mmo.play.scene.DocSceneBase;

   /**
    * REBUILT document class of scene/starland.swf (奥拉广场).
    *
    * The January 2013 starland.swf is lost: the live file is a much later
    * redesign. The artwork here is the July 2012 square, kept in
    * bigscene/starlandcopy.swf (the copy the newbie quest used); see
    * Starland.as for which parts are reconstructed.
    */
   public class Docstarland extends DocSceneBase
   {
      public function Docstarland()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new Starland();
      }
   }
}
