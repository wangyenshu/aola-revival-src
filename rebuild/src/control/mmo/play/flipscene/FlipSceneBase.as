package mmo.play.flipscene
{
   import mmo.play.flipscene.helper.flip.FlipHelper;
   import mmo.play.flipscene.helper.player.FlipPlayerGenerator;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.helper.player.IPlayerGenerator;

   /**
    * REBUILT. An upside-down scene (海文3, 海文4): the scene's layers are
    * turned over once the room is joined, so players walk on the ceiling;
    * their name plates stay readable (FlipPlayerGenerator).
    */
   public class FlipSceneBase extends SceneBase
   {
      private var _flipHelper:FlipHelper;

      public function FlipSceneBase(x:int, y:int)
      {
         super(x, y);
      }

      public function get flipHelper():FlipHelper
      {
         return _flipHelper;
      }

      override public function getPlayerGenerator():IPlayerGenerator
      {
         return new FlipPlayerGenerator();
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         _flipHelper = new FlipHelper();
         _flipHelper.addLayer(backGround);
         _flipHelper.addLayer(foreGround);
         _flipHelper.addLayer(container);
         _flipHelper.addLayer(obStruction);
         _flipHelper.addLayer(topGround);
         _flipHelper.activeFlip();
      }

      override protected function onLeaveRoom():void
      {
         super.onLeaveRoom();
         if (_flipHelper) _flipHelper.dispose();
         _flipHelper = null;
      }
   }
}
