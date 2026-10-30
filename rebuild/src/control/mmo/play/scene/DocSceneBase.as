package mmo.play.scene
{
   import flash.display.MovieClip;

   /** REBUILT. Document class every scene SWF extends; subclasses override setScene(). */
   public class DocSceneBase extends MovieClip
   {
      protected var _scene:SceneBase;

      public function DocSceneBase()
      {
         super();
      }

      public function get scene():SceneBase
      {
         if (this._scene == null)
         {
            this.setScene();
         }
         return this._scene;
      }

      protected function setScene():void
      {
         throw new Error("setScene() is implemented as Virtual Method!");
      }
   }
}
