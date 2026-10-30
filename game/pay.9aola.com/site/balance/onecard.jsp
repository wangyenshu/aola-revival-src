<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">





<script type="text/javascript">
	var MyAobiBalance = 0;
	var openService = 0;
	var duoduoId = new String(0);
</script>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>充值奥币</title>
<meta http-equiv="keywords" content="奥拉星，超级HELLO，多多卡" />
<meta http-equiv="description" content="奥拉星，超级HELLO，多多卡" />
<link href="http://assets.9aola.com/baitianpay/css/main_site.css" rel="stylesheet" type="text/css" />
<style type="text/css">
.main_content_desc {
	background:url(http://assets.9aola.com/baitianpay/images/site/bank_desc_bg.jpg) no-repeat scroll 0 0;
	width:530px;
	height:270px;
	position:relative;
	left:38px;
	margin-top:-5px;
}
.desc_content {
	position:relative;
	top:15px;
	left:25px;
	width:480px;
}
.desc_content p {
	text-indent:0px;
	padding-bottom:8px;
}
#buy_babi{
	text-align:center;
}

#header_btn{
	margin-left:100px;
}

#buy_babi{
	padding:20px;
	margin-top:40px;
}
</style>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/pngfix.js"></script>
<link href="http://assets.9aola.com/baitianpay/css/jquery.fancybox.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/jquery.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/jquery.fancybox.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/global.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/site.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/swfobject.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/aobi.js"></script>
<script language="JavaScript" type="text/javascript">
        var homePage = true;		
</script>
<script src="http://assets.9aola.com/baitianpay/js/nav.js" language="javascript" type="text/javascript"></script>
<script type="text/javascript">
	var account = "";
	var confirmAccount = "";
	var opId = "";
	var aobiMoney = "";
	var captcha = "";
	var isAola = true;
	var isUseAobi = false;
	
	function selectBabi(){
		$('#junwang').css('display','none');
		$('#babi').css('display','block');
		$('#babi_img').attr('src','http://assets.9aola.com/baitianpay/images/site/babi_btn_active.jpg');
		$('#junwang_img').attr('src','http://assets.9aola.com/baitianpay/images/site/junwang_btn.jpg');
	};
	
	function selectJunwang(){
		$('#junwang').css('display','block');
		$('#babi').css('display','none');
		$('#babi_img').attr('src','http://assets.9aola.com/baitianpay/images/site/babi_btn.jpg');
		$('#junwang_img').attr('src','http://assets.9aola.com/baitianpay/images/site/junwang_btn_active.jpg');
	};
	
	var setting = { 
		'modal':true,
		'padding':0,
		'margin':0,
		'width': '100%',
		'height':'100%',
		'autoScale':true,
		'scrolling':'false',
		'autoDimensions':true,
		'centerOnScroll':true,
		'zoomSpeedIn': 300,
		'zoomSpeedOut': 300, 
		'overlayColor':'#000',
		'overlayOpacity':0.75,
		'onClosed':function() {$('#captcha').val("");changeImg();}
	};
		
	$(document).ready(function(){
		setting.onComplete = function(){changeImgById('#imgCaptchaLogin');}
		$("a.login_fancy").fancybox(setting);
	})
