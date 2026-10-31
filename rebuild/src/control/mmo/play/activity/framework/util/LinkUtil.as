package mmo.play.activity.framework.util
{
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RNotice;

   /**
    * REBUILT shim (not in the January 2013 engine): links later modules use
    * to jump to other panels and scenes. Only what the catalog book and the
    * later scenes of the story quests call is here.
    */
   public class LinkUtil
   {
      /**
       * Into a scene (the later engine also hung an arrow there and called
       * back once it was shown): what 崩坏的上古神殿 does after its film.
       */
      public static function gotoScene(sceneName:String, arrow:String = "", callback:Function = null):void
      {
         var onInited:Function = function(e:* = null):void
         {
            SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED, onInited);
            if (callback != null) callback();
         };
         ModalDialogManager.getInstance().clearAll();
         if (callback != null) SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onInited);
         SceneManager.getInstance().loadScene(sceneName, "default");
      }

      /** 开通蓝宝石: the VIP sign-up page of the real-money shop, which the revival does not have. */
      public static function goToBlueDiamond():void
      {
         RNotice.show(LayerManager.getBaseTop(), "蓝宝石骑士还在修复中哦！");
      }
   }
}
