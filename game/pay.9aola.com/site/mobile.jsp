<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">





<script type="text/javascript">
	var MyAobiBalance = 0;
	var openService = 0;
	var duoduoId = new String(0);
</script>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>开通蓝宝石</title>
<meta http-equiv="keywords" content="奥拉星,蓝宝石骑士,多多卡" />
<meta http-equiv="description" content="奥拉星,蓝宝石骑士,多多卡" />
<link href="http://assets.9aola.com/baitianpay/css/main_site.css" rel="stylesheet" type="text/css" />
<style type="text/css">
.main_content_desc {
	background:url(http://assets.9aola.com/baitianpay/images/site/mobile_desc_bg.jpg) no-repeat scroll 0 0;
	width:530px;
	height:202px;
	position:relative;
	left:38px;
}
.main_content_19pay_desc{
	background:url(http://assets.9aola.com/baitianpay/images/site/mobile_desc_19pay_bg.jpg) no-repeat scroll 0 0;
	width:530px;
	height:143px;
	position:relative;
	left:38px;
}
.main_content_dianxin_desc {
    background: url("http://assets.9aola.com/baitianpay/images/site/mobile_desc_dianxin_bg.jpg") no-repeat scroll 0 0 transparent;
    height: 200px;
    left: 38px;
    position: relative;
    width: 530px;
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
.easyown {
	display:block;
}
.easyown_inline {
	display:inline;
}
.pay19 {
	display:none;
}
.pay19_inline {
	display:none;
}
.dianxin {
	display:none;
}
.dianxin_inline {
	display:none;
}
#phoneButton {
	text-align:center;
	position:relative;
	top:5px;
}
#phoneButton img {
	cursor:pointer;
	  width: 170px;
}
.btm_desc {
	padding-left:35px;
	color:#6c6b6b;
	height:50px;
}
.btm_desc p {
	padding-bottom:8px;
}
</style>
<link href="http://assets.9aola.com/baitianpay/css/jquery.fancybox.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/jquery.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/jquery.fancybox.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/global.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/site.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/swfobject.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/site_ruby.js"></script>
<script language="JavaScript" type="text/javascript">
        var homePage = true; 		
</script>
<script src="http://assets.9aola.com/baitianpay/js/nav.js" language="javascript" type="text/javascript"></script>
<script type="text/javascript">
	var account = "";
	var confirmAccount = "";
	var serviceTime = "";
	var captcha = "";
	var opId = "";
	var gameId = "";
	var isAola = true;
	var isUseAobi = false;
	var isHtml = false;
		
	var domReady = function(){
		$('#Account').focus(AccountFocus);
		$('#Account').blur(AccountBlur);
		$('#ConfirmAccount').focus(ConfirmAccountFocus);
		$('#ConfirmAccount').blur(ConfirmAccountBlur);
		$('#chkServiceTime').click(ServiceTimeFocus);
		$('#captcha').focus(captchaFocus);
		$('#phoneButton img').click(tabClick);
	};
	
	var loadValues = function(){
		account = $('#Account').val();
		confirmAccount = $('#ConfirmAccount').val();
		opId = $('#OpId').val();
		gameId = $('#GameId').val();
		serviceTime = "";
		$('#chkServiceTime :radio').each(function(i, docElement){
			if(docElement.checked){
				serviceTime = docElement.value;
			}
		});
		captcha = $('#captcha').val();
		
		return true;
	};
	
	var clientCheck = function(){
		hideValidate('AccountValidate');
		hideValidate('ConfirmAccountValidate');
		hideValidate('ServiceTimeValidate');
		hideValidate('CaptchaValidate');
		
		var msg = "你选择了 "+ serviceTime * 10 +" 元面值，请核对你手上的充值卡面值是否也是 " + serviceTime * 10
			+" 元；\n如果不一致，会导致充值卡作废或者充值失败，请认真确认！"
			+"\n\n如果一致，请按“确定”；否则，请按“取消”。"
		return (checkAccount(account, confirmAccount) 
			&& checkCaptcha(captcha)) && window.confirm(msg);
	};
	
	function checkCallBack(){
		this.userName;
		this.fun = function(){
			var intServiceTime = parseInt(serviceTime);	
			$('#orderAccount').text(account);
			$('#orderServiceTime').text(intServiceTime==12?'1年':intServiceTime + '个月');
			$('#orderAmount').text(intServiceTime * 10 + '元');
			$("#dialoglink").click();
		}
	};
	
	function checkData(){
		if(check()){
			var arr = { Account:account, captcha:captcha, OpId:opId, GameId:gameId,ServiceTime:serviceTime};
			serverAccountCheck(arr, checkCallBack);
		}
	};
	
	function tabClick(){
	
		$('#chkServiceTime :radio').each(function(i, docElement){
			if(docElement.checked){
				docElement.checked = false;
			}
		});
		
		if($(this).parent().attr('id') == 'easyownBtn'){
		$("#notIndianxin").css("display","");
			$('#payType').val('7');
			$('.pay19').css('display', 'none');
			$('.pay19_inline').css('display', 'none');
			$('.dianxin').css('display', 'none');
			$('.dianxin_inline').css('display', 'none');
			$('.easyown').css('display', 'block');
			$('.easyown_inline').css('display', 'inline');
			this.src = 'http://assets.9aola.com/baitianpay/images/site/a_on.gif';
			$('#pay19Btn img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/b_off.gif');
			//$('#dianxin img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/c_off.gif');
			$('#ServiceTime_0').attr('checked', true);
			$('#serviceProvider').text('神州行面值：');
		}else if($(this).parent().attr('id') == 'pay19Btn'){
		$("#notIndianxin").css("display","");
			$('#payType').val('10');
			$('.easyown').css('display', 'none');
			$('.easyown_inline').css('display', 'none');
			$('.dianxin').css('display', 'none');
			$('.dianxin_inline').css('display', 'none');
			$('.pay19').css('display', 'block');
			$('.pay19_inline').css('display', 'inline');
			this.src = 'http://assets.9aola.com/baitianpay/images/site/b_on.gif';
			$('#easyownBtn img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/a_off.gif');
			//$('#dianxin img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/c_off.gif');
			$('#ServiceTime_1').attr('checked', true);
			$('#serviceProvider').text('联通一卡充面值：');
		}
		/*else{
			$('#payType').val('11');
			$('.easyown').css('display', 'none');
			$('.easyown_inline').css('display', 'none');
			$('.dianxin').css('display', 'block');
			$('.dianxin_inline').css('display', 'inline');
			$('.pay19').css('display', 'none');
			$('.pay19_inline').css('display', 'none');
			this.src = 'http://assets.9aola.com/baitianpay/images/site/c_on.gif';
			$('#easyownBtn img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/a_off.gif');
			$('#pay19Btn img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/b_off.gif');
			$("#notIndianxin").css("display","none");
			$('#ServiceTime_2').attr('checked', true);
			$('#serviceProvider').text('电信充面值:');
		}*/
		
		changeImg();
		$('#captcha').focus(captchaFocus);
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
		$("a.fancybox").fancybox(setting);
		setting.onComplete = function(){changeImgById('#imgCaptchaLogin');}
		$("a.login_fancy").fancybox(setting);
	})
