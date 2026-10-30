package mmo.scene.cloudstar1
{
   import mmo.play.scene.DocSceneBase;
   import mmo.play.scene.SceneBase;
   
   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocCloudStar1 extends DocSceneBase
   {
      
      public function DocCloudStar1()
      {
         super();
      }
      
      override protected function setScene() : void
      {
         this._scene = new CloudStar1() as SceneBase;
      }
   }
}

