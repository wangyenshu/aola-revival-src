package mmo.play.player.sceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Graphics;
   import flash.display.MovieClip;
   import flash.geom.Rectangle;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.play.player.dressily.Dressily;
   import mmo.play.player.dressily.DressilyEvent;
   import mmo.play.player.dressily.IDressily;
   import mmo.play.player.movable.IMovable;

   /**
    * REBUILT. A dressed player: avatar (Dressily over the original avatar
    * service), nickname, icons above the head, actions.
    */
   public class Player extends PlayerBase implements IMovable, IDressily
   {
      private var _dressily:IDressily;
      private var _shadow:Shape;
      private var _nameField:TextField;
      private var _nickName:String;
      private var _topIcons:Object = {};
      private var _topIconOrder:Array = [];
      private var _iconLayer:Sprite;
      private var _member:Boolean;
      private var _bubble:Sprite;
      private var _flipV:Boolean;
      private var _bubbleTimer:Timer;

      public function Player(userName:String, b1:Boolean = false, b2:Boolean = false)
      {
         super(userName);
         _shadow = new Shape();
         _shadow.graphics.beginFill(0x000000, 0.22);
         _shadow.graphics.drawEllipse(-18, -6, 36, 12);
         _shadow.graphics.endFill();
         addChild(_shadow);
         setDressily(createDressily(null));
         _nameField = new TextField();
         _nameField.defaultTextFormat = new TextFormat("SimSun", 12, 0xFFFFFF);
         _nameField.autoSize = TextFieldAutoSize.CENTER;
         _nameField.selectable = false;
         _nameField.mouseEnabled = false;
         _nameField.filters = [new GlowFilter(0x000000, 1, 2, 2, 8)];
         addChild(_nameField);
         _iconLayer = new Sprite();
         _iconLayer.mouseEnabled = false;
         addChild(_iconLayer);
         setNickName(null);
      }

      protected function createDressily(forbidden:Dictionary):IDressily
      {
         return new Dressily(forbidden, null);
      }

      final public function setDressily(d:IDressily):void
      {
         if (_dressily != null)
         {
            _dressily.removeEventListener(DressilyEvent.ACTION_BEGIN, relay);
            _dressily.removeEventListener(DressilyEvent.DRESS_COMPLETED, onDressed);
            if (_dressily.avatarSprite && _dressily.avatarSprite.parent == this) removeChild(_dressily.avatarSprite);
            _dressily.dispose();
         }
         _dressily = d;
         if (d == null) return;
         d.addEventListener(DressilyEvent.ACTION_BEGIN, relay);
         d.addEventListener(DressilyEvent.DRESS_COMPLETED, onDressed);
         if (d.avatarSprite) addChildAt(d.avatarSprite, numChildren > 0 ? 1 : 0);
      }

      final public function get dressily():IDressily
      {
         return _dressily;
      }

      final public function get avatarSprite():DisplayObject
      {
         return _dressily ? _dressily.avatarSprite : null;
      }

      public function get top():Number
      {
         var t:Number = _dressily ? _dressily.top : -80;
         return isNaN(t) || t == 0 ? -80 : t;
      }

      final public function action(code:String):void
      {
         if (_dressily) _dressily.action(code);
      }

      final public function currentAction():String
      {
         return _dressily ? _dressily.currentAction() : null;
      }

      final public function setAvatar(avatar:Object):void
      {
         if (_dressily) _dressily.setAvatar(avatar);
         onMoveStateChanged();
      }

      final public function getAvatar():AvatarInfo
      {
         return _dressily ? _dressily.getAvatar() : null;
      }

      /** In an upside-down scene (FlipSceneBase): the name plate and bubbles are turned back. */
      public function setFlip():void
      {
         _flipV = true;
         setNickName(_nickName);
      }

      public function get flipV():Boolean
      {
         return _flipV;
      }

      public function setNickName(nn:String):void
      {
         _nickName = nn;
         _nameField.text = nn ? nn : getName();
         _nameField.textColor = _member ? 0xFFCC00 : 0xFFFFFF;
         _nameField.x = -_nameField.width / 2;
         _nameField.y = _flipV ? 6 + _nameField.height : 6;
         _nameField.scaleY = _flipV ? -1 : 1;
      }

      public function get nickName():String
      {
         return _nickName ? _nickName : getName();
      }

      /** VIP (蓝宝石) players had their name shown in gold. */
      public function initMemberFormat():void
      {
         _member = true;
         setNickName(_nickName);
      }

      public function setNickNameVisible(v:Boolean):void
      {
         _nameField.visible = v;
      }

      public function addTopIcon(key:String, icon:DisplayObject):void
      {
         removeTopIcon(key);
         _topIcons[key] = icon;
         _topIconOrder.push(key);
         _iconLayer.addChild(icon);
         layoutIcons();
      }

      public function removeTopIcon(key:String):void
      {
         var icon:DisplayObject = _topIcons[key];
         if (icon == null) return;
         if (icon.parent) icon.parent.removeChild(icon);
         delete _topIcons[key];
         _topIconOrder.splice(_topIconOrder.indexOf(key), 1);
         layoutIcons();
      }

      private function layoutIcons():void
      {
         var y:Number = top - 4;
         for each (var key:String in _topIconOrder)
         {
            var icon:DisplayObject = _topIcons[key];
            icon.x = -icon.width / 2;
            y -= icon.height;
            icon.y = y;
         }
      }

      /** Marks my own player; the revival keeps the shadow under every player and adds nothing more. */
      final public function addSelfSymbol():void
      {
      }

      final public function addShadow():void
      {
         _shadow.visible = true;
      }

      /**
       * A speech bubble over the head (scene chat, NPC-like lines): drawn,
       * as the 2013 bubble art was in the lost control module. It stays
       * `seconds` seconds, by default longer for longer lines.
       */
      public function say(text:String, seconds:int = -1):void
      {
         clearBubble();
         if (text == null || text == "") return;
         _bubble = new Sprite();
         _bubble.mouseEnabled = _bubble.mouseChildren = false;
         var tf:TextField = new TextField();
         tf.defaultTextFormat = new TextFormat("SimSun", 12, 0x333333);
         tf.wordWrap = true;
         tf.multiline = true;
         tf.width = 140;
         tf.autoSize = TextFieldAutoSize.LEFT;
         tf.selectable = false;
         tf.text = text;
         var w:Number = Math.min(140, tf.textWidth + 6) + 14;
         var h:Number = tf.height + 8;
         var g:Graphics = _bubble.graphics;
         g.lineStyle(1.5, 0x5A8FC8);
         g.beginFill(0xFFFFFF, 0.95);
         g.drawRoundRect(-w / 2, -h, w, h, 14, 14);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.95);
         g.moveTo(-6, -1);
         g.lineTo(0, 8);
         g.lineTo(6, -1);
         g.endFill();
         g.lineStyle(1.5, 0x5A8FC8);
         g.moveTo(-6, 0);
         g.lineTo(0, 8);
         g.lineTo(6, 0);
         tf.x = -w / 2 + 7;
         tf.y = -h + 4;
         _bubble.addChild(tf);
         _bubble.y = Math.min(-60, top) - 8;
         if (_flipV)
         {
            _bubble.scaleY = -1;
            _bubble.y = Math.min(-60, top) - 8 - h - 8;
         }
         addChild(_bubble);
         _bubbleTimer = new Timer(1000 * (seconds > 0 ? seconds : Math.min(10, 4 + text.length / 8)), 1);
         _bubbleTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { clearBubble(); });
         _bubbleTimer.start();
      }

      /**
       * A face of baseservice/face (表情) over the head for a few seconds, in
       * place of a speech bubble; its animation plays once from the start.
       */
      public function showFace(face:DisplayObject, seconds:Number = 3):void
      {
         clearBubble();
         if (face == null) return;
         var holder:Sprite = new Sprite();
         holder.mouseEnabled = holder.mouseChildren = false;
         var b:Rectangle = face.getBounds(face);
         var k:Number = Math.min(1, 60 / Math.max(1, b.width), 60 / Math.max(1, b.height));
         face.scaleX = face.scaleY = k;
         face.x = -(b.left + b.width / 2) * k;
         face.y = -b.bottom * k;
         holder.addChild(face);
         holder.y = Math.min(-60, top) - 4;
         if (_flipV)
         {
            holder.scaleY = -1;
            holder.y = Math.min(-60, top) - 4 - b.height * k;
         }
         addChild(holder);
         if (face is MovieClip) MovieClip(face).gotoAndPlay(1);
         _bubble = holder;
         _bubbleTimer = new Timer(1000 * seconds, 1);
         _bubbleTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { clearBubble(); });
         _bubbleTimer.start();
      }

      private static function stopClips(d:DisplayObject):void
      {
         if (d is MovieClip) MovieClip(d).stop();
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c == null) return;
         for (var i:int = 0; i < c.numChildren; i++) stopClips(c.getChildAt(i));
      }

      private function clearBubble():void
      {
         if (_bubbleTimer) _bubbleTimer.stop();
         _bubbleTimer = null;
         if (_bubble) stopClips(_bubble);
         if (_bubble && _bubble.parent) _bubble.parent.removeChild(_bubble);
         _bubble = null;
      }

      override protected function onMoveStateChanged():void
      {
         if (_dressily == null) return;
         var cur:String = _dressily.currentAction();
         var want:String = directionCode + (isMoving() ? "wn" : "zn");
         if (cur != want) _dressily.action(want);
      }

      private function relay(e:DressilyEvent):void
      {
         dispatchEvent(new DressilyEvent(e.type, e.params));
      }

      private function onDressed(e:Event):void
      {
         onMoveStateChanged();
         layoutIcons();
      }

      override public function dispose():void
      {
         clearBubble();
         setDressily(null);
         super.dispose();
      }
   }
}
