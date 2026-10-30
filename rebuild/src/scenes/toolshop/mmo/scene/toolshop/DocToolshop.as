package mmo.scene.toolshop
{
   import mmo.play.scene.DocSceneBase;
   
   [SWF(width="960", height="560", backgroundColor="#999999", frameRate="25")]
   public class DocToolshop extends DocSceneBase
   {
      
      public function DocToolshop()
      {
         super();
      }
      
      override protected function setScene() : void
      {
         this._scene = new Toolshop();
      }
   }
}

