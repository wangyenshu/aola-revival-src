package mmo.play
{
   import flash.display.Sprite;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.play.player.movable.MovableEvent;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.play.scene.DocSceneBase;
   import mmo.play.scene.FBSceneBase;
   import mmo.play.scene.FBSceneInfo;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.player.dressily.Dressily;
   import mmo.play.player.dressily.DressilyEvent;
   import mmo.play.player.dressily.IDressily;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.strategy.IMovingStrategy;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.movable.strategy.RoundPointStrategy;
   import mmo.play.player.movable.strategy.StandBehindStrategy;
   import mmo.play.player.movable.strategy.FollowSlowlyStrategy;
   import mmo.play.flipscene.FlipSceneBase;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.date.ActDateUtils;
   import mmo.play.action.ActionHelper;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.RefuseInviteHelper;
   import mmo.play.bigscene.event.BigSceneEvent;
   import mmo.play.player.sceneplayer.observer.UserCardObserver;
   import mmo.play.flipscene.helper.flip.FlipHelper;
   import mmo.play.flipscene.helper.player.FlipPlayerGenerator;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.observer.IPlayerObserver;
   import mmo.play.player.sceneplayer.observer.MyPlayerObserver;
   import mmo.play.scene.DocGameBase;
   import mmo.play.scene.SceneCommandStep;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.play.scene.helper.player.DefaultPlayerGenerator;
   import mmo.play.scene.helper.player.IPlayerGenerator;
   import mmo.play.bigscene.BigSceneBase;
   import mmo.play.scene.helper.cache.AutomaticCacheChecker;
   import mmo.play.activity.framework.util.LinkUtil;

   /**
    * REBUILT. Links the rebuilt scene engine (mmo.play.*) into play.swf, which
    * the loader puts into the main application domain before any <play>
    * module, so the modules that extend its classes (WildPetAvatar is a
    * ScenePlayer) find them whatever their order in config.xml.
    */
   public class DocPlayEngine extends Sprite
   {
      public function DocPlayEngine()
      {
         super();
      }

      private static function compileMe():void
      {
         var b:PlayerManager, c:PlayerManagerEvent, d:MovableEvent, e:PlayerBase, f:ScenePlayer;
         var g:DocSceneBase, h:FBSceneBase, i:FBSceneInfo, j:FaceDirectionTypes, k:SceneBase, l:SceneInfo;
         var m:SceneManager, n:SceneManagerEvent, o:BigSceneBase, p:SceneExtInfo;
         var q1:Dressily, q2:DressilyEvent, q3:IDressily, q4:IMovable, q5:IMovingStrategy, q6:MouseControlStrategy;
         var q7:RoundPointStrategy, q8:StandBehindStrategy, q8b:FollowSlowlyStrategy, q8c:FlipSceneBase, q8d:FlipHelper, q8e:FlipPlayerGenerator, h1:ActComHelper, h2:ActDateUtils, h3:ActionHelper, h4:Panel_Helper, h5:RefuseInviteHelper, h6:BigSceneEvent, h7:UserCardObserver, q9:Player, q10:IPlayerObserver, q11:MyPlayerObserver;
         var q12:DocGameBase, q13:SceneCommandStep, q14:ClickAndHitEvent, q15:ClickAndHitHelper;
         var q16:DefaultPlayerGenerator, q17:IPlayerGenerator;
         var q18:AutomaticCacheChecker, q19:LinkUtil;
      }
   }
}
