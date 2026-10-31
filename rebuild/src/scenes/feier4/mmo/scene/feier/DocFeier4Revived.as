package mmo.scene.feier
{
   import mmo.play.scene.DocSceneBase;

   /** LATER scene/feier4 (火山口): document class of the cut-down code. */
   public class DocFeier4Revived extends DocSceneBase
   {
      public function DocFeier4Revived()
      {
         super();
      }

      override protected function setScene():void
      {
         _scene = new Feier4Revived();
      }
   }
}
