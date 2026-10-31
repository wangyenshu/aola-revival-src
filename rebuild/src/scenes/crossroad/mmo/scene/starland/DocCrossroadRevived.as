package mmo.scene.starland
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocCrossroadRevived extends DocSceneBase
   {
      public function DocCrossroadRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new CrossroadRevived();
      }
   }
}
