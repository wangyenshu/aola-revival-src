package mmo.scene.library
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocLibraryRevived extends DocSceneBase
   {
      public function DocLibraryRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new LibraryRevived();
      }
   }
}
