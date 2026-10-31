package mmo.scene.temple
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocTemple1Revived extends DocSceneBase
   {
      public function DocTemple1Revived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new Temple1Revived();
      }
   }
}
