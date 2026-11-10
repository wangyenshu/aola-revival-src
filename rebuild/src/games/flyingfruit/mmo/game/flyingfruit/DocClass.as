package mmo.game.flyingfruit
{
   import flash.display.DisplayObject;
   import mmo.play.scene.DocGameBase;
   import com.adobe.crypto.MD5;
   import com.adobe.utils.ArrayUtil;
   import com.adobe.utils.IntUtil;
   import com.adobe.utils.OpUtil;
   import com.adobe.utils.StringUtil;
   import com.greensock.TweenLite;
   import com.greensock.core.PropTween;
   import com.greensock.core.SimpleTimeline;
   import com.greensock.core.TweenCore;
   import com.greensock.easing.Back;
   import com.greensock.easing.Linear;
   import com.greensock.easing.Strong;
   import com.greensock.plugins.AutoAlphaPlugin;
   import com.greensock.plugins.EndArrayPlugin;
   import com.greensock.plugins.FramePlugin;
   import com.greensock.plugins.RemoveTintPlugin;
   import com.greensock.plugins.TintPlugin;
   import com.greensock.plugins.TweenPlugin;
   import com.greensock.plugins.VisiblePlugin;
   import com.greensock.plugins.VolumePlugin;
   import flyingfruit_fla.Timeline_158;
   import flyingfruit_fla.Timeline_168;
   import flyingfruit_fla.Timeline_169;
   import flyingfruit_fla.Timeline_172;
   import flyingfruit_fla.Timeline_18;
   import flyingfruit_fla.Timeline_23;
   import flyingfruit_fla.Timeline_28;
   import flyingfruit_fla.Timeline_3;
   import flyingfruit_fla.Timeline_34;
   import flyingfruit_fla.Timeline_39;
   import flyingfruit_fla.Timeline_44;
   import flyingfruit_fla.Timeline_54;
   import flyingfruit_fla.Timeline_64;
   import flyingfruit_fla.Timeline_68;
   import flyingfruit_fla.Timeline_7;
   import flyingfruit_fla.Timeline_70;
   import flyingfruit_fla._2_19;
   import flyingfruit_fla._2_24;
   import flyingfruit_fla._2_30;
   import flyingfruit_fla._2_36;
   import flyingfruit_fla._2_41;
   import mmo.common.AlignType;
   import mmo.common.BitmapMovieClip;
   import mmo.common.DateUtil;
   import mmo.common.DisplayUtil;
   import mmo.common.HitTest;
   import mmo.common.Text;
   import mmo.common.cachepool.CachePool;
   import mmo.common.event.BtCommonEventDispatcher;
   import mmo.common.event.BtEventDispatcher;
   import mmo.common.event.BtEventDispatcherManager;
   import mmo.game.flyingfruit.event.EnterFrameParams;
   import mmo.game.flyingfruit.event.FFEnterFrameManager;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.FruitManager;
   import mmo.game.flyingfruit.fruit.IFFStrategy;
   import mmo.game.flyingfruit.fruit.MoveDateConfig;
   import mmo.game.flyingfruit.fruit.fruit.Fruit1;
   import mmo.game.flyingfruit.fruit.fruit.Fruit2;
   import mmo.game.flyingfruit.fruit.fruit.Fruit3;
   import mmo.game.flyingfruit.fruit.fruit.Fruit4;
   import mmo.game.flyingfruit.fruit.fruit.Fruit5;
   import mmo.game.flyingfruit.fruit.fruit.Fruit6;
   import mmo.game.flyingfruit.fruit.fruit.Fruit7;
   import mmo.game.flyingfruit.fruit.fruit.Fruit8;
   import mmo.game.flyingfruit.fruit.strategy.FFBombStragety;
   import mmo.game.flyingfruit.fruit.strategy.FFClockStragety;
   import mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
   import mmo.game.flyingfruit.fruit.strategy.FFToolStragety;
   import mmo.game.flyingfruit.panel.AngerPanel;
   import mmo.game.flyingfruit.panel.BombMovie;
   import mmo.game.flyingfruit.panel.BombPanel;
   import mmo.game.flyingfruit.panel.EndMovie;
   import mmo.game.flyingfruit.panel.GameOverPanel;
   import mmo.game.flyingfruit.panel.MainPanel;
   import mmo.game.flyingfruit.panel.StartMovie;
   import mmo.game.flyingfruit.panel.StartPanel;
   import mmo.game.flyingfruit.sound.BGSound;
   import mmo.game.flyingfruit.sound.BeginSound;
   import mmo.game.flyingfruit.sound.BombSound;
   import mmo.game.flyingfruit.sound.CountDownSound;
   import mmo.game.flyingfruit.sound.DiskAppearSound;
   import mmo.game.flyingfruit.sound.DiskAppearSound2;
   import mmo.game.flyingfruit.sound.HitBombSound;
   import mmo.game.flyingfruit.sound.HitClockSound;
   import mmo.game.flyingfruit.sound.HitDimandSound;
   import mmo.game.flyingfruit.sound.HitDiskSound;
   import mmo.game.flyingfruit.sound.HitFlyingDiskSound;
   import mmo.game.flyingfruit.sound.ShootSound;
   import mmo.game.flyingfruit.sound.SongController;
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneCommandEvent;
   import mmo.util.command.SceneMacroCommand;
   import mmo.util.command.SceneSimpleCommand;
   import mmo.util.constants.EventListenerPriority;
   import mmo.util.quadtree.QuadTree;
   import mmo.util.quadtree.QuadTreeConstants;
   import mmo.util.quadtree.QuadTreeDisplayObject;
   import mmo.util.quadtree.QuadTreeNode;
   import mmo.util.quadtree.QuadTreeProxy;
   import mmo.util.quadtree.pair.IPairHandler;
   import mmo.util.quadtree.pair.QuadTreePair;
   import mmo.util.quadtree.pair.QuadTreePairManager;
   import mmo.util.words.AnsiUnicodeConvert;
   import mmo.util.words.HanziToPinyinUtil;
   
   /**
    * LATER game/flyingfruit (疯狂的水果): its decompiled code compiled against the 2013 libraries
    * (aola-revival), without the later praise-and-feedback stamp and material tips of its start
    * panel, which stopped it in the 2013 client; on its own art.
    */
   public class DocClass extends DocGameBase
   {
      
      public function DocClass()
      {
         super();
      }
      
      /** REVIVAL: every class of the game compiled in (the art's symbols are bound to them by name). */
      private static function compileMe() : void
      {
         var c0:com.adobe.crypto.MD5;
         var c1:com.adobe.utils.ArrayUtil;
         var c2:com.adobe.utils.IntUtil;
         var c3:com.adobe.utils.OpUtil;
         var c4:com.adobe.utils.StringUtil;
         var c5:com.greensock.TweenLite;
         var c6:com.greensock.core.PropTween;
         var c7:com.greensock.core.SimpleTimeline;
         var c8:com.greensock.core.TweenCore;
         var c9:com.greensock.easing.Back;
         var c10:com.greensock.easing.Linear;
         var c11:com.greensock.easing.Strong;
         var c12:com.greensock.plugins.AutoAlphaPlugin;
         var c13:com.greensock.plugins.EndArrayPlugin;
         var c14:com.greensock.plugins.FramePlugin;
         var c15:com.greensock.plugins.RemoveTintPlugin;
         var c16:com.greensock.plugins.TintPlugin;
         var c17:com.greensock.plugins.TweenPlugin;
         var c18:com.greensock.plugins.VisiblePlugin;
         var c19:com.greensock.plugins.VolumePlugin;
         var c20:flyingfruit_fla.Timeline_158;
         var c21:flyingfruit_fla.Timeline_168;
         var c22:flyingfruit_fla.Timeline_169;
         var c23:flyingfruit_fla.Timeline_172;
         var c24:flyingfruit_fla.Timeline_18;
         var c25:flyingfruit_fla.Timeline_23;
         var c26:flyingfruit_fla.Timeline_28;
         var c27:flyingfruit_fla.Timeline_3;
         var c28:flyingfruit_fla.Timeline_34;
         var c29:flyingfruit_fla.Timeline_39;
         var c30:flyingfruit_fla.Timeline_44;
         var c31:flyingfruit_fla.Timeline_54;
         var c32:flyingfruit_fla.Timeline_64;
         var c33:flyingfruit_fla.Timeline_68;
         var c34:flyingfruit_fla.Timeline_7;
         var c35:flyingfruit_fla.Timeline_70;
         var c36:flyingfruit_fla._2_19;
         var c37:flyingfruit_fla._2_24;
         var c38:flyingfruit_fla._2_30;
         var c39:flyingfruit_fla._2_36;
         var c40:flyingfruit_fla._2_41;
         var c41:mmo.common.AlignType;
         var c42:mmo.common.BitmapMovieClip;
         var c43:mmo.common.DateUtil;
         var c44:mmo.common.DisplayUtil;
         var c45:mmo.common.HitTest;
         var c46:mmo.common.Text;
         var c47:mmo.common.cachepool.CachePool;
         var c49:mmo.common.event.BtCommonEventDispatcher;
         var c50:mmo.common.event.BtEventDispatcher;
         var c51:mmo.common.event.BtEventDispatcherManager;
         var c53:mmo.game.flyingfruit.FFAdderConfig;
         var c54:mmo.game.flyingfruit.FFAdderManager;
         var c55:mmo.game.flyingfruit.FFHitManager;
         var c56:mmo.game.flyingfruit.FFInstanceManager;
         var c57:mmo.game.flyingfruit.FlyingFruitManager;
         var c58:mmo.game.flyingfruit.event.EnterFrameParams;
         var c59:mmo.game.flyingfruit.event.FFEnterFrameManager;
         var c60:mmo.game.flyingfruit.fruit.FruitBase;
         var c61:mmo.game.flyingfruit.fruit.FruitManager;
         var c62:mmo.game.flyingfruit.fruit.IFFStrategy;
         var c63:mmo.game.flyingfruit.fruit.MoveDateConfig;
         var c64:mmo.game.flyingfruit.fruit.fruit.Fruit1;
         var c65:mmo.game.flyingfruit.fruit.fruit.Fruit2;
         var c66:mmo.game.flyingfruit.fruit.fruit.Fruit3;
         var c67:mmo.game.flyingfruit.fruit.fruit.Fruit4;
         var c68:mmo.game.flyingfruit.fruit.fruit.Fruit5;
         var c69:mmo.game.flyingfruit.fruit.fruit.Fruit6;
         var c70:mmo.game.flyingfruit.fruit.fruit.Fruit7;
         var c71:mmo.game.flyingfruit.fruit.fruit.Fruit8;
         var c72:mmo.game.flyingfruit.fruit.strategy.FFBombStragety;
         var c73:mmo.game.flyingfruit.fruit.strategy.FFClockStragety;
         var c74:mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
         var c75:mmo.game.flyingfruit.fruit.strategy.FFToolStragety;
         var c76:mmo.game.flyingfruit.panel.AngerPanel;
         var c77:mmo.game.flyingfruit.panel.BombMovie;
         var c78:mmo.game.flyingfruit.panel.BombPanel;
         var c79:mmo.game.flyingfruit.panel.EndMovie;
         var c80:mmo.game.flyingfruit.panel.GameOverPanel;
         var c81:mmo.game.flyingfruit.panel.MainPanel;
         var c82:mmo.game.flyingfruit.panel.StartMovie;
         var c83:mmo.game.flyingfruit.panel.StartPanel;
         var c84:mmo.game.flyingfruit.sound.BGSound;
         var c85:mmo.game.flyingfruit.sound.BeginSound;
         var c86:mmo.game.flyingfruit.sound.BombSound;
         var c87:mmo.game.flyingfruit.sound.CountDownSound;
         var c88:mmo.game.flyingfruit.sound.DiskAppearSound;
         var c89:mmo.game.flyingfruit.sound.DiskAppearSound2;
         var c90:mmo.game.flyingfruit.sound.HitBombSound;
         var c91:mmo.game.flyingfruit.sound.HitClockSound;
         var c92:mmo.game.flyingfruit.sound.HitDimandSound;
         var c93:mmo.game.flyingfruit.sound.HitDiskSound;
         var c94:mmo.game.flyingfruit.sound.HitFlyingDiskSound;
         var c95:mmo.game.flyingfruit.sound.ShootSound;
         var c96:mmo.game.flyingfruit.sound.SongController;
         var c97:mmo.util.command.ISceneCommand;
         var c98:mmo.util.command.SceneCommandEvent;
         var c99:mmo.util.command.SceneMacroCommand;
         var c100:mmo.util.command.SceneSimpleCommand;
         var c101:mmo.util.constants.EventListenerPriority;
         var c102:mmo.util.quadtree.QuadTree;
         var c103:mmo.util.quadtree.QuadTreeConstants;
         var c104:mmo.util.quadtree.QuadTreeDisplayObject;
         var c105:mmo.util.quadtree.QuadTreeNode;
         var c106:mmo.util.quadtree.QuadTreeProxy;
         var c107:mmo.util.quadtree.pair.IPairHandler;
         var c108:mmo.util.quadtree.pair.QuadTreePair;
         var c109:mmo.util.quadtree.pair.QuadTreePairManager;
         var c110:mmo.util.words.AnsiUnicodeConvert;
         var c111:mmo.util.words.HanziToPinyinUtil;
      }

      override public function get game() : DisplayObject
      {
         return new FlyingFruitManager();
      }
   }
}