</script>
</head>
<body>
<div id="container">
  <div id="header">
    <div id="top"><img src="http://assets.9aola.com/baitianpay/images/site/head.png" /></div>
  	<div id="logo"><a target="_blank" href="http://www.9aola.com"><img src="http://assets.9aola.com/baitianpay/images/site/logo.gif"/></a></div>
  </div>
    <div class="nav">
      <div id="mainContainer">
        <div align="center">
        </div>
      </div>
    </div>
  </div>
  <div id="content">
    <div id="sidebar">
      <div class="ruby_sidebar_bg balance_sidebar_bg">
        <ul>
          <li><a href="../mycard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/jewel_btn.jpg" /></a></li>
          <li><a href="mycard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/topup_aobi.jpg" /></a></li>
          <li><a href="../aomoneyintro.html"><img src="http://assets.9aola.com/baitianpay/images/site/aobi_intro_btn.jpg" /></a></li>
          <li><a href="../cardintroduce1.html"><img src="http://assets.9aola.com/baitianpay/images/site/duo_intro_btn.jpg" /></a></li>
          <li><a href="../duocardsold.html"><img src="http://assets.9aola.com/baitianpay/images/site/card_sol_btn.jpg" /></a></li>
          <li><a href="../cardhelp.html"><img src="http://assets.9aola.com/baitianpay/images/site/help_btn.jpg" /></a></li>
          <li><a href="../faq.html"><img src="http://assets.9aola.com/baitianpay/images/site/question_btn.jpg" /></a></li>
        </ul>
      </div>
      <div class="sidebar_ad"></div>
    </div>
    <div id="main">
    <div class="login_bar"><a href="../login.html" class="login_fancy" id="login">登录</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="javascript:addCookie();">加入收藏</a></div>
      <div class="login_ed" style="display:none"><span id="duoduo"></span><a href="javascript:logout()">安全退出</a> | <a href="javascript:addCookie();">加入收藏</a></div>
      <div class="title"><img src="http://assets.9aola.com/baitianpay/images/site/balance_title.jpg" alt="" /><br/></div>
      <div class="mainbg">
        <div class="mainContainer">
          <div class="payWayDesc grayText">你选择下面的方式充值奥币</div>
          <div class="payWayBar">
            <table cellspacing="0" cellpadding="0">
              <tr>
                <td id="active_waybar"><a href="mycard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/duoducard.jpg" alt="多多卡充值" /></a></td>
                <td><a href="mobile.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/mobile.jpg" alt="手机充值卡" /></a></td>
                <td><a href="onlinebanking.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/bank.jpg" alt="网上银行" /></a></td>
                <td><a href="telephone.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/phone.jpg" alt="固定电话" /></a></td>
                <td>
					<a href="../login.html" class="login_fancy" id="login">
					<img src="http://assets.9aola.com/baitianpay/images/site/mobile_msg.jpg" alt="手机短信" /></a></td>
                <td><a href="onecard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/other_active.jpg" alt="其它方式" /></a></td>
              </tr>
            </table>
          </div>
          <div class="main_cen">
            <div class="main_top"></div>
            <div class="main_content">
			  <div id="header_btn">
				<a href="javascript:selectBabi()"><img id="babi_img" src="http://assets.9aola.com/baitianpay/images/site/babi_btn_active.jpg" /></a>
				<a href="javascript:selectJunwang()"><img id="junwang_img" src="http://assets.9aola.com/baitianpay/images/site/junwang_btn.jpg" /></a>
			  </div>
              <div class="main_content_desc">
				<div id="junwang" style="display:none">
					<div class="desc_content">
					  <p>你选择了"骏网一卡通"的充值方式：<a href="../cardhelp.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
					  <p></p>
					   <p class="grayText2">第一步：先购买一张10元面值的"骏网一卡通"（软件店、书报亭、便利店等卖游戏点卡的地方都很容易买到）；</p>
					  <p class="grayText2">第二步：刮开骏网一卡通获得卡号和密码，然后点击下面的"骏网一卡通"按钮，在充值页面填写一卡通卡号、最后点"提取卡密"，这样你就可以获得多多卡了（卡号11位，密码16位）；</p>
					  <p class="grayText2">第三步：登陆奥拉星，你就可以使用刚才获得的多多卡充值蓝宝石或奥币了；</p>
										<p style="color:red">在充值过程中，如果遇到任何问题，记得打电话（020-83995251）找客服姐姐帮忙哦！</p>
					</div>
					<div style="text-align:center;padding:20px"><a href="http://www.jcard.cn/Fetch/UCardFetchCard.aspx?category=AXGZBTZBDV&product=AXGZBTZBDV010AV" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/onecard_btn.jpg" alt="骏网一卡通" /></a></div>
				</div>
				<div id="babi">
					<div class="desc_content">
						<p>你選擇了"babi點卡"的充值方式.</p>
						<p>購卡須知：</p>
						<p>本方式只適合港澳台、東南亞地區的小朋友，請參考以下購買流程:</p>
						<p class="grayText2">1、登陸babi網站，根據網站指引的地方購買相關面值的babi點數；</p>
						<p class="grayText2">2、根據babi網站提示，利用babi點數兌換多多卡（卡密形式，卡號11位，密碼16位）；</p>
						<p class="grayText2">3、獲得多多卡卡號密碼後，登陸奧拉星，選擇多多卡開通方式充值藍寶石或者奧幣。</p>
					</div>
					<div id="buy_babi">
						<a href="http://www.ba-bi.com/wherebuy" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/buy_babi_btn.jpg" /></a>
					</div>
				</div>
              </div>
            </div>
            <div class="main_btm"></div>
          </div>
          <div style="color: #666666;">
            <p style="color: #ff7901;	font-weight: bold; margin: 5px auto;">温馨提示：</p>
            <p style=" margin: 5px auto; text-indent:35px;">1.在填写要充值的多多号时请仔细填写并确认，以免输入错误导致为他人充值。</p>
            <p style=" margin-top: 5px; text-indent:35px;">2.请在父母的指导下操作。</p>
          </div>
        </div>
		<div id="footer">
			<div id="footerleft"></div>
			<div id="footerright"></div>
  		</div>
      </div>
    </div>
    <div class="clear"></div>
	<div id="copyright">
  		<div> <a href="http://www.baitianinfo.com" target="_blank">广州百田</a> |
	 	<a href="http://www.9aola.com/">奥拉星</a> |
	 	<a href="http://www.9aola.com/website/tos6.html" target="_blank">服务条款</a> |
	 	<a href="http://www.baitianinfo.com/join.html" target="_blank">加盟奥拉星</a> | 
	 	<a href="http://www.baitianinfo.com/contact.html" target="_blank">联系我们</a>
	 	</div>
  	<div>   
    	文网文[2009]103号&nbsp;增值电信业务经营许可证粤B2-20090388号<br/>
    	文化部监督电子邮箱:wlwh@vip.sina.com<br/>
     	Copyright &copy; 2009 Baitian Ltd.All Rights Reserved<br/>
    	服务热线：020-83995251 &nbsp;&nbsp;邮箱：<a href="mailto:kefu@9aola.com">kefu@9aola.com</a></div>
  	</div>
</div>
<div id="block"></div>

</body>
</html>
