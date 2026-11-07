package mmo.scene.youanmingzhou
{
   import mmo.play.scene.DocSceneBase;

   /** REBUILT: document class of scene/youanmingzhou2 (幽冥大殿). */
   public class DocYouanmingzhou2Revived extends DocSceneBase
   {
      public function DocYouanmingzhou2Revived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new Youanmingzhou2Revived();
      }
   }
}
