package mmo.shoot.players.effects
{
   import mmo.interfaces.shoot.data.ShootTargetEffectTypes;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class EffectFactory
   {
      
      private static const replacePetClothes:Object = {
         "3":21001,
         "6":20068,
         "7":20053,
         "8":20069,
         "9":20054,
         "10":20132,
         "11":20137,
         "12":20052,
         "13":20049,
         "15":20126,
         "16":20127,
         "17":20134,
         "18":20138,
         "19":20279,
         "22":20344,
         "23":20226,
         "24":20285,
         "25":20278,
         "26":20166,
         "27":20169,
         "28":20184,
         "29":20187,
         "30":20200,
         "31":20209,
         "32":20282,
         "33":20409,
         "1034":20445,
         "35":20446,
         "37":20463,
         "38":29995,
         "41":29997,
         "44":29996,
         "48":20494,
         "49":20533,
         "50":20516,
         "52":29998,
         "53":29993,
         "54":29992,
         "55":29991,
         "57":29989,
         "59":29973,
         "60":29972,
         "61":29951,
         "62":29952,
         "63":29941,
         "64":29942,
         "65":29943,
         "66":29943,
         "67":29988,
         "68":29971,
         "69":29970,
         "70":20534,
         "71":21126,
         "72":29939,
         "73":29945,
         "74":29946,
         "75":"6;7;132;1533;1534;1535;1536",
         "76":29944,
         "77":29937,
         "84":"6;7;126;132;741;742",
         "85":29952,
         "86":20393,
         "88":29913,
         "89":29914,
         "90":29911,
         "91":29912,
         "98":29905,
         "99":29906,
         "100":29896,
         "101":29897,
         "113":29869,
         "114":29870,
         "115":29871,
         "116":29872,
         "117":22135,
         "118":22144,
         "119":29827,
         "120":22220,
         "121":29813,
         "122":29814,
         "123":22225,
         "124":29811,
         "125":29806,
         "126":29807,
         "127":29808,
         "131":29805,
         "132":29805,
         "133":29804,
         "134":29803,
         "142":80001,
         "143":80002,
         "144":80003,
         "145":80004,
         "151":29562,
         "152":29563,
         "153":29561,
         "155":29553,
         "156":29552,
         "157":29551,
         "158":29510,
         "159":29508,
         "160":29509,
         "161":29491,
         "162":29452,
         "163":29442,
         "164":29443,
         "165":29444,
         "166":29445,
         "167":29452,
         "168":22736,
         "5000":29856,
         "5001":29857,
         "5002":29854,
         "5003":29855,
         "5004":29951,
         "5007":29839,
         "5008":29840,
         "5009":29838,
         "5010":29837,
         "5011":29718,
         "5012":29720,
         "5013":29721,
         "5014":29719,
         "5016":29713,
         "5017":29714,
         "5018":29715,
         "5019":29716,
         "5020":29717,
         "5021":20273,
         "5022":29532,
         "5023":29533,
         "5024":29534,
         "5025":29535,
         "5026":29536,
         "5027":29537,
         "5028":29526,
         "5029":29527,
         "5030":29528,
         "5031":29529,
         "5032":29530,
         "5033":29531,
         "5034":29493,
         "5035":29494
      };
      
      private static const compositeEffect:Object = {
         "34":"1_1034",
         "51":"1_2002",
         "5005":"1_5004",
         "5006":"1_2002_2004",
         "141":"2_2003"
      };
      
      public function EffectFactory()
      {
         super();
      }
      
      public static function getSingleEffect(param1:PlayerBase, param2:int) : PlayerEffectBase
      {
         if(replacePetClothes.hasOwnProperty(param2 + ""))
         {
            return new ReplaceEffect(param1,{
               "clothes":replacePetClothes[param2],
               "targetEffect":param2
            });
         }
         switch(param2)
         {
            case ShootTargetEffectTypes.Decelerate:
               return new DecelerateEffect(param1,null);
            case ShootTargetEffectTypes.Forbid:
               return new ForbidEffect(param1,null);
            case ShootTargetEffectTypes.ZoomOut:
               return new ZoomOutEffect(param1,null);
            case ShootTargetEffectTypes.Freeze:
               return new FreezeEffect(param1,null);
            case ShootTargetEffectTypes.Burn:
               return new BurnEffect(param1,null);
            case ShootTargetEffectTypes.RomdonReplace:
               return new RomdonReplaceEffect(param1,null);
            case ShootTargetEffectTypes.FirecrakerEffect:
               return new FirecrackerEffect(param1,null);
            case 78:
               return new RomdonReplacePlayerEffect(param1,"29929,29930,29931;33,66,100");
            case 82:
               return new BossBurnEffect(param1,null);
            case 83:
               return new BossFetterEffect(param1,null);
            case 107:
               return new ActPimientoMovieEffect(param1,null);
            case 108:
               return new ActCakeMovieEffect(param1,null);
            case 2004:
               return new IceFetterEffect(param1,null);
            default:
               return null;
         }
      }
      
      public static function getEffect(param1:PlayerBase, param2:int) : PlayerEffectBase
      {
         var _loc3_:PlayerEffectBase = getSingleEffect(param1,param2);
         if(_loc3_ != null)
         {
            return _loc3_;
         }
         if(compositeEffect.hasOwnProperty(param2 + ""))
         {
            return new CompositeEffect(param1,{
               "compositeEffect":compositeEffect[param2],
               "targetEffect":param2
            });
         }
         return null;
      }
   }
}

