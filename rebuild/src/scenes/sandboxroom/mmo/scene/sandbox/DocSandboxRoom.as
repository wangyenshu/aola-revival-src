package mmo.scene.sandbox
{
   import mmo.play.scene.DocSceneBase;
   import mmo.play.scene.SceneBase;

   /**
    * The 沙盒 room (scene/sandboxroom, the revival's own; docs/SANDBOX.md).
    * Each load builds a new room, because the room shown is whichever room of
    * a 关卡 pack the 沙盒 is in (SandboxRun.current()), and the scene file may
    * be loaded once and kept.
    */
   [SWF(width="960", height="560", backgroundColor="#1d2a3a", frameRate="25")]
   public class DocSandboxRoom extends DocSceneBase
   {
      public function DocSandboxRoom()
      {
         super();
      }

      override public function get scene():SceneBase
      {
         this._scene = new SandboxRoom();
         return this._scene;
      }

      override protected function setScene():void
      {
         this._scene = new SandboxRoom();
      }
   }
}
