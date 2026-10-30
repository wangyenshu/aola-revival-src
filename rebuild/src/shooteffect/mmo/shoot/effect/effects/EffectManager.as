package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   import flash.utils.getDefinitionByName;
   import mmo.shoot.effect.beam.BeamInfo;
   
   public class EffectManager
   {
      
      public static const instance:EffectManager = new EffectManager();
      
      internal var cardEffects:Object = {};
      
      internal var beamMap:Object = {};
      
      internal var collectBeamMap:Object = {};
      
      public function EffectManager()
      {
         super();
         this.cardEffects["1"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect1_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect1",
            "effectMovie":"mmo.shoot.effect.effects.EffectMovie1"
         };
         this.cardEffects["2"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect2",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect2_Beam",BeamInfo.BEAM_TYPE_MOVIECLIP,1300),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect2",
            "effectMovie":"mmo.shoot.effect.effects.EffectMovie2"
         };
         this.cardEffects["3"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect3"
         };
         this.cardEffects["4"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect4"
         };
         this.cardEffects["5"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect5_Beam",BeamInfo.BEAM_TYPE_MOVIECLIP,1315),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect5"
         };
         this.cardEffects["6"] = this.cardEffects["4"];
         this.cardEffects["7"] = this.cardEffects["4"];
         this.cardEffects["8"] = this.cardEffects["4"];
         this.cardEffects["9"] = this.cardEffects["4"];
         this.cardEffects["10"] = this.cardEffects["4"];
         this.cardEffects["11"] = this.cardEffects["4"];
         this.cardEffects["12"] = this.cardEffects["4"];
         this.cardEffects["13"] = this.cardEffects["4"];
         this.cardEffects["14"] = this.cardEffects["4"];
         this.cardEffects["15"] = this.cardEffects["4"];
         this.cardEffects["16"] = this.cardEffects["4"];
         this.cardEffects["17"] = this.cardEffects["4"];
         this.cardEffects["18"] = this.cardEffects["4"];
         this.cardEffects["19"] = this.cardEffects["4"];
         this.cardEffects["20"] = this.cardEffects["4"];
         this.cardEffects["21"] = this.cardEffects["4"];
         this.cardEffects["23"] = this.cardEffects["4"];
         this.cardEffects["24"] = this.cardEffects["4"];
         this.cardEffects["25"] = this.cardEffects["4"];
         this.cardEffects["26"] = this.cardEffects["4"];
         this.cardEffects["27"] = this.cardEffects["4"];
         this.cardEffects["28"] = this.cardEffects["4"];
         this.cardEffects["29"] = this.cardEffects["4"];
         this.cardEffects["30"] = this.cardEffects["4"];
         this.cardEffects["31"] = this.cardEffects["4"];
         this.cardEffects["32"] = this.cardEffects["4"];
         this.cardEffects["33"] = this.cardEffects["4"];
         this.cardEffects["37"] = this.cardEffects["4"];
         this.cardEffects["56"] = this.cardEffects["4"];
         this.cardEffects["61"] = this.cardEffects["4"];
         this.cardEffects["62"] = this.cardEffects["4"];
         this.cardEffects["70"] = this.cardEffects["4"];
         this.cardEffects["71"] = this.cardEffects["4"];
         this.cardEffects["76"] = this.cardEffects["4"];
         this.cardEffects["78"] = this.cardEffects["4"];
         this.cardEffects["98"] = this.cardEffects["4"];
         this.cardEffects["99"] = this.cardEffects["4"];
         this.cardEffects["100"] = this.cardEffects["4"];
         this.cardEffects["101"] = this.cardEffects["4"];
         this.cardEffects["107"] = this.cardEffects["4"];
         this.cardEffects["108"] = this.cardEffects["4"];
         this.cardEffects["110"] = this.cardEffects["4"];
         this.cardEffects["111"] = this.cardEffects["4"];
         this.cardEffects["112"] = this.cardEffects["4"];
         this.cardEffects["5000"] = this.cardEffects["4"];
         this.cardEffects["5001"] = this.cardEffects["4"];
         this.cardEffects["5028"] = this.cardEffects["4"];
         this.cardEffects["5029"] = this.cardEffects["4"];
         this.cardEffects["5030"] = this.cardEffects["4"];
         this.cardEffects["5031"] = this.cardEffects["4"];
         this.cardEffects["5032"] = this.cardEffects["4"];
         this.cardEffects["5033"] = this.cardEffects["4"];
         this.cardEffects["117"] = this.cardEffects["4"];
         this.cardEffects["118"] = this.cardEffects["4"];
         this.cardEffects["119"] = this.cardEffects["4"];
         this.cardEffects["120"] = this.cardEffects["4"];
         this.cardEffects["121"] = this.cardEffects["4"];
         this.cardEffects["122"] = this.cardEffects["4"];
         this.cardEffects["123"] = this.cardEffects["4"];
         this.cardEffects["124"] = this.cardEffects["4"];
         this.cardEffects["125"] = this.cardEffects["4"];
         this.cardEffects["126"] = this.cardEffects["4"];
         this.cardEffects["127"] = this.cardEffects["4"];
         this.cardEffects["128"] = this.cardEffects["4"];
         this.cardEffects["129"] = this.cardEffects["4"];
         this.cardEffects["130"] = this.cardEffects["4"];
         this.cardEffects["131"] = this.cardEffects["4"];
         this.cardEffects["132"] = this.cardEffects["4"];
         this.cardEffects["133"] = this.cardEffects["4"];
         this.cardEffects["134"] = this.cardEffects["4"];
         this.cardEffects["135"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect135_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect135"
         };
         this.cardEffects["136"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect136_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect136"
         };
         this.cardEffects["137"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect137_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect137"
         };
         this.cardEffects["138"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect138_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10020"
         };
         this.cardEffects["139"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect139_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10021"
         };
         this.cardEffects["140"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect105"
         };
         this.cardEffects["141"] = this.cardEffects["1"];
         this.cardEffects["142"] = this.cardEffects["4"];
         this.cardEffects["143"] = this.cardEffects["4"];
         this.cardEffects["144"] = this.cardEffects["4"];
         this.cardEffects["145"] = this.cardEffects["4"];
         this.cardEffects["146"] = this.cardEffects["4"];
         this.cardEffects["147"] = this.cardEffects["4"];
         this.cardEffects["151"] = this.cardEffects["4"];
         this.cardEffects["152"] = this.cardEffects["4"];
         this.cardEffects["153"] = this.cardEffects["4"];
         this.cardEffects["158"] = this.cardEffects["4"];
         this.cardEffects["159"] = this.cardEffects["4"];
         this.cardEffects["160"] = this.cardEffects["4"];
         this.cardEffects["163"] = this.cardEffects["4"];
         this.cardEffects["164"] = this.cardEffects["4"];
         this.cardEffects["165"] = this.cardEffects["4"];
         this.cardEffects["166"] = this.cardEffects["4"];
         this.cardEffects["168"] = this.cardEffects["4"];
         this.cardEffects["34"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect7_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect8"
         };
         this.cardEffects["35"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect6_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect7"
         };
         this.cardEffects["36"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect8_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect9"
         };
         this.cardEffects["38"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect9_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10"
         };
         this.cardEffects["39"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect10_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect11"
         };
         this.cardEffects["40"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect11_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect12"
         };
         this.cardEffects["41"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect12_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect13"
         };
         this.cardEffects["42"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect13_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect14"
         };
         this.cardEffects["43"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect14_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect15"
         };
         this.cardEffects["44"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect15_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect16"
         };
         this.cardEffects["45"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect16_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect17"
         };
         this.cardEffects["46"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect17_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect18"
         };
         this.cardEffects["47"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect18_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect19"
         };
         this.cardEffects["22"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect5",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect6_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect6"
         };
         this.cardEffects["51"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect19_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect20"
         };
         this.cardEffects["52"] = this.cardEffects["4"];
         this.cardEffects["58"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect20_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect21"
         };
         this.cardEffects["60"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect21_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect22"
         };
         this.cardEffects["79"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect23"
         };
         this.cardEffects["80"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect24"
         };
         this.cardEffects["81"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect25"
         };
         this.cardEffects["92"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect22_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect26"
         };
         this.cardEffects["93"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect23_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect27"
         };
         this.cardEffects["94"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect24_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect28"
         };
         this.cardEffects["95"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect25_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect29"
         };
         this.cardEffects["96"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect26_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect24"
         };
         this.cardEffects["97"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect27_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect30"
         };
         this.cardEffects["102"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect4"
         };
         this.cardEffects["103"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect4"
         };
         this.cardEffects["104"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect4"
         };
         this.cardEffects["105"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect105"
         };
         this.cardEffects["106"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect106"
         };
         this.cardEffects["107"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect1_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect1",
            "effectMovie":"mmo.shoot.effect.effects.EffectMovie3"
         };
         this.cardEffects["108"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect1_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect1",
            "effectMovie":"mmo.shoot.effect.effects.EffectMovie4"
         };
         this.cardEffects["110"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect110"
         };
         this.cardEffects["111"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect111"
         };
         this.cardEffects["112"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect112"
         };
         this.cardEffects["113"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect113_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect113"
         };
         this.cardEffects["114"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect114_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect1114"
         };
         this.cardEffects["115"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect1",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect114_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect115"
         };
         this.cardEffects["117"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect4"
         };
         this.cardEffects["118"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect4"
         };
         this.cardEffects["54"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect147_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,140)
         };
         this.cardEffects["147"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect147_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,48)
         };
         this.cardEffects["148"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect148_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,110)
         };
         this.cardEffects["149"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect149_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,100)
         };
         this.cardEffects["150"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect150_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,140)
         };
         this.cardEffects["154"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect140_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect138"
         };
         this.cardEffects["161"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect161_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect161"
         };
         this.cardEffects["162"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect162_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect162"
         };
         this.cardEffects["167"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect4",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect162_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect162"
         };
         this.cardEffects["402"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect402_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,47)
         };
         this.cardEffects["586"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect586_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,47)
         };
         this.cardEffects["2751"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect2751_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,15 * 60)
         };
         this.cardEffects["2752"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect2752_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,15 * 60)
         };
         this.cardEffects["2753"] = {
            "collectShootEffect":"mmo.shoot.effect.effects.CollectShootEffect",
            "collectBeam":new BeamInfo("mmo.shoot.effect.beam.Collect2753_Beam",BeamInfo.BEAM_TYPE_COLLECT_MOVIE,15 * 60)
         };
         this.cardEffects["5015"] = this.cardEffects["4"];
         this.cardEffects["10001"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10001"
         };
         this.cardEffects["10002"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10002"
         };
         this.cardEffects["10003"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10003"
         };
         this.cardEffects["10004"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10004"
         };
         this.cardEffects["10005"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10005"
         };
         this.cardEffects["10006"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10006"
         };
         this.cardEffects["10007"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10007"
         };
         this.cardEffects["10008"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10008"
         };
         this.cardEffects["10009"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10009"
         };
         this.cardEffects["10010"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10010"
         };
         this.cardEffects["10011"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect1_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10011"
         };
         this.cardEffects["10012"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect3_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10012"
         };
         this.cardEffects["10013"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10013"
         };
         this.cardEffects["10013"] = {
            "shootEffect":"mmo.shoot.effect.effects.ShootEffect3",
            "beam":new BeamInfo("mmo.shoot.effect.beam.Effect4_Beam",BeamInfo.BEAM_TYPE_DOUBLE_MOVIE,0),
            "bumpEffect":"mmo.shoot.effect.effects.BumpEffect10013"
         };
      }
      
      public function getShootEffect(param1:int, param2:Boolean = false) : ShootEffectBase
      {
         var _loc3_:String = "";
         if(param2)
         {
            _loc3_ = this.cardEffects[param1].collectShootEffect;
         }
         else
         {
            _loc3_ = this.cardEffects[param1].shootEffect;
         }
         return this.getMovieClip(_loc3_) as ShootEffectBase;
      }
      
      public function getBeam(param1:int, param2:Boolean = false) : BeamInfo
      {
         var _loc3_:String = "";
         if(param2)
         {
            return this.cardEffects[param1].collectBeam;
         }
         return this.cardEffects[param1].beam;
      }
      
      public function getBumpEffect(param1:int) : MovieClip
      {
         var _loc2_:String = this.cardEffects[param1].bumpEffect;
         return this.getMovieClip(_loc2_);
      }
      
      public function getEffectMovie(param1:int) : MovieClip
      {
         var _loc2_:String = this.cardEffects[param1].effectMovie;
         if(_loc2_ == null)
         {
            return null;
         }
         return this.getMovieClip(_loc2_);
      }
      
      private function getMovieClip(param1:String) : MovieClip
      {
         var type:Class = null;
         var effectMovie:MovieClip = null;
         var clsName:String = param1;
         try
         {
            type = getDefinitionByName(clsName) as Class;
            effectMovie = MovieClip(new type());
            effectMovie.gotoAndStop(1);
            return effectMovie;
         }
         catch(er:Error)
         {
            return null;
         }
      }
   }
}

