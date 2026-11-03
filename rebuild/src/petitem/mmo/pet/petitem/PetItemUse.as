package mmo.pet.petitem
{
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.MaterialClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.material.petstone.EvolutionStone;
   import mmo.interfaces.material.petstone.IPetStoneService;
   import mmo.interfaces.material.petstone.SkillStone;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;

   /**
    * Using one item of the 亚比道具 page: a question first, then
    * MaterialClient.useItem (14_12 {ii, pi, pa, num}); the server says whether it
    * worked and what it did (petitems.ts), and the bag's 亚比 are asked for again.
    *
    * The later module's checks (written again here, its code being of the later
    * libraries): items that need no 亚比 (经验器, 学习器, 寻宝雷达, 自动战斗仪) ask
    * only whether to use them; a 进化石 or 技能石 says which 亚比 it is for; the rest
    * ask "你确定要对…使用…吗？". The server checks everything again.
    */
   public class PetItemUse
   {
      /** Used on no 亚比: they count the next wins. */
      private static const NO_TARGET:Array = [43, 44, 120, 62, 189, 378, 499, 663];
      /** Of the battle only (no status outlasts it). */
      private static const IN_BATTLE:Array = [94, 95, 96, 97, 98, 99, 100, 101];

      private var petId:Function;
      private var after:Function;
      private var busy:Boolean;

      public function PetItemUse(petId:Function, after:Function)
      {
         this.petId = petId;
         this.after = after;
      }

      public function useItem(u:UserItem):void
      {
         if (busy || u == null) return;
         var ii:int = u.materialId;
         var name:String = u.material ? u.material.name : "这个道具";
         if (IN_BATTLE.indexOf(ii) >= 0)
         {
            NewDialog.showMessage(name + "要在战斗中使用哦！战斗结束后，亚比的异常状态就会消失。");
            return;
         }
         if (NO_TARGET.indexOf(ii) >= 0)
         {
            ask("你确定要使用" + name + "吗？", ii, -1);
            return;
         }
         var pet:PetBriefInfo = selected();
         if (pet == null)
         {
            NewDialog.showMessage("请先在亚比背包里选择一只亚比。");
            return;
         }
         var pn:String = pet.nickname || pet.name;
         var q:String = "你确定要对" + pn + "使用" + name + "吗？";
         try
         {
            var stones:IPetStoneService = ServiceContainer.getService(IPetStoneService) as IPetStoneService;
            if (stones != null && stones.checkIsEvoStone(ii))
            {
               var evo:EvolutionStone = stones.getEvoStoneByItemId(ii);
               if (evo != null && evo.evoRaceId != pet.raceId)
               {
                  NewDialog.showFailMessage("这块" + name + "不能给" + pn + "使用哦！");
                  return;
               }
               q = "使用" + name + "后，" + pn + "会立刻进化。你确定要使用吗？";
            }
            else if (stones != null && stones.checkIsSkillStone(ii))
            {
               var sk:SkillStone = stones.getSkillStoneByItemId(ii);
               if (sk != null && sk.raceId != pet.raceId)
               {
                  NewDialog.showFailMessage(pn + "不能学习" + name + "哦！");
                  return;
               }
               if (sk != null && pet.level < sk.levelLimit)
               {
                  NewDialog.showFailMessage("只有达到" + sk.levelLimit + "级或以上，" + pn + "才可以学习" + name + "哦！");
                  return;
               }
            }
         }
         catch (e:Error) {}
         ask(q, ii, pet.id);
      }

      private function selected():PetBriefInfo
      {
         var id:int = -1;
         try { id = int(petId()); } catch (e:Error) {}
         if (id <= 0) return null;
         var data:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         return data ? data.getPetByPetId(id) : null;
      }

      private function ask(q:String, ii:int, pi:int):void
      {
         NewDialog.getCofirmDialog(q, function(d:ModalDialog):void
         {
            d.addEventListener(ModalDialogEvent.OK, function(e:ModalDialogEvent):void { send(ii, pi); });
            d.show();
         });
      }

      private function send(ii:int, pi:int):void
      {
         busy = true;
         SocketClient.instance.addEventListener(MaterialClient.cmdUsePetItem, onUsed);
         ProgressFullSprite.show();
         MaterialClient.getInstance().useItem(ii, pi, -1, 1);
      }

      private function onUsed(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(MaterialClient.cmdUsePetItem, onUsed);
         ProgressFullSprite.close();
         busy = false;
         var msg:String = e.params.msg ? String(e.params.msg) : "";
         if (int(e.params.res) == 1)
         {
            // The pets' new numbers (levels, 学习力, 性格, race): the bag shows them from viewAllPM.
            PetClient.instance.viewAllPM();
            if (msg) NewDialog.showSucceedMessage(msg);
         }
         else if (int(e.params.res) == -2) NewDialog.showFailMessage("物品正在使用中。");
         else NewDialog.showFailMessage(msg || "现在不能使用这个道具哦。");
         if (after != null) after();
      }

      public function dispose():void
      {
         SocketClient.instance.removeEventListener(MaterialClient.cmdUsePetItem, onUsed);
         after = null;
      }
   }
}
