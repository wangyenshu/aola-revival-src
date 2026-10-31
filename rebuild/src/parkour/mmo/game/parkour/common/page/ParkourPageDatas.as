package mmo.game.parkour.common.page
{
   public class ParkourPageDatas
   {
      
      private var datas:Array;
      
      private var numPerPage:int;
      
      private var totalPage:int;
      
      public function ParkourPageDatas(param1:Array, param2:int)
      {
         super();
         this.numPerPage = param2;
         this.updateData(param1);
      }
      
      public function get getTotalPage() : int
      {
         return this.totalPage;
      }
      
      public function totalDataCount() : int
      {
         return this.datas.length;
      }
      
      public function deleteData(param1:Object) : void
      {
         var _loc3_:Object = null;
         var _loc2_:int = 0;
         while(_loc2_ < this.datas.length)
         {
            _loc3_ = this.datas[_loc2_] as Object;
            if(_loc3_ == param1)
            {
               this.datas.splice(_loc2_,1);
               break;
            }
            _loc2_++;
         }
      }
      
      public function updateData(param1:Array, param2:int = -1) : void
      {
         this.datas = param1;
         if(param2 != -1)
         {
            this.numPerPage = param2;
         }
         this.totalPage = (param1.length - 1) / this.numPerPage + 1;
         if(this.totalPage == 0)
         {
            this.totalPage = 1;
         }
      }
      
      public function getPageData(param1:int) : Array
      {
         var _loc4_:int = 0;
         if(param1 <= 0)
         {
            throw new Error("page <= 0");
         }
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         while(_loc3_ < this.numPerPage)
         {
            _loc4_ = _loc3_ + this.numPerPage * (param1 - 1);
            if(_loc4_ >= this.datas.length)
            {
               break;
            }
            _loc2_.push(this.datas[_loc4_]);
            _loc3_++;
         }
         return _loc2_;
      }
   }
}

