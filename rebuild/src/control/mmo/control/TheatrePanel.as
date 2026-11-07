package mmo.control
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.AsyncErrorEvent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.NetStatusEvent;
   import flash.events.SecurityErrorEvent;
   import flash.external.ExternalInterface;
   import flash.media.Video;
   import flash.net.NetConnection;
   import flash.net.NetStream;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.loader.layer.LayerManager;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.utils.getQualifiedClassName;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REVIVAL. The 百田大剧场: in 2013 the page script (js/aola.js) put 百田's video site over the
    * game (showVideoPlayer: the theatre scene's list of cartoons; showAnniversaryVideo and
    * showWarTeamVideo: two films). The site is gone; 奥拉星's own films survive on the game's CDN
    * as Flash video (FLV), which play here (revival/theatre.xml lists them). The page's functions
    * call revivalTheatre(film) (web/theatre.js): "" the list, a film's id that film, "close".
    */
   public class TheatrePanel extends Sprite
   {
      private static const LIST:String = "http://www.9aola.com/revival/theatre.xml";
      private static const W:int = 820;
      private static const H:int = 452;
      private static const SW:int = 576;
      private static const SH:int = 336;
      private static const TRACK:int = 400;
      private static var current:TheatrePanel;
      private static var films:Array;

      private var box:Sprite;
      private var video:Video;
      private var idle:TextField;
      private var listBox:Sprite;
      private var items:Array = [];
      private var playBtn:Sprite;
      private var playIcon:Shape;
      private var track:Sprite;
      private var loadedBar:Shape;
      private var playedBar:Shape;
      private var knob:Shape;
      private var timeText:TextField;
      private var nc:NetConnection;
      private var ns:NetStream;
      private var film:Object;
      private var duration:Number = 0;
      private var paused:Boolean;
      private var ended:Boolean;
      private var dragging:Boolean;
      private var shut:Boolean;

      public static function install():void
      {
         if (!ExternalInterface.available) return;
         try
         {
            ExternalInterface.addCallback("revivalTheatre", function(id:String):void
            {
               if (id == "close") { if (current != null) current.close(); return; }
               open(id);
            });
         }
         catch (e:Error)
         {
            RLog.error("theatre", e);
         }
      }

      public static function open(id:String = ""):void
      {
         RLog.log("theatre: open " + (id || "the list"));
         try { PlayerManager.getInstance().myPlayer.stop(); } catch (e:Error) {}
         if (current == null || current.parent == null)
         {
            // The theatre scene's own screen (TheatreUI: a frame and a close button, under 百田's video
            // site in 2013) is put away: the panel is the theatre now, and its close leaves the room.
            putAwayTheatreUI();
            current = new TheatrePanel();
            ModalDialogManager.getInstance().addModalDialog(current, AlignType.NONE, PanelEffect.NONE, false);
         }
         current.start(id || "");
      }

      public function TheatrePanel()
      {
         super();
         addChild(RUI.dim());
         box = RUI.panel(W, H, "百田大剧场", close, "theatreClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2;
         addChild(box);

         var screen:Shape = new Shape();
         screen.graphics.lineStyle(2, 0xC9ECFF);
         screen.graphics.beginFill(0x000011);
         screen.graphics.drawRoundRect(16, 54, SW + 4, SH + 4, 14, 14);
         screen.graphics.endFill();
         box.addChild(screen);
         video = new Video(SW, SH);
         video.smoothing = true;
         video.x = 18;
         video.y = 56;
         box.addChild(video);
         idle = RUI.text(16, 0x9FD6FF, true, SW - 60);
         var centred:TextFormat = idle.defaultTextFormat;
         centred.align = TextFormatAlign.CENTER;
         idle.defaultTextFormat = centred;
         idle.height = 60;
         idle.x = 18 + 30;
         box.addChild(idle);

         buildControls(18, 56 + SH + 14);

         box.addChild(RUI.well(610, 54, 194, H - 74));
         listBox = new Sprite();
         listBox.x = 610;
         listBox.y = 54;
         box.addChild(listBox);
         addEventListener(Event.ENTER_FRAME, tick);
         // Taken away by anything else (a scene change clears the dialogs): the film stops.
         addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void { if (e.target == e.currentTarget) shutDown(); });
      }

      private function buildControls(x:int, y:int):void
      {
         playBtn = RUI.smallButton("", togglePlay, 40, 28, "theatrePlay");
         playBtn.x = x;
         playBtn.y = y;
         box.addChild(playBtn);
         // Beside the button, not in it: Ruffle keeps a filtered sprite's old picture when a child changes.
         playIcon = new Shape();
         playIcon.x = x + 20;
         playIcon.y = y + 14;
         box.addChild(playIcon);

         track = new Sprite();
         track.name = "theatreSeek";
         track.buttonMode = true;
         track.x = x + 54;
         track.y = y + 14;
         track.graphics.beginFill(0, 0);
         track.graphics.drawRect(-4, -10, TRACK + 8, 20);
         track.graphics.endFill();
         track.graphics.lineStyle(1.5, 0xFFFFFF);
         track.graphics.beginFill(0x1F5E9E);
         track.graphics.drawRoundRect(0, -4, TRACK, 8, 8, 8);
         track.graphics.endFill();
         loadedBar = new Shape();
         playedBar = new Shape();
         knob = new Shape();
         knob.graphics.lineStyle(2, 0xFFFFFF);
         knob.graphics.beginFill(0xF07812);
         knob.graphics.drawCircle(0, 0, 7);
         knob.graphics.endFill();
         track.addChild(loadedBar);
         track.addChild(playedBar);
         track.addChild(knob);
         track.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (ns == null || duration <= 0) return;
            dragging = true;
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag);
            stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
            onDrag(null);
         });
         box.addChild(track);

         timeText = RUI.text(13, RUI.BLUE, true);
         timeText.name = "theatreTime";
         timeText.x = track.x + TRACK + 14;
         timeText.y = y + 5;
         box.addChild(timeText);
         drawPlayIcon();
         drawProgress(0, 0);
      }

      private function start(id:String):void
      {
         if (films != null) { show(id); return; }
         say("正在打开……");
         var l:URLLoader = new URLLoader();
         l.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            films = [];
            try
            {
               for each (var x:XML in new XML(l.data).film)
                  films.push({ id: String(x.@id), title: String(x.@title), url: String(x.@url), uploaded: String(x.@uploaded) });
            }
            catch (err:Error) { RLog.error("theatre list", err); }
            if (parent != null) show(id);
         });
         // Not kept: the next opening asks again.
         var fail:Function = function(e:Event):void
         {
            RLog.log("theatre: no film list (" + e.type + ")");
            if (parent != null) say("放映厅里还没有动画片。");
         };
         l.addEventListener(IOErrorEvent.IO_ERROR, fail);
         l.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fail);
         l.load(new URLRequest(LIST));
      }

      private function show(id:String):void
      {
         if (films.length == 0) { say("放映厅里还没有动画片。"); return; }
         if (items.length == 0) buildList();
         for each (var f:Object in films) if (f.id == id) { play(f); return; }
         if (film == null) say("选一部动画片看看吧！");
      }

      private function buildList():void
      {
         var y:int = 8;
         for each (var f:Object in films)
         {
            var it:Sprite = item(f);
            it.x = 10;
            it.y = y;
            listBox.addChild(it);
            items.push(it);
            y += it.height + 8;
         }
         var note:TextField = RUI.text(12, 0x8A6A3A, false, 174);
         note.text = "2013 年的大剧场还放过其他动画公司的卡通，那些片子没有保存在这里。";
         note.x = 10;
         note.y = y + 4;
         listBox.addChild(note);
      }

      private function item(f:Object):Sprite
      {
         var s:Sprite = new Sprite();
         s.name = "film_" + f.id;
         s.buttonMode = true;
         s.mouseChildren = false;
         var icon:Shape = new Shape();
         var g:* = icon.graphics;
         g.beginFill(0x2B3E5C);
         g.drawRoundRect(0, 0, 34, 26, 6, 6);
         g.endFill();
         g.beginFill(0xFFFFFF);
         for (var i:int = 0; i < 4; i++) { g.drawRect(3 + i * 8, 2, 4, 3); g.drawRect(3 + i * 8, 21, 4, 3); }
         g.endFill();
         g.beginFill(0xFFC45A);
         g.moveTo(13, 8); g.lineTo(23, 13); g.lineTo(13, 18); g.lineTo(13, 8);
         g.endFill();
         icon.x = 10;
         icon.y = 12;
         s.addChild(icon);
         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = String(f.title || f.id);
         t.x = 52;
         t.y = 8;
         s.addChild(t);
         var d:TextField = RUI.text(12, 0x7A8EA8, false);
         d.text = String(f.uploaded || "").replace(/-/g, ".");
         d.x = 52;
         d.y = 28;
         s.addChild(d);
         drawItem(s, false);
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); play(f); });
         return s;
      }

      private static function drawItem(s:Sprite, on:Boolean):void
      {
         s.graphics.clear();
         s.graphics.lineStyle(2, on ? 0xF07812 : 0xF2C27A);
         s.graphics.beginFill(on ? 0xFFF1C9 : 0xFFFFFF);
         s.graphics.drawRoundRect(0, 0, 174, 50, 14, 14);
         s.graphics.endFill();
      }

      private function play(f:Object):void
      {
         stopStream();
         film = f;
         for each (var it:Sprite in items) drawItem(it, it.name == "film_" + f.id);
         duration = Number(f.duration) || 0;
         paused = false;
         ended = false;
         say("正在打开……");
         nc = new NetConnection();
         nc.connect(null);
         ns = new NetStream(nc);
         ns.client = {
            onMetaData: function(m:Object):void { if (Number(m.duration) > 0) duration = Number(m.duration); },
            onCuePoint: function(m:Object):void {},
            onXMPData: function(m:Object):void {},
            onPlayStatus: function(m:Object):void {}
         };
         ns.addEventListener(NetStatusEvent.NET_STATUS, onStatus);
         ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, function(e:AsyncErrorEvent):void { RLog.log("theatre: " + e.text); });
         ns.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void { missing(); });
         video.attachNetStream(ns);
         ns.play(String(f.url));
         drawPlayIcon();
      }

      private function onStatus(e:NetStatusEvent):void
      {
         var code:String = String(e.info.code);
         if (code == "NetStream.Play.Start" || code == "NetStream.Buffer.Full") idle.visible = false;
         else if (code == "NetStream.Play.StreamNotFound" || code == "NetStream.Play.Failed") missing();
         else if (code == "NetStream.Play.Stop")
         {
            // The end: the last picture stays; ▶ plays it again.
            ended = true;
            paused = true;
            drawPlayIcon();
         }
      }

      private function missing():void
      {
         stopStream();
         say("这部动画片没有找到（" + (film ? film.title : "") + "）。");
      }

      private function togglePlay():void
      {
         if (ns == null) { if (film != null) play(film); return; }
         if (ended)
         {
            ended = false;
            paused = false;
            ns.seek(0);
            ns.resume();
         }
         else if (paused)
         {
            paused = false;
            ns.resume();
         }
         else
         {
            paused = true;
            ns.pause();
         }
         drawPlayIcon();
      }

      private function onDrag(e:MouseEvent):void
      {
         var f:Number = Math.max(0, Math.min(1, track.mouseX / TRACK));
         drawProgress(f, loadedPart());
      }

      private function onDrop(e:MouseEvent):void
      {
         stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
         stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
         dragging = false;
         if (ns == null || duration <= 0) return;
         // Not past what has come in (the file is read from its start).
         var f:Number = Math.min(Math.max(0, Math.min(1, track.mouseX / TRACK)), loadedPart());
         ended = false;
         ns.seek(f * duration);
         if (!paused) ns.resume();
         drawPlayIcon();
      }

      private function loadedPart():Number
      {
         return ns != null && ns.bytesTotal > 0 ? ns.bytesLoaded / ns.bytesTotal : 0;
      }

      private function tick(e:Event):void
      {
         if (ns == null || dragging) return;
         var t:Number = ns.time;
         drawProgress(duration > 0 ? Math.min(1, t / duration) : 0, loadedPart());
         timeText.text = clock(t) + " / " + clock(duration);
      }

      private function drawProgress(played:Number, loaded:Number):void
      {
         loadedBar.graphics.clear();
         loadedBar.graphics.beginFill(0x8CC8F0);
         loadedBar.graphics.drawRoundRect(1, -3, Math.max(0, (TRACK - 2) * loaded), 6, 6, 6);
         loadedBar.graphics.endFill();
         playedBar.graphics.clear();
         playedBar.graphics.beginFill(0xFFB040);
         playedBar.graphics.drawRoundRect(1, -3, Math.max(0, (TRACK - 2) * played), 6, 6, 6);
         playedBar.graphics.endFill();
         knob.x = TRACK * played;
         if (timeText != null && ns == null) timeText.text = clock(0) + " / " + clock(duration);
      }

      private function drawPlayIcon():void
      {
         var g:* = playIcon.graphics;
         g.clear();
         g.beginFill(0xFFFFFF);
         if (ns != null && !paused)
         {
            g.drawRect(-6, -7, 4, 14);
            g.drawRect(2, -7, 4, 14);
         }
         else
         {
            g.moveTo(-5, -8); g.lineTo(8, 0); g.lineTo(-5, 8); g.lineTo(-5, -8);
         }
         g.endFill();
      }

      private static function clock(s:Number):String
      {
         var n:int = Math.max(0, Math.floor(s));
         var m:int = n / 60;
         var r:int = n % 60;
         return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
      }

      private function say(text:String):void
      {
         idle.text = text;
         idle.y = 56 + (SH - idle.textHeight) / 2;
         idle.visible = true;
      }

      private function stopStream():void
      {
         if (ns != null)
         {
            ns.removeEventListener(NetStatusEvent.NET_STATUS, onStatus);
            // (Ruffle's close does nothing yet: paused, it is silent.)
            try { ns.pause(); ns.close(); } catch (e:Error) {}
            ns = null;
         }
         if (nc != null)
         {
            try { nc.close(); } catch (e:Error) {}
            nc = null;
         }
         video.attachNetStream(null);
         video.clear();
         drawPlayIcon();
         drawProgress(0, 0);
      }

      public function close():void
      {
         shutDown();
         if (parent == null) return;
         if (!ModalDialogManager.getInstance().removeModalDialog(this, PanelEffect.NONE) && parent) parent.removeChild(this);
         // In the theatre: out of it, as the scene's own close did (TheatreUI: loadDefaultScene).
         try
         {
            var sm:SceneManager = SceneManager.getInstance();
            if (sm.loadedSceneInfo != null && String(sm.loadedSceneInfo.sceneName) == "theatre") sm.loadDefaultScene();
         }
         catch (e:Error) { RLog.error("theatre: leave", e); }
      }

      /** The theatre scene's TheatreUI, wherever the dialog manager put it. */
      private static function putAwayTheatreUI():void
      {
         var found:DisplayObject = null;
         var look:Function = function(d:DisplayObjectContainer, depth:int):void
         {
            for (var i:int = 0; d != null && found == null && i < d.numChildren; i++)
            {
               var c:DisplayObject = d.getChildAt(i);
               if (getQualifiedClassName(c) == "mmo.scene.theatre::TheatreUI") found = c;
               else if (depth > 0 && c is DisplayObjectContainer) look(DisplayObjectContainer(c), depth - 1);
            }
         };
         try
         {
            look(LayerManager.stage, 5);
            if (found != null) ModalDialogManager.getInstance().removeModalDialog(found, PanelEffect.NONE);
         }
         catch (e:Error) { RLog.error("theatre: its screen", e); }
      }

      private function shutDown():void
      {
         if (shut) return;
         shut = true;
         if (dragging && stage != null)
         {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
            dragging = false;
         }
         removeEventListener(Event.ENTER_FRAME, tick);
         stopStream();
         if (current == this) current = null;
      }
   }
}
