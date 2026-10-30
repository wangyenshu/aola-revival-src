package mmo.scene.cloudstar1
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IShowDataPanel;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneBase;
   
   /**
    * LATER scene/cloudstar1 (奇草树林, the 2024 copy's own code, decompiled)
    * on the 2013 interfaces and that copy's art: the 2013 scene is lost. The
    * copy lost the scene's map button but kept its handler (onMap: the era
    * 云端王国 map, scene/cloudstarmap of October 2012); REBUILT: a drawn
    * button (the 2013 icon is lost) opens it again.
    */
   public class CloudStar1 extends SceneBase
   {
      
      public var background:MovieClip;
      
      public var foreground:MovieClip;
      
      public var obstruction:MovieClip;
      
      public var overlap:MovieClip;
      
      public var topground:MovieClip;
      
      private var btnMap:InteractiveObject = null;
      
      public function CloudStar1()
      {
         super(520,400);
         this.addInitLocation("fromScene2To1",new Point(165,400));
         this.addInitLocation("fromScene3To1",new Point(730,345));
         this.addInitLocation("fromScene4To1",new Point(745,370));
         this.addInitLocation("fromScene5To1",new Point(318,347));
      }
      
      override protected function onJoinRoom() : void
      {
         super.onJoinRoom();
         this.btnMap = MapButton.make("云端王国地图");
         this.btnMap.x = 70;
         this.btnMap.y = 118;
         this.btnMap.addEventListener(MouseEvent.CLICK,this.onMap);
         this.topGround.addChild(this.btnMap);
         TipsManager.getInstance().addTips(this.btnMap,"云端王国地图");
         TipsManager.getInstance().addTips(this.foreground.et1,"魔法羽林");
         this.addEntrances(this.foreground.et1,"cloudstar2","fromScene1To2",null,FaceDirectionTypes.FACELEFTDOWN);
         TipsManager.getInstance().addTips(this.foreground.et2,"星芒小镇");
         this.addEntrances(this.foreground.et2,"cloudstar3","fromScene1To3",null,FaceDirectionTypes.FACERIGHTUP);
         TipsManager.getInstance().addTips(this.foreground.et3,"索尔石城");
         this.addEntrances(this.foreground.et3,"cloudstar4","fromScene1To4",null,FaceDirectionTypes.FACERIGHTDOWN);
         TipsManager.getInstance().addTips(this.foreground.et4,"参天瀑布");
         this.addEntrances(this.foreground.et4,"cloudstar5","fromScene1To5",null,FaceDirectionTypes.FACELEFTUP);
      }
      
      private function onMap(param1:MouseEvent) : void
      {
         var e:MouseEvent = param1;
         e.stopImmediatePropagation();
         SundriesClient.logEvent(64);
         SimpleCustomLoader.loadSingleResource("scene/cloudstarmap","mmo.scene.cloudstar.CloudStarMap",LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"正在加载，请稍候...",function(param1:IShowDataPanel):void
         {
            param1.showPanelByData(null);
         });
      }
      
      override protected function onLeaveRoom() : void
      {
         super.onLeaveRoom();
         if(null != this.btnMap)
         {
            this.btnMap.removeEventListener(MouseEvent.CLICK,this.onMap);
            this.btnMap = null;
         }
      }
   }
}

