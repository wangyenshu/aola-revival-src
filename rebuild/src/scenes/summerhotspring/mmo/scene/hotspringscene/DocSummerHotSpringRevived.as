package mmo.scene.hotspringscene
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocSummerHotSpringRevived extends DocSceneBase
   {
      public function DocSummerHotSpringRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new SummerHotSpringRevived();
      }
   }
}
