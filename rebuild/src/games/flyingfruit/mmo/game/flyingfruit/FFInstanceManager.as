package mmo.game.flyingfruit
{
   import mmo.game.flyingfruit.event.FFEnterFrameManager;
   import mmo.game.flyingfruit.fruit.FruitManager;
   import mmo.game.flyingfruit.panel.MainPanel;
   
   public class FFInstanceManager
   {
      
      private static var _instance:FFInstanceManager = null;
      
      private var addManager:FFAdderManager = null;
      
      private var enterFrameMnger:FFEnterFrameManager = null;
      
      private var diskMnger:FruitManager = null;
      
      private var mainPnl:MainPanel = null;
      
      private var hitMnger:FFHitManager = null;
      
      public function FFInstanceManager()
      {
         super();
      }
      
      public static function instance() : FFInstanceManager
      {
         if(_instance == null)
         {
            _instance = new FFInstanceManager();
         }
         return _instance;
      }
      
      public function get adderManager() : FFAdderManager
      {
         if(this.addManager == null)
         {
            this.addManager = new FFAdderManager();
         }
         return this.addManager;
      }
      
      public function get enterFrameManager() : FFEnterFrameManager
      {
         if(this.enterFrameMnger == null)
         {
            this.enterFrameMnger = new FFEnterFrameManager();
         }
         return this.enterFrameMnger;
      }
      
      public function get diskManager() : FruitManager
      {
         if(this.diskMnger == null)
         {
            this.diskMnger = new FruitManager();
         }
         return this.diskMnger;
      }
      
      public function get mainPanel() : MainPanel
      {
         if(this.mainPnl == null)
         {
            this.mainPnl = new MainPanel();
         }
         return this.mainPnl;
      }
      
      public function get hitManager() : FFHitManager
      {
         if(this.hitMnger == null)
         {
            this.hitMnger = new FFHitManager();
         }
         return this.hitMnger;
      }
      
      public function dispose() : void
      {
         if(this.addManager != null)
         {
            this.addManager.dispose();
         }
         if(this.enterFrameMnger != null)
         {
            this.enterFrameMnger.dispose();
         }
         if(this.diskMnger != null)
         {
            this.diskMnger.dispose();
         }
         if(this.mainPnl != null)
         {
            this.mainPnl.dispose();
         }
         if(this.hitMnger != null)
         {
            this.hitMnger.dispose();
         }
         this.addManager = null;
         this.enterFrameMnger = null;
         this.diskMnger = null;
         this.mainPnl = null;
         this.hitMnger = null;
         _instance = null;
      }
   }
}

