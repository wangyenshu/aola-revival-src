package mmo.thinktower.interact
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.thinktower.IThinkTower;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class IceWalkInteract implements Iinteract
   {
      
      private var params:Array;
      
      private var fun:Function;
      
      private var isCheck:Boolean = false;
      
      private var myplayer:PlayerBase;
      
      public function IceWalkInteract()
      {
         super();
      }
      
      public function dispose() : void
      {
         if(this.params == null)
         {
            return;
         }
         if(MovieClip(this.params[0]) != null)
         {
            MovieClip(this.params[0]).removeEventListener(Event.ENTER_FRAME,this.onEnterframe);
         }
         this.params = null;
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         this.params = param1;
         this.fun = param2;
         MovieClip(param1[0]).addEventListener(Event.ENTER_FRAME,this.onEnterframe);
         this.myplayer = PlayerManager.getInstance().myPlayer;
      }
      
      private function onEnterframe(param1:Event) : void
      {
         var thinkservice:IThinkTower = null;
         var evt:Event = param1;
         if(this.isCheck)
         {
            return;
         }
         if(!MovieClip(this.params[2]).hitTestPoint(this.myplayer.x,this.myplayer.y))
         {
            return;
         }
         this.isCheck = true;
         this.myplayer.stop();
         thinkservice = ServiceContainer.getService(IThinkTower) as IThinkTower;
         if(thinkservice.icecount > 0)
         {
            ModalDialogManager.getInstance().addModalDialog(MovieClip(this.params[4]));
            MovieClip(this.params[4]).getChildByName("btnOk").addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
            {
               MovieClip(params[0]).gotoAndPlay(2);
               MovieClip(params[2]).visible = false;
               --thinkservice.icecount;
               removePanel();
               if(fun != null)
               {
                  fun.apply(null,[-1,params[3]]);
               }
               dispose();
            });
            MovieClip(this.params[4]).getChildByName("btnClose").addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
            {
               removePanel();
               playMovie();
            });
         }
         else
         {
            this.playMovie();
         }
      }
      
      private function playMovie() : void
      {
         var sp:Sprite = null;
         sp = new Sprite();
         MovieClip(this.params[2]).addFrameScript(1,function():void
         {
            ModalDialogManager.getInstance().addModalDialog(sp,AlignType.NONE,PanelEffect.NONE,false);
         },65,function():void
         {
            myplayer.visible = false;
         },MovieClip(this.params[2]).totalFrames - 1,function():void
         {
            MovieClip(params[2]).gotoAndStop(1);
            myplayer.visible = true;
            myplayer.jumpTo(Point(params[1]).x,Point(params[1]).y);
            isCheck = false;
            ModalDialogManager.getInstance().removeModalDialog(sp);
            if(fun != null)
            {
               fun.apply(null,[parseInt(MovieClip(params[0]).name.substr(5)),params[3]]);
            }
            dispose();
         });
         MovieClip(this.params[2]).gotoAndPlay(2);
      }
      
      private function removePanel() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(MovieClip(this.params[4]));
      }
   }
}

