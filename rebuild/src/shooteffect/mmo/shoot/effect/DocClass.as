package mmo.shoot.effect
{
   import flash.display.MovieClip;
   import mmo.shoot.effect.beam.Collect147_Beam;
   import mmo.shoot.effect.beam.Collect148_Beam;
   import mmo.shoot.effect.beam.Collect149_Beam;
   import mmo.shoot.effect.beam.Collect150_Beam;
   import mmo.shoot.effect.beam.Collect2751_Beam;
   import mmo.shoot.effect.beam.Collect2752_Beam;
   import mmo.shoot.effect.beam.Collect2753_Beam;
   import mmo.shoot.effect.beam.Collect402_Beam;
   import mmo.shoot.effect.beam.Collect586_Beam;
   import mmo.shoot.effect.beam.Effect10_Beam;
   import mmo.shoot.effect.beam.Effect113_Beam;
   import mmo.shoot.effect.beam.Effect114_Beam;
   import mmo.shoot.effect.beam.Effect11_Beam;
   import mmo.shoot.effect.beam.Effect12_Beam;
   import mmo.shoot.effect.beam.Effect135_Beam;
   import mmo.shoot.effect.beam.Effect136_Beam;
   import mmo.shoot.effect.beam.Effect137_Beam;
   import mmo.shoot.effect.beam.Effect138_Beam;
   import mmo.shoot.effect.beam.Effect139_Beam;
   import mmo.shoot.effect.beam.Effect13_Beam;
   import mmo.shoot.effect.beam.Effect140_Beam;
   import mmo.shoot.effect.beam.Effect14_Beam;
   import mmo.shoot.effect.beam.Effect15_Beam;
   import mmo.shoot.effect.beam.Effect161_Beam;
   import mmo.shoot.effect.beam.Effect162_Beam;
   import mmo.shoot.effect.beam.Effect16_Beam;
   import mmo.shoot.effect.beam.Effect17_Beam;
   import mmo.shoot.effect.beam.Effect18_Beam;
   import mmo.shoot.effect.beam.Effect19_Beam;
   import mmo.shoot.effect.beam.Effect1_Beam;
   import mmo.shoot.effect.beam.Effect20_Beam;
   import mmo.shoot.effect.beam.Effect21_Beam;
   import mmo.shoot.effect.beam.Effect2_Beam;
   import mmo.shoot.effect.beam.Effect3_Beam;
   import mmo.shoot.effect.beam.Effect4_Beam;
   import mmo.shoot.effect.beam.Effect5_Beam;
   import mmo.shoot.effect.beam.Effect6_Beam;
   import mmo.shoot.effect.beam.Effect7_Beam;
   import mmo.shoot.effect.beam.Effect8_Beam;
   import mmo.shoot.effect.beam.Effect9_Beam;
   import mmo.shoot.effect.effects.BumpEffect1;
   import mmo.shoot.effect.effects.BumpEffect10;
   import mmo.shoot.effect.effects.BumpEffect10001;
   import mmo.shoot.effect.effects.BumpEffect10002;
   import mmo.shoot.effect.effects.BumpEffect10003;
   import mmo.shoot.effect.effects.BumpEffect10004;
   import mmo.shoot.effect.effects.BumpEffect10005;
   import mmo.shoot.effect.effects.BumpEffect10006;
   import mmo.shoot.effect.effects.BumpEffect10007;
   import mmo.shoot.effect.effects.BumpEffect10008;
   import mmo.shoot.effect.effects.BumpEffect10009;
   import mmo.shoot.effect.effects.BumpEffect10010;
   import mmo.shoot.effect.effects.BumpEffect10011;
   import mmo.shoot.effect.effects.BumpEffect10012;
   import mmo.shoot.effect.effects.BumpEffect10013;
   import mmo.shoot.effect.effects.BumpEffect10020;
   import mmo.shoot.effect.effects.BumpEffect10021;
   import mmo.shoot.effect.effects.BumpEffect105;
   import mmo.shoot.effect.effects.BumpEffect106;
   import mmo.shoot.effect.effects.BumpEffect11;
   import mmo.shoot.effect.effects.BumpEffect110;
   import mmo.shoot.effect.effects.BumpEffect111;
   import mmo.shoot.effect.effects.BumpEffect112;
   import mmo.shoot.effect.effects.BumpEffect113;
   import mmo.shoot.effect.effects.BumpEffect114;
   import mmo.shoot.effect.effects.BumpEffect115;
   import mmo.shoot.effect.effects.BumpEffect12;
   import mmo.shoot.effect.effects.BumpEffect13;
   import mmo.shoot.effect.effects.BumpEffect135;
   import mmo.shoot.effect.effects.BumpEffect136;
   import mmo.shoot.effect.effects.BumpEffect137;
   import mmo.shoot.effect.effects.BumpEffect138;
   import mmo.shoot.effect.effects.BumpEffect14;
   import mmo.shoot.effect.effects.BumpEffect15;
   import mmo.shoot.effect.effects.BumpEffect16;
   import mmo.shoot.effect.effects.BumpEffect161;
   import mmo.shoot.effect.effects.BumpEffect162;
   import mmo.shoot.effect.effects.BumpEffect17;
   import mmo.shoot.effect.effects.BumpEffect18;
   import mmo.shoot.effect.effects.BumpEffect19;
   import mmo.shoot.effect.effects.BumpEffect2;
   import mmo.shoot.effect.effects.BumpEffect20;
   import mmo.shoot.effect.effects.BumpEffect21;
   import mmo.shoot.effect.effects.BumpEffect22;
   import mmo.shoot.effect.effects.BumpEffect3;
   import mmo.shoot.effect.effects.BumpEffect4;
   import mmo.shoot.effect.effects.BumpEffect5;
   import mmo.shoot.effect.effects.BumpEffect6;
   import mmo.shoot.effect.effects.BumpEffect7;
   import mmo.shoot.effect.effects.BumpEffect8;
   import mmo.shoot.effect.effects.BumpEffect9;
   import mmo.shoot.effect.effects.CollectShootEffect;
   import mmo.shoot.effect.effects.EffectMovie1;
   import mmo.shoot.effect.effects.EffectMovie2;
   import mmo.shoot.effect.effects.ShootEffect1;
   import mmo.shoot.effect.effects.ShootEffect2;
   import mmo.shoot.effect.effects.ShootEffect3;
   import mmo.shoot.effect.effects.ShootEffect4;
   import mmo.shoot.effect.effects.ShootEffect5;
   import mmo.shoot.effect.lighting.LightningEffect;

   /**
    * LATER shoot/shooteffectservice (the live client's, decompiled with
    * JPEXS) compiled against the 2013 interfaces and put back on the later
    * module's own art (tools/swf_transplant.py --drop-art-abc): the beams and
    * hits of the shoot cards and of gathering. The 2013 module is lost.
    */
    [SWF(width="960", height="560", backgroundColor="#000000", frameRate="24")]
   public class DocClass extends MovieClip
   {
      public function DocClass()
      {
         super();
      }

      internal static function compileMe() : void
      {
         var _loc1_:ShootEffectService = null;
         var _loc2_:LightningEffect = null;
         // Every class the art binds a symbol to (some are only looked up by name).
         mmo.shoot.effect.beam.Collect147_Beam;
         mmo.shoot.effect.beam.Collect148_Beam;
         mmo.shoot.effect.beam.Collect149_Beam;
         mmo.shoot.effect.beam.Collect150_Beam;
         mmo.shoot.effect.beam.Collect2751_Beam;
         mmo.shoot.effect.beam.Collect2752_Beam;
         mmo.shoot.effect.beam.Collect2753_Beam;
         mmo.shoot.effect.beam.Collect402_Beam;
         mmo.shoot.effect.beam.Collect586_Beam;
         mmo.shoot.effect.beam.Effect10_Beam;
         mmo.shoot.effect.beam.Effect113_Beam;
         mmo.shoot.effect.beam.Effect114_Beam;
         mmo.shoot.effect.beam.Effect11_Beam;
         mmo.shoot.effect.beam.Effect12_Beam;
         mmo.shoot.effect.beam.Effect135_Beam;
         mmo.shoot.effect.beam.Effect136_Beam;
         mmo.shoot.effect.beam.Effect137_Beam;
         mmo.shoot.effect.beam.Effect138_Beam;
         mmo.shoot.effect.beam.Effect139_Beam;
         mmo.shoot.effect.beam.Effect13_Beam;
         mmo.shoot.effect.beam.Effect140_Beam;
         mmo.shoot.effect.beam.Effect14_Beam;
         mmo.shoot.effect.beam.Effect15_Beam;
         mmo.shoot.effect.beam.Effect161_Beam;
         mmo.shoot.effect.beam.Effect162_Beam;
         mmo.shoot.effect.beam.Effect16_Beam;
         mmo.shoot.effect.beam.Effect17_Beam;
         mmo.shoot.effect.beam.Effect18_Beam;
         mmo.shoot.effect.beam.Effect19_Beam;
         mmo.shoot.effect.beam.Effect1_Beam;
         mmo.shoot.effect.beam.Effect20_Beam;
         mmo.shoot.effect.beam.Effect21_Beam;
         mmo.shoot.effect.beam.Effect2_Beam;
         mmo.shoot.effect.beam.Effect3_Beam;
         mmo.shoot.effect.beam.Effect4_Beam;
         mmo.shoot.effect.beam.Effect5_Beam;
         mmo.shoot.effect.beam.Effect6_Beam;
         mmo.shoot.effect.beam.Effect7_Beam;
         mmo.shoot.effect.beam.Effect8_Beam;
         mmo.shoot.effect.beam.Effect9_Beam;
         mmo.shoot.effect.effects.BumpEffect1;
         mmo.shoot.effect.effects.BumpEffect10;
         mmo.shoot.effect.effects.BumpEffect10001;
         mmo.shoot.effect.effects.BumpEffect10002;
         mmo.shoot.effect.effects.BumpEffect10003;
         mmo.shoot.effect.effects.BumpEffect10004;
         mmo.shoot.effect.effects.BumpEffect10005;
         mmo.shoot.effect.effects.BumpEffect10006;
         mmo.shoot.effect.effects.BumpEffect10007;
         mmo.shoot.effect.effects.BumpEffect10008;
         mmo.shoot.effect.effects.BumpEffect10009;
         mmo.shoot.effect.effects.BumpEffect10010;
         mmo.shoot.effect.effects.BumpEffect10011;
         mmo.shoot.effect.effects.BumpEffect10012;
         mmo.shoot.effect.effects.BumpEffect10013;
         mmo.shoot.effect.effects.BumpEffect10020;
         mmo.shoot.effect.effects.BumpEffect10021;
         mmo.shoot.effect.effects.BumpEffect105;
         mmo.shoot.effect.effects.BumpEffect106;
         mmo.shoot.effect.effects.BumpEffect11;
         mmo.shoot.effect.effects.BumpEffect110;
         mmo.shoot.effect.effects.BumpEffect111;
         mmo.shoot.effect.effects.BumpEffect112;
         mmo.shoot.effect.effects.BumpEffect113;
         mmo.shoot.effect.effects.BumpEffect114;
         mmo.shoot.effect.effects.BumpEffect115;
         mmo.shoot.effect.effects.BumpEffect12;
         mmo.shoot.effect.effects.BumpEffect13;
         mmo.shoot.effect.effects.BumpEffect135;
         mmo.shoot.effect.effects.BumpEffect136;
         mmo.shoot.effect.effects.BumpEffect137;
         mmo.shoot.effect.effects.BumpEffect138;
         mmo.shoot.effect.effects.BumpEffect14;
         mmo.shoot.effect.effects.BumpEffect15;
         mmo.shoot.effect.effects.BumpEffect16;
         mmo.shoot.effect.effects.BumpEffect161;
         mmo.shoot.effect.effects.BumpEffect162;
         mmo.shoot.effect.effects.BumpEffect17;
         mmo.shoot.effect.effects.BumpEffect18;
         mmo.shoot.effect.effects.BumpEffect19;
         mmo.shoot.effect.effects.BumpEffect2;
         mmo.shoot.effect.effects.BumpEffect20;
         mmo.shoot.effect.effects.BumpEffect21;
         mmo.shoot.effect.effects.BumpEffect22;
         mmo.shoot.effect.effects.BumpEffect3;
         mmo.shoot.effect.effects.BumpEffect4;
         mmo.shoot.effect.effects.BumpEffect5;
         mmo.shoot.effect.effects.BumpEffect6;
         mmo.shoot.effect.effects.BumpEffect7;
         mmo.shoot.effect.effects.BumpEffect8;
         mmo.shoot.effect.effects.BumpEffect9;
         mmo.shoot.effect.effects.CollectShootEffect;
         mmo.shoot.effect.effects.EffectMovie1;
         mmo.shoot.effect.effects.EffectMovie2;
         mmo.shoot.effect.effects.ShootEffect1;
         mmo.shoot.effect.effects.ShootEffect2;
         mmo.shoot.effect.effects.ShootEffect3;
         mmo.shoot.effect.effects.ShootEffect4;
         mmo.shoot.effect.effects.ShootEffect5;
      }
   }
}