</script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/pngfix.js"></script>
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
    </div>
    <div id="main">
   <div class="login_bar"><a href="login.html" class="login_fancy" id="login">登录</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="javascript:addCookie();">加入收藏</a></div>
      <div class="login_ed" style="display:none"><span id="duoduo"></span><a href="javascript:logout()">安全退出</a> | <a href="javascript:addCookie();">加入收藏</a></div>
      <div class="title" style="left:45px"><img src="http://assets.9aola.com/baitianpay/images/site/vip_title.jpg" alt="" /><br/></div>
      <div class="mainbg">
        <div class="mainContainer">
          <div class="payWayDesc grayText">你可以选择下面的方式开通蓝宝石</div>
          <div class="payWayBar">
            <table cellspacing="0" cellpadding="0">
              <tr>
                <td>
                <a href="login.html" class="login_fancy" id="login">
                
                <img src="http://assets.9aola.com/baitianpay/images/site/money.jpg" alt="奥币" /></a></td>
                <td id="active_waybar"><a href="mycard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/duoduocard2.jpg" alt="多多卡充值" /></a></td>
                <td><a href="mobile.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/mobile_active.jpg" alt="手机充值卡" /></a></td>
                <td><a href="onlinebanking.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/bank.jpg" alt="网上银行" /></a></td>
                <td><a href="telephone.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/phone.jpg" alt="固定电话" /></a></td>
                <td>
                	<a href="login.html" class="login_fancy" id="login">
                	
                	<img src="http://assets.9aola.com/baitianpay/images/site/mobile_msg2.jpg" alt="手机短信" /></a></td>
              </tr>
            </table>
          </div>
          <div class="main_cen">
            <div class="main_top"></div>
            <div class="main_content">
              <div id="phoneButton">
              	<span id="easyownBtn"><img src="http://assets.9aola.com/baitianpay/images/site/a_on.gif"/></span> 
              	<span id="pay19Btn"><img src="http://assets.9aola.com/baitianpay/images/site/b_off.gif"></span> 
              	<!--<span id="dianxin"><img src="http://assets.9aola.com/baitianpay/images/site/c_off.gif"></span>-->
              	</div>
              <div class="easyown">
                <div class="main_content_desc">
                  <div class="desc_content">
                      <p>您选择了“神州行卡”充值方式，您可到手机充值点、报刊亭、士多店等购买中国移动发行的神州行卡，在购买“神州行卡”时请注意以下几个问题（必看）：</p>
                      <p></p>
                      <p class="grayText2"><strong class="red_text">1.请您一定要购买全国通用的神州行充值卡（卡号17位，密码18位）</strong>，面值有10、30、50、100；</p>
                      <p class="grayText2">2.江苏省用户，您也可购买江苏移动充值卡（卡号16位，密码17位），面值有50、100；</p>
                      <p class="grayText2">3.浙江省用户，您也可购买浙江移动充值卡（卡号10位，密码8位），面值有50、100；</p>
                      <p class="grayText2">4.充值前，建议您先查看神州行卡充值帮助说明。<a href="cardhelp.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
                    </div>
                </div>
              </div>
              <div class="pay19">
                <div class="main_content_19pay_desc">
                  <div class="desc_content">
                    <p>您选择“联通一卡充”充值方式，您可到手机充值点、报刊亭、士多店等购买中国联通发行的联通充值卡，在购买“联通一卡充”请注意要购买全国卡。</p>
                    <p></p>
                    <p><strong class="red_text">联通全国一卡充的卡号是15位、密码19位，面值有30、50、100。</strong><a href="cardhelp.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
                  </div>
                </div>
              </div>
           <div class="dianxin">
                <div class="main_content_dianxin_desc">
                  <div class="desc_content">
                    <p>您选择了“电信充值卡”充值方式。您可以到手机充值点、报刊亭、士多店等购买中国电信发行的充值卡，在购买“电信充值卡”时请注意以下几个问题（必看）：</p>
                    <p></p>
                     <p class="grayText2"><strong class="red_text">1.支持全国通用的电信卡（卡号19位，密码18位，卡号第四位为1）</strong>，面额有50、100 元；</p>
                      <p class="grayText2">2.支持各省（天津、海南、吉林、港澳台除外）发行的电信充值卡（卡号19位，密码18位，卡号第四位为2）面值有50、100元；</p>
                      <p class="grayText2">3.请在父母的指导下完成充值操作。</p>
                      
                  </div>
                </div>
              </div>

		   <div class="main_contents" style="height:246px">
                <form id="payForm" name="payForm" method="post" action="/orderpay.jsp">
                  <table width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                      <td width="120" align="right">请输入多多号：</td>
                      <td width="171"><input name="Account" type="text" id="Account" size="20" maxlength="9" class="textbox" />
                      </td>
                      <td><div><span class="grayText">多多号就是登录游戏的帐号哦</span>
    <!--<a href="javascript:fade('accountForget');">忘记多多号？</a>-->
                          <div id="accountForget" style="display:none;">每个用户都有一个多多号，如果你还不知道的话，赶快<a href="http://play.aobi.com" target="_blank">进入奥比岛</a>，打开ATM机看看吧！</div>
                        </div>
                        <div id="AccountValidate" class="Validate"></div></td>
                    </tr>
                    <tr id="confirmTr">
                      <td align="right">请再输入多多号：</td>
                      <td><input name="ConfirmAccount" type="text" id="ConfirmAccount"
                    size="20" maxlength="9" class="textbox" /></td>
                      <td class="grayText"><div>确定充值的多多号正确</div>
                        <div id="ConfirmAccountValidate" class="Validate"></div></td>
                    </tr>
                     <tr>
                    	<td colspan="3" align="center" valign="middle">
                    		<strong class="red_text">别轻信网络上“系统漏洞”，“系统错误”等诈骗手段，别填写骗子的多多号，防止被骗！</strong>
                    	</td>
                    </tr>
                    <tr>
                      <td class="td_first" id="serviceProvider">神州行面值：</td>
                      <td colspan="2"><div id="chkServiceTime">
                          <label for="ServiceTime_0" class="easyown_inline"><input name="ServiceTime" type="radio" id="ServiceTime_0"
								value="1" checked="checked" class="radioStyle" />
                          10元开通1个月 </label>
                          <label for="ServiceTime_1" id="notIndianxin"><input type="radio" name="ServiceTime" value="3"
								id="ServiceTime_1" class="radioStyle" />
                          30元开通3个月</label><br class="easyown_inline"/>
                          <label for="ServiceTime_2"><input type="radio" name="ServiceTime" value="5"
								id="ServiceTime_2" class="radioStyle" />
                          50元开通5个月 </label>
                          <label for="ServiceTime_3"><input type="radio" name="ServiceTime" value="10"
								id="ServiceTime_3" class="radioStyle" />
                          100元开通10个月 </label>
                        </div>
                        <div></div>
                        <div id="ServiceTimeValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                      <td class="td_first">验证码：</td>
                      <td colspan="2"><input name="captcha" type="text" id="captcha" size="15" maxlength="4" class="textbox" />
                        <img id="imgCaptcha" src="/imagecaptcha.jsp?actionType=2" /> <a href="javascript:changeImg()">看不清，换一张</a>
                        <div></div>
                        <div id="CaptchaValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                      <td colspan="3" align="center" valign="middle"><div id="checkButton" style="margin:5px 0px;"> <a href="javascript:checkData()"><img src="http://assets.9aola.com/baitianpay/images/next_step.jpg" alt="下一步" /></a> </div>
                        <div id="loading" style="display:none;">loading....</div></td>
                    </tr>
                  </table>
				  	<input type="hidden" name="OpId" id="OpId" value="200"/>
					<input type="hidden" name="GameId" id="GameId" value="2"/>
					<input type="hidden" name="MemberType" id="MemberType" value="4"/>
					<input type="hidden" name="payType" id="payType" value="7"/>
					<input type="hidden" name="Position" id="Position" value="1" />
                </form>
              </div>
              <div> <br/>
                <div class="btm_desc">
                  <div style="float:left; width:25px;"><img src="http://assets.9aola.com/baitianpay/images/alarm.jpg" /></div>
                    <div style="float:left; width:470px; color:rgb(241, 85, 9)">请确保您所选择的充值金额与你所购买的<span class="easyown_inline">移动</span><span class="pay19_inline">联通</span>充值卡面值一致,如30元金额对应30元面值的<span class="easyown_inline">移动</span><span class="pay19_inline">联通</span>充值卡;如果不一致,会导致充值失败或<span class="easyown_inline">移动</span><span class="pay19_inline">联通</span>充值卡作废.详情请看充值说明。</div>
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

