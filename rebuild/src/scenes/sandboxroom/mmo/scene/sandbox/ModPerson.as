package mmo.scene.sandbox
{
   import com.greensock.TweenLite;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.revival.RDef;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.revival.mod.IModNpc;

   /**
    * REVIVAL. A character or an opponent a mod puts in its room
    * (IModRoom.npc, IModRoom.foe): its look, its name under it, clicked: the
    * player walks up to it, then its onClick (a character) or the fight with
    * its team (an opponent, which goes away when beaten).
    */
   public class ModPerson extends Sprite implements IModNpc
   {
      private var room:SandboxRoom;
      private var def:Object;
      private var look:DisplayObject;
      /** The look in its holder (as drawn in the room). */
      private var art:DisplayObject;
      private var foe:Boolean;
      private var run:Object;
      private var tag:TextField;
      private var gone:Boolean;

      public function ModPerson(room:SandboxRoom, def:Object, look:DisplayObject, foe:Boolean, run:Object)
      {
         super();
         this.room = room;
         this.def = def;
         this.look = look;
         this.foe = foe;
         this.run = run;
         buttonMode = true;
         if (look != null)
         {
            // Scaled in a holder of its own: a look the mod shows again keeps its own size.
            var k:Number = (Number(def.scale) || 1) * (foe && def.boss ? 1.5 : 1);
            var holder:Sprite = new Sprite();
            holder.scaleX = holder.scaleY = k;
            holder.addChild(look);
            addChild(holder);
            art = holder;
         }
         var label:String = def.name ? String(def.name) : (foe ? (def.boss ? "首领" : "对手") : "");
         if (foe && def.team is Array && def.team.length > 0)
         {
            var n:int = def.team.length;
            label += (n > 1 ? "（" + n + "只亚比）" : "") + " Lv" + int(def.team[0].level || 1);
         }
         if (label)
         {
            tag = RUI.text(12, foe ? (def.boss ? 0xFFE27A : 0xFFFFFF) : 0xFFFFFF, true);
            tag.filters = [new GlowFilter(foe ? 0x40140A : 0x0B2440, 1, 3, 3, 6)];
            tag.text = label;
            tag.x = -tag.width / 2;
            tag.y = 6;
            tag.mouseEnabled = false;
            addChild(tag);
         }
         name = "modPerson_" + (def.name ? String(def.name) : "");
         x = Number(def.x) || 0;
         y = Number(def.y) || 0;
         // The name is written under it already: a tip only when given, or to say a click fights.
         var tip:String = def.tip ? String(def.tip) : (foe ? "点击挑战" : "");
         if (tip) try { TipsManager.getInstance().addTips(this, tip); } catch (e:Error) {}
         room.place(this);
      }

      /** The player has walked up to it. */
      internal function clicked():void
      {
         if (gone) return;
         if (!foe)
         {
            if (def.onClick is Function)
            {
               try { def.onClick(); } catch (e:Error) { RLog.error("mod npc " + def.name, e); }
            }
            return;
         }
         if (run == null || !(def.team is Array) || def.team.length == 0) return;
         run.fight(def.team, function(win:Boolean):void
         {
            if (win) remove();
            var f:Function = (win ? def.onWin : def.onLose) as Function;
            if (f != null)
            {
               try { f(); } catch (e:Error) { RLog.error("mod foe " + def.name, e); }
            }
         }, def.heal !== false);
      }

      public function get view():DisplayObject
      {
         return look;
      }

      public function get npcName():String
      {
         return def && def.name ? String(def.name) : "";
      }

      public function say(text:String, seconds:Number = 3):void
      {
         room.say(this, text, seconds);
      }

      public function talk(pages:Array, done:Function = null):void
      {
         if (run == null) return;
         run.talk({name: def.name ? String(def.name) : "", picture: portrait()}, pages, done);
      }

      /** The picture for a conversation: the mod's, its 亚比's, or one taken of its look. */
      private function portrait():DisplayObject
      {
         if (def.picture is DisplayObject) return DisplayObject(def.picture);
         if (def.picture is Class || def.look is Class)
         {
            try { return new (def.picture is Class ? def.picture : def.look)() as DisplayObject; } catch (e:Error) {}
         }
         if (!(def.look is DisplayObject) && int(def.look) > 0 && RDef.has("mmo.pet.peticon" + int(def.look) + "_L"))
            return RDef.make("mmo.pet.peticon" + int(def.look) + "_L") as DisplayObject;
         if (art == null) return null;
         try
         {
            var b:Object = art.getBounds(this);
            if (b.width < 2 || b.height < 2) return null;
            var bd:BitmapData = new BitmapData(Math.ceil(b.width), Math.ceil(b.height), true, 0);
            var m:Matrix = art.transform.matrix.clone();
            m.translate(-b.x, -b.y);
            bd.draw(art, m);
            var pic:Bitmap = new Bitmap(bd, "auto", true);
            pic.x = b.x;
            pic.y = b.y;
            var s:Sprite = new Sprite();
            s.addChild(pic);
            return s;
         }
         catch (e2:Error) {}
         return null;
      }

      public function moveTo(x:Number, y:Number, seconds:Number = 1, then:Function = null):void
      {
         TweenLite.to(this, Math.max(0.01, seconds), {x: x, y: y, onComplete: function():void
         {
            if (then == null || gone) return;
            try { then(); } catch (e:Error) { RLog.error("mod moveTo", e); }
         }});
      }

      public function remove():void
      {
         if (gone) return;
         gone = true;
         TweenLite.killTweensOf(this);
         room.unplace(this);
      }

      internal function dispose():void
      {
         gone = true;
         TweenLite.killTweensOf(this);
      }
   }
}
