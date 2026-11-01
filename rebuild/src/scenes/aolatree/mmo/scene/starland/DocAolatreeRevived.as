package mmo.scene.starland
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocAolatreeRevived extends DocSceneBase
   {
      public function DocAolatreeRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new AolatreeRevived();
      }
   }
}
