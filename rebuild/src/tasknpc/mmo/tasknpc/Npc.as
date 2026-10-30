package mmo.tasknpc
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.revival.RLog;

   /**
    * REBUILT: one NPC standing in a scene. The view is the original
    * mmo.tasknpc.Npc<id>_<view> symbol of tasknpc/npc<id>.swf (tasknpc/npc0 as
    * the default, as in the 2013 loader); the name plate and bubble are drawn.
    */
   public class Npc
   {
      public var id:int;
      public var viewId:int;
      public var x:int;
      public var y:int;
      public var view:Sprite;
      private var onClick:Function;
      private var disposed:Boolean;
      private var bubble:Sprite;
      private var bubbleTimer:Timer;
      private var art:DisplayObject;

      public function Npc(id:int, viewId:int, x:int, y:int, onClick:Function)
      {
         this.id = id;
         this.viewId = viewId;
         this.x = x;
         this.y = y;
         this.onClick = onClick;
      }

      public function load():void
      {
         var cls:String = "mmo.tasknpc.Npc" + id + "_" + viewId;
         ResScheduler.getResource("tasknpc/npc" + id, function(d:DisplayObject):void
         {
            if (!place(cls)) fallback();
         }, cls, function(e:*):void { fallback(); });
      }

      private function fallback():void
      {
         if (disposed) return;
         var cls:String = "mmo.tasknpc.Npc0_" + viewId;
         ResScheduler.getResource("tasknpc/npc0", function(d:DisplayObject):void { place(cls); }, cls);
      }

      private function place(cls:String):Boolean
      {
         if (disposed) return true;
         if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return false;
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null) return true;
         var layer:DisplayObjectContainer = info.scene.playerLayer;
         if (layer == null) return true;
         try
         {
            var C:Class = getDefinitionByName(cls) as Class;
            art = new C() as DisplayObject;
         }
         catch (e:Error)
         {
            RLog.error("npc " + id, e);
            return true;
         }
         view = new Sprite();
         view.name = "npc_" + id;
         view.buttonMode = true;
         art.name = "npcArt";
         view.addChild(art);
         var name:String = TaskNpcService.npcName(id);
         if (name)
         {
            var tf:TextField = new TextField();
            tf.defaultTextFormat = new TextFormat("SimSun", 12, 0xFFFF66, true);
            tf.autoSize = TextFieldAutoSize.CENTER;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = name;
            tf.filters = [new GlowFilter(0x000000, 1, 2, 2, 8)];
            tf.x = -tf.width / 2;
            tf.y = 4;
            view.addChild(tf);
         }
         view.x = x;
         view.y = y;
         layer.addChild(view);
         PlayerManager.getInstance().sortDepths();
         ClickAndHitHelper.instance.registerTarget(view, true, 100);
         var self:Npc = this;
         view.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, function(e:ClickAndHitEvent):void
         {
            if (onClick != null) onClick(self);
         });
         if (wantMark) setTaskMark(true);
         return true;
      }

      /** A speech bubble over the head for a few seconds (the 2013 NPCs greeted passers-by). */
      public function say(text:String):void
      {
         if (view == null || disposed) return;
         clearBubble();
         bubble = new Sprite();
         bubble.mouseEnabled = bubble.mouseChildren = false;
         var tf:TextField = new TextField();
         tf.defaultTextFormat = new TextFormat("SimSun", 12, 0x333333);
         tf.wordWrap = true;
         tf.multiline = true;
         tf.width = 150;
         tf.autoSize = TextFieldAutoSize.LEFT;
         tf.selectable = false;
         tf.text = text;
         var w:Number = Math.min(150, tf.textWidth + 8) + 12;
         var h:Number = tf.height + 8;
         bubble.graphics.lineStyle(1.5, 0x5A8FC8);
         bubble.graphics.beginFill(0xFFFFFF, 0.95);
         bubble.graphics.drawRoundRect(-w / 2, -h, w, h, 14, 14);
         bubble.graphics.endFill();
         bubble.graphics.beginFill(0xFFFFFF, 0.95);
         bubble.graphics.moveTo(-6, -1);
         bubble.graphics.lineTo(0, 9);
         bubble.graphics.lineTo(6, -1);
         bubble.graphics.endFill();
         tf.x = -w / 2 + 6;
         tf.y = -h + 4;
         bubble.addChild(tf);
         var top:Number = art ? art.getBounds(view).top : -100;
         bubble.y = top - 10;
         view.addChild(bubble);
         bubbleTimer = new Timer(4500, 1);
         bubbleTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { clearBubble(); });
         bubbleTimer.start();
      }

      private function clearBubble():void
      {
         if (bubbleTimer) bubbleTimer.stop();
         bubbleTimer = null;
         if (bubble && bubble.parent) bubble.parent.removeChild(bubble);
         bubble = null;
      }

      private var mark:Sprite;
      private var wantMark:Boolean;

      /**
       * The yellow "?" over an NPC who has something to say for a task (as
       * over 贝鲁特 in the December 2011 screenshots), drawn; it bobs.
       */
      public function setTaskMark(on:Boolean):void
      {
         wantMark = on;
         if (view == null) return;
         if (mark != null && mark.parent) mark.parent.removeChild(mark);
         mark = null;
         if (!on) return;
         mark = new Sprite();
         mark.mouseEnabled = mark.mouseChildren = false;
         var tf:TextField = new TextField();
         tf.defaultTextFormat = new TextFormat("Arial", 30, 0xFFD21F, true);
         tf.autoSize = TextFieldAutoSize.CENTER;
         tf.selectable = false;
         tf.text = "?";
         tf.filters = [new GlowFilter(0x8A4B00, 1, 3, 3, 10), new GlowFilter(0xFFFFFF, 0.9, 6, 6, 2)];
         tf.x = -tf.width / 2;
         tf.y = -tf.height;
         mark.addChild(tf);
         var top:Number = art ? art.getBounds(view).top : -100;
         var baseY:Number = top - 6;
         mark.y = baseY;
         view.addChild(mark);
         var t:int = 0;
         var m:Sprite = mark;
         m.addEventListener(Event.ENTER_FRAME, function(e:Event):void
         {
            if (m.parent == null) { m.removeEventListener(Event.ENTER_FRAME, arguments.callee); return; }
            t++;
            m.y = baseY - Math.abs(Math.sin(t / 6)) * 6;
         });
      }

      public function dispose():void
      {
         disposed = true;
         clearBubble();
         if (view != null)
         {
            try { ClickAndHitHelper.instance.remove(view); } catch (e:Error) {}
            if (view.parent) view.parent.removeChild(view);
         }
         view = null;
      }
   }
}