<div style="display:none">
<a href="#dialog" id="dialoglink" class="fancybox" style="display:none;"></a>
<div id="dialog">
  <div class="dialog_top"><span style="position: relative; top: 30px; left: 120px;"><img src="http://assets.9aola.com/baitianpay/images/site/confirm_desc.jpg"/></span></div>
  <div class="dialog_cen">
    <div class="dialog_contents">
      <table width="100%" border="1" cellspacing="0" cellpadding="0">
        <tr>
          <td align="right" width="188px">充值的多多号：</td>
          <td id="orderAccount" width="360px;" align="left"></td>
        </tr>
        <tr>
          <td align="right">充值类型：</td>
          <td align="left">开通蓝宝石骑士</td>
        </tr>
        <tr>
          <td align="right">开通时长：</td>
          <td id="orderServiceTime" align="left"></td>
        </tr>
        <tr>
          <td align="right">扣款金额：</td>
          <td id="orderAmount" align="left"></td>
        </tr>
        <tr style="display:none;">
          <td align="right">充值方式：</td>
          <td id="orderPayWay" align="left"></td>
        </tr>
        <tr>
          <td colspan="2" style="padding: 1em 1em; color:#cc3300; text-align:center;">再次核对你的充值信息，确认无误后请点击“确定”，信息有误请选择“取消”</td>
        </tr>
        <tr>
          <td colspan="2"><div style="margin-top:5px; text-align:center;"> <a href="javascript:submitForm()"><img src="http://assets.9aola.com/baitianpay/images/ok.jpg" alt="确定" /></a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="javascript:$.fancybox.close();"><img src="http://assets.9aola.com/baitianpay/images/cancel.jpg" alt="取消" /></a> </div></td>
        </tr>
      </table>
    </div>
  </div>
  <div class="dialog_btm"></div>
</div></div>
</body>
</html>
