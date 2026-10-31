package mmo.game.parkour.game.sceneitem.coin
{
   import flash.display.MovieClip;
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.data.mapitem.ParkourCoinInfo;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItemManager;
   import mmo.game.parkour.game.mapitem.move.ParkourMoveToPlayerStrategy;
   import mmo.game.parkour.game.player.ParkourPlayer;
   
   public class ParkourCoinManager extends ParkourAbstractMapItemManager
   {
      
      private var onlyCrateGoldCoin:Boolean = false;
      
      private var _logEatNum:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourCoinManager()
      {
         super([ParkourGameMapConfig.CoinGold,ParkourGameMapConfig.CoinSilver,ParkourGameMapConfig.CoinCuprum]);
      }
      
      public function setOnlyCrateGoldCoin(param1:Boolean) : void
      {
         this.onlyCrateGoldCoin = param1;
      }
      
      override public function create(param1:int, param2:Number, param3:Number) : Boolean
      {
         var _loc4_:int = param1;
         if(this.onlyCrateGoldCoin)
         {
            _loc4_ = ParkourGameMapConfig.CoinGold;
         }
         return super.create(_loc4_,param2,param3);
      }
      
      override protected function newInstance(param1:ParkourMapItemInfo, param2:MovieClip) : ParkourAbstractMapItem
      {
         return new ParkourCoin(param1 as ParkourCoinInfo,param2);
      }
      
      public function checkAbsorbByPlayer(param1:ParkourPlayer) : void
      {
         var _loc2_:ParkourCoin = null;
         if(!param1.param.absorbing)
         {
            return;
         }
         for each(_loc2_ in items)
         {
            if(ParkourGameConfig.MapRect.intersects(_loc2_.getRect()))
            {
               _loc2_.setMoveStrategy(new ParkourMoveToPlayerStrategy());
               _loc2_.isBeAbsorbing = true;
            }
         }
      }
      
      public function getAllCoins() : Array
      {
         return items;
      }
      
      public function changetCoinToGold(param1:ParkourCoin) : void
      {
         var _loc3_:ParkourCoin = null;
         if(param1.type == ParkourGameMapConfig.CoinGold)
         {
            return;
         }
         var _loc2_:int = items.indexOf(param1);
         if(_loc2_ != -1 && !param1.isBeAbsorbing)
         {
            _loc3_ = getItemFromPool(ParkourGameMapConfig.CoinGold) as ParkourCoin;
            _loc3_.x = param1.x;
            _loc3_.y = param1.y;
            _loc3_.reset();
            getContainer().addChild(_loc3_.view);
            items.splice(_loc2_,1,_loc3_);
            disposeItem(param1);
         }
      }
      
      public function checkHitPlayer(param1:ParkourPlayer) : void
      {
         var _loc2_:ParkourCoin = null;
         for each(_loc2_ in items)
         {
            if(!_loc2_.canDispose() && param1.isHit(_loc2_))
            {
               _loc2_.signDispose();
               ++this.logEatNum;
               param1.addScore(_loc2_.score);
               if(this.logEatNum >= 4)
               {
                  param1.param.power += 1;
                  this.logEatNum = 0;
               }
            }
         }
      }
      
      public function get logEatNum() : int
      {
         return this._logEatNum.getValue();
      }
      
      public function set logEatNum(param1:int) : void
      {
         this._logEatNum.setValue(param1);
      }
   }
}

