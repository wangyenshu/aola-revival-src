package mmo.usercard
{
   import flash.utils.getTimer;
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.HTTPStatusEvent;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.SecurityErrorEvent;
   import flash.events.TimerEvent;
   import flash.external.ExternalInterface;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.IAlbumAvatarProxy;
   import mmo.interfaces.avatar.IAvatarService;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.material.clothes.Clothes;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.interfaces.material.clothes.UserClothes;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.VersManager;
   import mmo.revival.RAvatar;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.revival.SavePanels;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClientEvent;

   /**
    * REBUILT player card, drawn: the avatar on a stand, name, number and 晶币,
    * and for the player's own card the wardrobe: every owned piece of
    * clothing (icons from ClothesService.getView, i.e. the original
    * skinicon/ files), worn ones ticked; a click puts it on or takes it off
    * through ClothesService.wearMyOwnClothesById, which tells the server
    * (updateMyWearingClothes) and the scene re-dresses the player.
    */
   public class UserCardPanel extends Sprite
   {
      private static const W:int = 600;
      private static const H:int = 400;
      private static const COLS:int = 5;
      private static const ROWS:int = 4;

      private var userName:String;
      private var own:Boolean;
      private var box:Sprite;
      private var stand:Sprite;
      private var avatar:IAlbumAvatarProxy;
      private var grid:Sprite;
      private var pageText:TextField;
      private var page:int;
      private var clothes:IClothesService;

      public function UserCardPanel(userName:String, tab:int)
      {
         super();
         this.userName = userName;
         own = userName == SocketClient.instance.myUserName;
         try { clothes = ServiceContainer.getService(IClothesService) as IClothesService; } catch (e:Error) { RLog.error("usercard clothes", e); }
         build();
         LayerManager.getBaseTop().addChild(this);
         showAvatar();
         if (own) refreshGrid();
      }

      private function build():void
      {
         var dim:Sprite = new Sprite();
         dim.graphics.beginFill(0x000000, 0.3);
         dim.graphics.drawRect(0, 0, 960, 560);
         dim.graphics.endFill();
         dim.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); close(); });
         addChild(dim);

         box = new Sprite();
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         var m:Matrix = new Matrix();
         m.createGradientBox(W, H, Math.PI / 2);
         box.graphics.lineStyle(3, 0x2E86D6);
         box.graphics.beginGradientFill(GradientType.LINEAR, [0xEAF7FF, 0xBFE3FA], [1, 1], [0, 255], m);
         box.graphics.drawRoundRect(0, 0, W, H, 26, 26);
         box.graphics.endFill();
         box.filters = [new DropShadowFilter(4, 90, 0, 0.45, 10, 10)];
         box.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         addChild(box);

         var left:Shape = new Shape();
         left.graphics.beginFill(0xFFFFFF, 0.75);
         left.graphics.drawRoundRect(16, 16, 200, H - 32, 20, 20);
         left.graphics.endFill();
         left.graphics.beginFill(0x8FCFF5, 0.6);
         left.graphics.drawEllipse(46, 252, 140, 34);
         left.graphics.endFill();
         box.addChild(left);

         stand = new Sprite();
         stand.x = 116;
         stand.y = 268;
         box.addChild(stand);

         var name:TextField = text(16, 0x1A5FA8, true);
         name.text = nickName();
         name.x = 116 - name.width / 2;
         name.y = 290;
         box.addChild(name);
         var info:TextField = text(12, 0x335577, false);
         info.text = own ? "奥拉号：" + UserInfo.userId + "\n晶币：" + (UserInfo.score < 0 ? "…" : String(UserInfo.score)) : "";
         info.x = 40;
         info.y = 318;
         box.addChild(info);
         if (own) accountButtons();

         var title:TextField = text(16, 0x1A5FA8, true);
         title.text = own ? "我的衣橱" : nickName() + "的名片";
         title.x = 240;
         title.y = 20;
         box.addChild(title);

         if (own)
         {
            grid = new Sprite();
            grid.x = 236;
            grid.y = 52;
            box.addChild(grid);
            var prev:Sprite = textButton("◀", function():void { page--; refreshGrid(); });
            prev.x = 340;
            prev.y = H - 40;
            box.addChild(prev);
            pageText = text(13, 0x1A5FA8, true);
            pageText.y = H - 38;
            box.addChild(pageText);
            var next:Sprite = textButton("▶", function():void { page++; refreshGrid(); });
            next.x = 480;
            next.y = H - 40;
            box.addChild(next);
            var tip:TextField = text(12, 0x557799, false);
            tip.text = "点一下衣服就能穿上或脱下";
            tip.x = 240;
            tip.y = H - 62;
            box.addChild(tip);
         }

         var closeBtn:Sprite = new Sprite();
         closeBtn.buttonMode = true;
         closeBtn.graphics.lineStyle(2.5, 0xFFFFFF);
         closeBtn.graphics.beginFill(0xD9452B);
         closeBtn.graphics.drawCircle(0, 0, 14);
         closeBtn.graphics.endFill();
         closeBtn.graphics.lineStyle(3, 0xFFFFFF);
         closeBtn.graphics.moveTo(-5, -5); closeBtn.graphics.lineTo(5, 5);
         closeBtn.graphics.moveTo(5, -5); closeBtn.graphics.lineTo(-5, 5);
         closeBtn.x = W - 6;
         closeBtn.y = 6;
         closeBtn.name = "cardClose";
         closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); this_close(); });
         box.addChild(closeBtn);
         if (!own) otherButtons();
      }

      /**
       * Another 奥拉's card (a shared server): 加为好友, 去他家 (his 家园), 邀请组队 and 他的HELLO
       * (robot/robotanothermes). Server: social.ts; the home: HouseLoader.loadHouse(his name).
       */
      private function otherButtons():void
      {
         var acts:Array = [
            ["加为好友", function():void { ask("BuddyManagerExtension", "revival_friend_add", "revival_friend_add"); }],
            ["去他家", function():void
            {
               close();
               ServiceContainer.instance.tryGetService("HouseService", function(svc:*, o:Object = null):void
               {
                  try { Object(svc).houseLoader.loadHouse(userName); } catch (e:Error) { RLog.error("usercard home", e); }
               });
            }],
            ["邀请组队", function():void { ask("TeamExtension", "revival_team_invite", "revival_team_invite"); }],
            // 亚比对战 (a 切磋 on the revival's server, duel.ts): he answers, then both fight.
            ["亚比对战", function():void { ask("PocketMonsterExtension", "revival_duel_invite", "revival_duel_invite"); }],
            ["他的HELLO", function():void
            {
               close();
               try { Object(ServiceContainer.getService("RobotDataService")).setSelectRobotId(userName); } catch (e:Error) {}
               ServiceContainer.instance.tryGetService("RobotAnotherMes", function(svc:*, o:Object = null):void
               {
                  try { Object(svc).showPanel(); } catch (e:Error) { RLog.error("usercard hello", e); }
               });
            }]
         ];
         for (var i:int = 0; i < acts.length; i++)
         {
            var b:Sprite = RUI.button(acts[i][0], acts[i][1], 96, 30, i == 0 ? 0xFFC45A : 0x8FE3FF, i == 0 ? 0xF07812 : 0x1E8FE0, "cardAct" + i);
            b.x = 248 + (i % 2) * 110;
            b.y = 70 + int(i / 2) * 44;
            box.addChild(b);
         }
      }

      /**
       * One's own card: 改名字 (both modes) and, on a shared server, 改密码 (SavePanels; the data is
       * the page's, web/saves.js): a rename ends the game, and the page logs in again with the new name.
       */
      private function accountButtons():void
      {
         var acts:Array = [["改名字", SavePanels.rename]];
         if (pageMode() == "server") acts.push(["改密码", SavePanels.password]);
         for (var i:int = 0; i < acts.length; i++)
         {
            var b:Sprite = RUI.button(acts[i][0], closeThen(acts[i][1]), 80, 24, 0x8FE3FF, 0x1E8FE0, "cardAccount" + i);
            b.x = (acts.length == 1 ? 76 : 32 + i * 88);
            b.y = H - 46;
            box.addChild(b);
         }
      }

      /** The page's mode: "inpage" (单机模式) or "server" (联机模式); "" without a page. */
      private static function pageMode():String
      {
         try { if (ExternalInterface.available) return String(ExternalInterface.call("aolaRevivalMode") || ""); } catch (e:Error) {}
         return "";
      }

      /** The card closes, then f. */
      private function closeThen(f:Function):Function
      {
         return function():void
         {
            close();
            f();
         };
      }

      /** A request to the server whose reply {res, msg} is shown. */
      /** Requests sent and not yet answered, by their answer (getTimer() then): one at a time. */
      private static var waiting:Object = {};

      private function ask(ext:String, cmd:String, answer:String):void
      {
         var sc:SocketClient = SocketClient.instance;
         // A second click while the first waits is not sent again (its answer would be shown twice).
         if (waiting[answer] != null && getTimer() - int(waiting[answer]) < 8000) return;
         waiting[answer] = getTimer();
         var onReply:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(answer, onReply);
            delete waiting[answer];
            if (int(e.params.res) == 1) NewDialog.showSucceedMessage(String(e.params.msg));
            else NewDialog.showFailMessage(String(e.params.msg));
         };
         sc.addEventListener(answer, onReply);
         sc.sendXtMessage(ext, cmd, {name: userName});
      }

      private function this_close():void
      {
         close();
      }

      private function nickName():String
      {
         if (own)
         {
            try
            {
               var me:Object = PlayerManagerRef.myPlayer();
               if (me && me.hasOwnProperty("nickName")) return me.nickName;
            }
            catch (e:Error) {}
         }
         return userName;
      }

      private function showAvatar():void
      {
         if (clothes == null) return;
         try
         {
            var svc:IAvatarService = ServiceContainer.getService(IAvatarService) as IAvatarService;
            avatar = svc.getAlbumAvatarProxy();
            var sprite:Sprite = avatar.getSprite();
            stand.addChild(sprite);
            // The album avatar draws at its own size and origin: fit it on the stand once it has drawn.
            var fitAvatar:Function = function(e:Event = null):void
            {
               if (sprite.parent == null) { stand.removeEventListener(Event.ENTER_FRAME, fitAvatar); return; }
               sprite.scaleX = sprite.scaleY = 1;
               var b:Object = sprite.getBounds(sprite);
               if (b.height <= 1) return;
               var k:Number = Math.min(230 / b.height, 170 / b.width, 1.4);
               sprite.scaleX = sprite.scaleY = k;
               sprite.x = -(b.left + b.width / 2) * k;
               sprite.y = -b.bottom * k + 6;
            };
            stand.addEventListener(Event.ENTER_FRAME, fitAvatar);
            var mine:IAlbumAvatarProxy = avatar;
            var dress:Function = function(info:AvatarInfo):void
            {
               RAvatar.drawable(info, function(shown:AvatarInfo):void { if (avatar == mine && shown != null) avatar.setAvatarInfo(shown); });
            };
            if (own) dress(clothes.getMyAvatarInfo());
            else clothes.getOthersAvatarInfo(userName, dress);
         }
         catch (e:Error)
         {
            RLog.error("usercard avatar", e);
         }
      }

      private function refreshGrid():void
      {
         if (clothes == null || grid == null) return;
         while (grid.numChildren) grid.removeChildAt(0);
         var list:Array = clothes.getMyClothesInfos().filter(function(u:*, i:int, a:Array):Boolean
         {
            return u is UserClothes && UserClothes(u).materialId > 22; // 1-22 are the body itself
         });
         list.sortOn("materialId", Array.NUMERIC | Array.DESCENDING);
         var per:int = COLS * ROWS;
         var pages:int = Math.max(1, Math.ceil(list.length / per));
         page = Math.max(0, Math.min(page, pages - 1));
         pageText.text = (page + 1) + " / " + pages;
         pageText.x = 410 - pageText.width / 2;
         for (var i:int = 0; i < per && page * per + i < list.length; i++)
         {
            var uc:UserClothes = list[page * per + i];
            var cell:Sprite = cellFor(uc);
            cell.x = (i % COLS) * 68;
            cell.y = int(i / COLS) * 68;
            grid.addChild(cell);
         }
      }

      private function cellFor(uc:UserClothes):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.buttonMode = true;
         var worn:Boolean = uc.isWearing();
         cell.graphics.lineStyle(2, worn ? 0xFF9900 : 0x7FBDE6);
         cell.graphics.beginFill(0xFFFFFF, worn ? 1 : 0.8);
         cell.graphics.drawRoundRect(0, 0, 62, 62, 12, 12);
         cell.graphics.endFill();
         try
         {
            var icon:DisplayObject = clothes.getView(uc.materialId);
            var holder:Sprite = new Sprite();
            holder.mouseEnabled = holder.mouseChildren = false;
            cell.addChild(holder);
            if (icon == null)
            {
               // Not loaded yet: ClothesService.getView sends it later (MaterialServiceEvent.onGetView).
               var later:Function = function(e:MaterialServiceEvent):void
               {
                  if (e.params == null || int(e.params.id) != uc.materialId || !(e.params.view is DisplayObject)) return;
                  clothes.removeEventListener(MaterialServiceEvent.onGetView, later);
                  if (holder.numChildren == 0 && cell.parent != null) placeIcon(holder, DisplayObject(e.params.view));
               };
               clothes.addEventListener(MaterialServiceEvent.onGetView, later);
            }
            else
            {
               placeIcon(holder, icon);
            }
         }
         catch (e:Error) {}
         if (worn)
         {
            var tick:TextField = text(14, 0xFF7700, true);
            tick.text = "✔";
            tick.x = 44;
            tick.y = 0;
            cell.addChild(tick);
         }
         var tipText:String = uc.material ? uc.material.name : "";
         cell.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { showTip(tipText, cell); });
         cell.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { showTip(null, null); });
         cell.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            try
            {
               clothes.wearMyOwnClothesById(uc.materialId);
               redrawAvatar();
            }
            catch (err:Error)
            {
               RLog.error("usercard wear " + uc.materialId, err);
            }
            refreshGrid();
         });
         return cell;
      }

      /** An icon in its cell, fitted into the 62 px square once it has drawn. */
      private static function placeIcon(holder:Sprite, icon:DisplayObject):void
      {
         holder.addChild(icon);
         var fit:Function = function(e:Event = null):void
         {
            var b:Object = holder.getBounds(holder);
            if (b.width <= 0) return;
            var s:Number = Math.min(1.2, 52 / b.width, 52 / b.height);
            holder.scaleX = holder.scaleY = s;
            holder.x = 31 - (b.left + b.width / 2) * s;
            holder.y = 31 - (b.top + b.height / 2) * s;
         };
         fit();
         holder.addEventListener(Event.ENTER_FRAME, function(e:Event):void
         {
            fit();
            if (holder.width > 0) holder.removeEventListener(Event.ENTER_FRAME, arguments.callee);
         });
      }

      private var tip:TextField;

      private function showTip(s:String, at:Sprite):void
      {
         if (tip && tip.parent) tip.parent.removeChild(tip);
         tip = null;
         if (!s || at == null) return;
         tip = text(12, 0xFFFFFF, true);
         tip.background = true;
         tip.backgroundColor = 0x1A5FA8;
         tip.text = " " + s + " ";
         tip.x = at.x + grid.x;
         tip.y = at.y + grid.y - 18;
         box.addChild(tip);
      }

      private static function text(size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         return t;
      }

      private static function textButton(s:String, f:Function):Sprite
      {
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginFill(0x3A8FD9);
         b.graphics.drawRoundRect(0, 0, 34, 24, 18, 18);
         b.graphics.endFill();
         var t:TextField = text(13, 0xFFFFFF, true);
         t.text = s;
         t.x = (34 - t.width) / 2;
         t.y = 3;
         b.addChild(t);
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
         return b;
      }

      private var redraw:Timer;

      /**
       * After a change of clothes the stand's figure is drawn anew from a new
       * album avatar once the change has settled: setting the clothes on the
       * same album avatar twice in a row (put on, take off) could leave it
       * blank while its pieces were still loading.
       */
      private function redrawAvatar():void
      {
         if (redraw == null)
         {
            redraw = new Timer(350, 1);
            redraw.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void
            {
               if (parent == null) return;
               if (avatar != null)
               {
                  try { avatar.dispose(); } catch (err:Error) {}
                  avatar = null;
               }
               while (stand.numChildren > 0) stand.removeChildAt(0);
               showAvatar();
            });
         }
         redraw.reset();
         redraw.start();
      }

      public function close():void
      {
         if (redraw != null) redraw.stop();
         if (avatar != null)
         {
            try { avatar.dispose(); } catch (e:Error) {}
            avatar = null;
         }
         if (parent) parent.removeChild(this);
      }
   }
}
