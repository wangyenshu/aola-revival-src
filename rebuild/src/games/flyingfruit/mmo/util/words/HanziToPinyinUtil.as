package mmo.util.words
{
   import flash.utils.ByteArray;
   import mmo.common.Text;
   
   public class HanziToPinyinUtil
   {
      
      private static const spell:Object = {
         45217:"a",
         45219:"ai",
         45232:"an",
         45241:"ang",
         45244:"ao",
         45253:"ba",
         45271:"bai",
         45279:"ban",
         45294:"bang",
         45306:"bao",
         45485:"bei",
         45500:"ben",
         45504:"beng",
         45510:"bi",
         45534:"bian",
         45546:"biao",
         45550:"bie",
         45554:"bin",
         45560:"bing",
         45731:"bo",
         45752:"bu",
         45761:"ca",
         45762:"cai",
         45773:"can",
         45780:"cang",
         45785:"cao",
         45790:"ce",
         45795:"ceng",
         45797:"cha",
         45808:"chai",
         45811:"chan",
         45821:"chang",
         45996:"chao",
         46005:"che",
         46011:"chen",
         46021:"cheng",
         46036:"chi",
         46052:"chong",
         46057:"chou",
         46069:"chu",
         46247:"chuai",
         46248:"chuan",
         46255:"chuang",
         46261:"chui",
         46266:"chun",
         46273:"chuo",
         46275:"ci",
         46287:"cong",
         46293:"cou",
         46294:"cu",
         46298:"cuan",
         46301:"cui",
         46309:"cun",
         46312:"cuo",
         46318:"da",
         46324:"dai",
         46498:"dan",
         46513:"dang",
         46518:"dao",
         46530:"de",
         46533:"deng",
         46540:"di",
         46559:"dian",
         46575:"diao",
         46584:"die",
         46753:"ding",
         46762:"diu",
         46763:"dong",
         46773:"dou",
         46780:"du",
         46795:"duan",
         46801:"dui",
         46805:"dun",
         46814:"duo",
         46826:"e",
         46839:"en",
         46840:"er",
         47010:"fa",
         47018:"fan",
         47035:"fang",
         47046:"fei",
         47058:"fen",
         47073:"feng",
         47088:"fo",
         47089:"fou",
         47090:"fu",
         47297:"ga",
         47299:"gai",
         47305:"gan",
         47316:"gang",
         47325:"gao",
         47335:"ge",
         47352:"gei",
         47353:"gen",
         47355:"geng",
         47524:"gong",
         47539:"gou",
         47548:"gu",
         47566:"gua",
         47572:"guai",
         47575:"guan",
         47586:"guang",
         47589:"gui",
         47605:"gun",
         47608:"guo",
         47614:"ha",
         47777:"hai",
         47784:"han",
         47803:"hang",
         47806:"hao",
         47815:"he",
         47833:"hei",
         47835:"hen",
         47839:"heng",
         47844:"hong",
         47853:"hou",
         47860:"hu",
         48040:"hua",
         48049:"huai",
         48054:"huan",
         48068:"huang",
         48082:"hui",
         48103:"hun",
         48109:"huo",
         48119:"ji",
         48334:"jia",
         48351:"jian",
         48553:"jiang",
         48566:"jiao",
         48594:"jie",
         48621:"jin",
         48803:"jing",
         48828:"jiong",
         48830:"jiu",
         48847:"ju",
         48872:"juan",
         48879:"jue",
         48889:"jun",
         49062:"ka",
         49066:"kai",
         49071:"kan",
         49077:"kang",
         49084:"kao",
         49088:"ke",
         49103:"ken",
         49107:"keng",
         49109:"kong",
         49113:"kou",
         49117:"ku",
         49124:"kua",
         49129:"kuai",
         49133:"kuan",
         49135:"kuang",
         49143:"kui",
         49316:"kun",
         49320:"kuo",
         49324:"la",
         49331:"lai",
         49334:"lan",
         49349:"lang",
         49356:"lao",
         49365:"le",
         49367:"lei",
         49378:"leng",
         49381:"li",
         49577:"lia",
         49578:"lian",
         49592:"liang",
         49603:"liao",
         49616:"lie",
         49621:"lin",
         49633:"ling",
         49647:"liu",
         49658:"long",
         49829:"lou",
         49835:"lu",
         49855:"lv",
         49869:"luan",
         49875:"lue",
         49877:"lun",
         49884:"luo",
         49896:"ma",
         49905:"mai",
         49911:"man",
         50082:"mang",
         50088:"mao",
         50100:"me",
         50101:"mei",
         50117:"men",
         50120:"meng",
         50128:"mi",
         50142:"mian",
         50151:"miao",
         50159:"mie",
         50161:"min",
         50167:"ming",
         50173:"miu",
         50174:"mo",
         50353:"mou",
         50356:"mu",
         50371:"na",
         50378:"nai",
         50383:"nan",
         50386:"nang",
         50387:"nao",
         50392:"ne",
         50393:"nei",
         50395:"nen",
         50396:"neng",
         50397:"ni",
         50408:"nian",
         50415:"niang",
         50417:"niao",
         50419:"nie",
         50426:"nin",
         50427:"ning",
         50595:"niu",
         50599:"nong",
         50603:"nu",
         50606:"nv",
         50607:"nuan",
         50608:"nue",
         50610:"nuo",
         50614:"o",
         50615:"ou",
         50622:"pa",
         50628:"pai",
         50634:"pan",
         50642:"pang",
         50647:"pao",
         50654:"pei",
         50663:"pen",
         50665:"peng",
         50679:"pi",
         50858:"pian",
         50862:"piao",
         50866:"pie",
         50868:"pin",
         50873:"ping",
         50882:"po",
         50891:"pu",
         50906:"qi",
         50942:"qia",
         51107:"qian",
         51129:"qiang",
         51137:"qiao",
         51152:"qie",
         51157:"qin",
         51168:"qing",
         51181:"qiong",
         51183:"qiu",
         51191:"qu",
         51366:"quan",
         51377:"que",
         51385:"qun",
         51387:"ran",
         51391:"rang",
         51396:"rao",
         51399:"re",
         51401:"ren",
         51411:"reng",
         51413:"ri",
         51414:"rong",
         51424:"rou",
         51427:"ru",
         51437:"ruan",
         51439:"rui",
         51442:"run",
         51444:"ruo",
         51446:"sa",
         51449:"sai",
         51453:"san",
         51619:"sang",
         51622:"sao",
         51626:"se",
         51629:"sen",
         51630:"seng",
         51631:"sha",
         51640:"shai",
         51642:"shan",
         51658:"shang",
         51666:"shao",
         51677:"she",
         51689:"shen",
         51705:"sheng",
         51878:"shi",
         51925:"shou",
         51935:"shu",
         52130:"shua",
         52132:"shuai",
         52136:"shuan",
         52138:"shuang",
         52141:"shui",
         52145:"shun",
         52149:"shuo",
         52153:"si",
         52169:"song",
         52177:"sou",
         52180:"su",
         52193:"suan",
         52196:"sui",
         52207:"sun",
         52210:"suo",
         52218:"ta",
         52389:"tai",
         52398:"tan",
         52416:"tang",
         52429:"tao",
         52440:"te",
         52441:"teng",
         52445:"ti",
         52460:"tian",
         52468:"tiao",
         52473:"tie",
         52476:"ting",
         52648:"tong",
         52661:"tou",
         52665:"tu",
         52676:"tuan",
         52678:"tui",
         52684:"tun",
         52687:"tuo",
         52698:"wa",
         52705:"wai",
         52707:"wan",
         52724:"wang",
         52734:"wei",
         52929:"wen",
         52939:"weng",
         52942:"wo",
         52951:"wu",
         52980:"xi",
         53177:"xia",
         53190:"xian",
         53216:"xiang",
         53236:"xiao",
         53416:"xie",
         53437:"xin",
         53447:"xing",
         53462:"xiong",
         53469:"xiu",
         53478:"xu",
         53497:"xuan",
         53669:"xue",
         53675:"xun",
         53689:"ya",
         53705:"yan",
         53738:"yang",
         53755:"yao",
         53932:"ye",
         53947:"yi",
         54000:"yin",
         54178:"ying",
         54196:"yo",
         54197:"yong",
         54212:"you",
         54233:"yu",
         54439:"yuan",
         54459:"yue",
         54469:"yun",
         54481:"za",
         54484:"zai",
         54491:"zan",
         54495:"zang",
         54498:"zao",
         54512:"ze",
         54516:"zei",
         54517:"zen",
         54518:"zeng",
         54522:"zha",
         54698:"zhai",
         54704:"zhan",
         54721:"zhang",
         54736:"zhao",
         54746:"zhe",
         54756:"zhen",
         54772:"zheng",
         54949:"zhi",
         54992:"zhong",
         55003:"zhou",
         55017:"zhu",
         55205:"zhua",
         55207:"zhuai",
         55208:"zhuan",
         55214:"zhuang",
         55221:"zhui",
         55227:"zhun",
         55229:"zhuo",
         55240:"zi",
         55255:"zong",
         55262:"zou",
         55266:"zu",
         55274:"zuan",
         55276:"zui",
         55280:"zun",
         55282:"zuo"
      };
      
      public function HanziToPinyinUtil()
      {
         super();
      }
      
      public static function convertString(param1:String) : String
      {
         var _loc2_:int = param1.length;
         var _loc3_:String = "";
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_)
         {
            _loc3_ += convertChar(param1.charAt(_loc4_));
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function convertChar(param1:String) : String
      {
         var _loc2_:ByteArray = new ByteArray();
         _loc2_.writeMultiByte(param1.charAt(0),"cn-gb");
         var _loc3_:int = _loc2_[0] << 8;
         _loc3_ += _loc2_[1];
         if(isIn(45217,45252,_loc3_))
         {
            return "a";
         }
         if(isIn(45253,45760,_loc3_))
         {
            return "b";
         }
         if(isIn(45761,46317,_loc3_))
         {
            return "c";
         }
         if(isIn(46318,46825,_loc3_))
         {
            return "d";
         }
         if(isIn(46826,47009,_loc3_))
         {
            return "e";
         }
         if(isIn(47010,47296,_loc3_))
         {
            return "f";
         }
         if(isIn(47297,47613,_loc3_))
         {
            return "g";
         }
         if(isIn(47614,48118,_loc3_))
         {
            return "h";
         }
         if(isIn(48119,49061,_loc3_))
         {
            return "j";
         }
         if(isIn(49062,49323,_loc3_))
         {
            return "k";
         }
         if(isIn(49324,49895,_loc3_))
         {
            return "l";
         }
         if(isIn(49896,50370,_loc3_))
         {
            return "m";
         }
         if(isIn(50371,50613,_loc3_))
         {
            return "n";
         }
         if(isIn(50614,50621,_loc3_))
         {
            return "o";
         }
         if(isIn(50622,50905,_loc3_))
         {
            return "p";
         }
         if(isIn(50906,51386,_loc3_))
         {
            return "q";
         }
         if(isIn(51387,51445,_loc3_))
         {
            return "r";
         }
         if(isIn(51446,52208,_loc3_))
         {
            return "s";
         }
         if(isIn(52218,52697,_loc3_))
         {
            return "t";
         }
         if(isIn(52698,52979,_loc3_))
         {
            return "w";
         }
         if(isIn(52980,53640,_loc3_))
         {
            return "x";
         }
         if(isIn(53689,54480,_loc3_))
         {
            return "y";
         }
         if(isIn(54481,55289,_loc3_))
         {
            return "z";
         }
         return "0";
      }
      
      private static function isIn(param1:int, param2:int, param3:int) : Boolean
      {
         return param3 >= param1 && param3 <= param2;
      }
      
      public static function isChinese(param1:String) : Boolean
      {
         if(convertChar(param1) == "0")
         {
            return false;
         }
         return true;
      }
      
      public static function isEnKong1(param1:*) : *
      {
         var _loc6_:* = undefined;
         var _loc2_:* = false;
         var _loc3_:* = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()_-+=|{[}]:;\'<,>.?/ ";
         var _loc4_:* = param1.length;
         var _loc5_:* = 0;
         while(_loc5_ < _loc4_)
         {
            _loc6_ = _loc3_.indexOf(param1.charAt(_loc5_));
            if(_loc6_ == -1)
            {
               _loc2_ = false;
            }
            else
            {
               _loc2_ = true;
            }
            _loc5_++;
         }
         return _loc2_;
      }
      
      public static function cn2asc(param1:*) : *
      {
         var _loc2_:RegExp = /[^\x00-\xff]/g;
         var _loc3_:String = param1;
         var _loc4_:String = _loc3_;
         while(_loc4_ == _loc2_.exec(_loc3_))
         {
            _loc4_ = _loc4_.split(_loc4_).join(escape(_loc4_).split("%u").join(""));
         }
         return _loc4_;
      }
      
      public static function pinyin(param1:*) : *
      {
         var _loc2_:* = new Array();
         var _loc3_:* = "";
         if(!param1.charCodeAt(0) || param1.charCodeAt(0) < 1328)
         {
            return param1;
         }
         if(_loc2_[param1.charCodeAt(0)])
         {
            return _loc2_[param1.charCodeAt(0)];
         }
         var _loc4_:* = AnsiUnicodeConvert.UnicodeToAnsi(cn2asc(param1));
         if(!(_loc4_ > "0xB0A0" && _loc4_ < "0xD7FC"))
         {
            return param1;
         }
         var _loc5_:* = _loc4_;
         while(!spell[_loc5_] && _loc5_ > 0)
         {
            _loc5_--;
         }
         return spell[_loc5_];
      }
      
      public static function toPinyin(param1:*) : *
      {
         var _loc2_:* = undefined;
         var _loc3_:* = undefined;
         if(param1)
         {
            _loc2_ = "";
            _loc3_ = 0;
            while(_loc3_ < param1.length)
            {
               if(isEnKong1(param1.charAt(_loc3_)))
               {
                  _loc2_ += param1.charAt(_loc3_);
               }
               else
               {
                  _loc2_ += " " + pinyin(param1.charAt(_loc3_));
               }
               _loc3_++;
            }
            return Text.trim(_loc2_);
         }
      }
   }
}

