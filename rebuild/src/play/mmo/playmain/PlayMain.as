package mmo.playmain
{
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.config.ConfigReader;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.CustomLoader;
   import mmo.loader.CustomLoaderEvent;
   import mmo.loader.LoaderFacade;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.domain.ApplicationDomainGetter;
   import mmo.loader.scheduler.ResPriority;
   import mmo.play.DocPlayEngine;

   /**
    * REBUILT. The January 2013 play.swf (v130110) did not survive.
    *
    * LoaderFacade.loadPlay() loads this file and calls init() on it. Like the
    * original it creates the ServiceContainer, loads the <play> modules from
    * config.xml into the main application domain, starts every <service> that
    * implements IInitService, and then enters the default scene through the
    * Control service.
    */
   public class PlayMain extends Sprite
   {
      private var loader:CustomLoader;
      /** The rebuilt scene engine rides in this file (see DocPlayEngine). */
      private static const ENGINE:Class = DocPlayEngine;

      public function PlayMain()
      {
         super();
      }

      public function init():void
      {
         if (ServiceContainer.instance == null)
         {
            new ServiceContainer();
         }
         var files:Array = ConfigReader.instance.playFiles;
         loader = new CustomLoader(ResPriority.HIGH, false, ApplicationDomainGetter.getMainDomain());
         loader.addEventListener(CustomLoaderEvent.onLoadCompleted, onPlayLoaded);
         loader.addEventListener(CustomLoaderEvent.onError, onPlayError);
         loader.load(files, LoadingSpriteType.FULL_SCREEN, false, "正在进入奥拉星……");
      }

      private function onPlayError(e:CustomLoaderEvent):void
      {
         trace("[play] module failed to load: " + e.file);
      }

      private function onPlayLoaded(e:CustomLoaderEvent):void
      {
         loader.removeEventListener(CustomLoaderEvent.onLoadCompleted, onPlayLoaded);
         loader.removeEventListener(CustomLoaderEvent.onError, onPlayError);
         loader.close();
         loader = null;
         LoaderFacade.closeLoadPlay();
         var names:Array = ConfigReader.instance.services;
         for each (var name:String in names)
         {
            try
            {
               var service:IInitService = ServiceContainer.getService(name) as IInitService;
               if (service != null)
               {
                  service.init();
               }
            }
            catch (err:Error)
            {
               trace("[play] service " + name + " failed: " + err.message);
            }
         }
      }
   }
}
