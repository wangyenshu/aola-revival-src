package mmo.scene.yabi
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocYabistudyRevived extends DocSceneBase
   {
      public function DocYabistudyRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new YabistudyRevived();
      }
   }
}
