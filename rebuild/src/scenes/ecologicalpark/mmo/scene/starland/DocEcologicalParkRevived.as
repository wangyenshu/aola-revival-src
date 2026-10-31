package mmo.scene.starland
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocEcologicalParkRevived extends DocSceneBase
   {
      public function DocEcologicalParkRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new EcologicalParkRevived();
      }
   }
}
