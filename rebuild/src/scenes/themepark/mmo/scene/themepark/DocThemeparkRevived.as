package mmo.scene.themepark
{
   import mmo.play.scene.DocSceneBase;

   [SWF(width="960", height="560", backgroundColor="#ffffff", frameRate="25")]
   public class DocThemeparkRevived extends DocSceneBase
   {
      public function DocThemeparkRevived()
      {
         super();
      }

      override protected function setScene():void
      {
         this._scene = new ThemeparkRevived();
      }
   }
}
