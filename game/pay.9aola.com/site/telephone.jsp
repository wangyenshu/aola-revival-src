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
	background:url(http://assets.9aola.com/baitianpay/images/site/telephone_bg.jpg) no-repeat scroll 0 0;
	width:530px;
	height:228px;
	position:relative;
	left:38px;
}
.main_content_desc_vpay {
	background:url(http://assets.9aola.com/baitianpay/images/site/telephone_vpay_bg.jpg) no-repeat scroll 0 0;
	width:530px;
	height:250px;
	position:relative;
	left:38px;
}
.desc_content {
	position:relative;
	top:15px;
	left:10px;
	width:480px;
}
.desc_content p {
	text-indent:0px;
	padding-bottom:8px;
}
.eBilling {
	display:block;
}
.vPay {
	display:none;
}
.vPay_tr {
	display:none;
}
.vPay_tr_show{
	display:table-row;
}
#phoneButton {
	text-align:center;
	position:relative;
	top:5px;
}
#phoneButton img {
	cursor:pointer;
}
.btm_desc {
	padding-left:10px;
	color:#6c6b6b;
	margin-top: 10px;
}
.btm_desc p {
	padding-bottom:8px;
}

.EB_province{
	display:none;
}

.EB_province_show{
	
}
.eb_desc {
	padding-left:10px;
	color:#f15509;
	margin-top: -90px;
	text-indent:83px;
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
	var opId = "";
	var gameId = "";
	var serviceTime = "";
	var captcha = "";
	var vPayNumber = "";
	var vPayPassword = "";
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
		$('#VPayNumber').focus(VPayNumberFocus);
		$('#VPayPassword').focus(VPayPasswordFocus);
		$('#phoneButton img').click(phoneClick);
		initProvince('vip');
		$('.EB_province').attr('className', 'EB_province_show');
		$('#eB_month2').css('display', 'none');
	};
	
	var loadValues = function(){
		account = $('#Account').val();
		confirmAccount = $('#ConfirmAccount').val();
		opId = $("#OpId").val();
		gameId = $("#GameId").val();
		serviceTime = "";
		$('#chkServiceTime :radio').each(function(i, docElement){
			if(docElement.checked){
				serviceTime = docElement.value;
			}
		});
		captcha = $('#captcha').val();
		vPayNumber = $('#VPayNumber').val();
		vPayPassword = $('#VPayPassword').val();
		
		return true;
	}
	
	var clientCheck = function(){
		hideValidate('AccountValidate');
		hideValidate('ConfirmAccountValidate');
		hideValidate('ServiceTimeValidate');
		hideValidate('CaptchaValidate');
		hideValidate('VPayNumberValidate');
		hideValidate('VPayPasswordValidate');
		hideValidate('provinceValidate');
		if($('#payType').val() == '4'){
			$('.vPay').css('display', 'none');
			return (checkAccount(account, confirmAccount) && checkCaptcha(captcha)&&checkProvince());
		}else{
			var intServiceTime = parseInt(serviceTime);	
			var aobi = intServiceTime*15;
			var parValue = parseInt(vPayNumber.substring(13, 15));
			if(aobi != parValue){
				showValidate('VPayNumberValidate', '对不起，我们暂时只支持15和30面值的V币！');
				return false;
			}
			return (checkAccount(account, confirmAccount) && checkVPayNumber(vPayNumber) && checkVPayPassword(vPayPassword) && checkCaptcha(captcha));
		}
	}
	
	function checkCallBack(){
		this.userName;
		this.fun = function(){
			var intServiceTime = parseInt(serviceTime);	
			$('#orderAccount').text(account);
			$('#orderServiceTime').text(intServiceTime==12?'1年':intServiceTime + '个月');
			$('#orderAmount').text(intServiceTime * 15 + '元');
			$("#dialoglink").click();
		}
	}
	
	function checkData(){
		if(check()){
			var arr = { Account:account, captcha:captcha, OpId:opId, GameId:gameId, ServiceTime:serviceTime};
			if($('#payType').val() == '4'){
				serverAccountCheck(arr, checkCallBack);
			}else{
				serverCheckVPay(arr, checkCallBack);
			}
		}
	}
	
	function phoneClick(){
		if($(this).parent().attr('id') == 'ebillingBtn'){
			$('#payType').val('4');
			$('.eBilling').css('display', 'block');
			$('.vPay').css('display', 'none');
			$('.vPay_tr_show').attr('className', 'vPay_tr');
			$('.EB_province').attr( 'className', 'EB_province_show');
			this.src = 'http://assets.9aola.com/baitianpay/images/site/phone_eb_btn_active.jpg';
			$('#vPayBtn img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/phone_vp_btn.jpg');
		}else{
			$('#payType').val('5');
			$('.eBilling').css('display', 'none');
			$('.vPay').css('display', 'block');
			$('.vPay_tr').attr('className', 'vPay_tr_show');
			$('.EB_province_show').attr('className', 'EB_province');
			this.src = 'http://assets.9aola.com/baitianpay/images/site/phone_vp_btn_active.jpg';
			$('#ebillingBtn img').attr('src', 'http://assets.9aola.com/baitianpay/images/site/phone_eb_btn.jpg');
		}
		
		$('#chkServiceTime :radio').each(function(i, docElement){
			if(docElement.checked){
				docElement.checked = false;
			}
		});
		$('#ServiceTime_0').attr('checked', true);
		changeImg();
		$('#captcha').focus(captchaFocus);
	}
	
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
                <td><a href="mobile.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/mobile.jpg" alt="手机充值卡" /></a></td>
                <td><a href="onlinebanking.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/bank.jpg" alt="网上银行" /></a></td>
                <td><a href="telephone.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/phone_active.jpg" alt="固定电话" /></a></td>
                <td>
                	<a href="login.html" class="login_fancy" id="login">
                	
                	<img src="http://assets.9aola.com/baitianpay/images/site/mobile_msg2.jpg" alt="手机短信" /></a></td>
              </tr>
            </table>
          </div>
          <div class="main_cen">
            <div class="main_top"></div>
            <div class="main_content">
              <div id="phoneButton"><span id="ebillingBtn"><img src="http://assets.9aola.com/baitianpay/images/site/phone_eb_btn_active.jpg" /></span> <span id="vPayBtn"><img src="http://assets.9aola.com/baitianpay/images/site/phone_vp_btn.jpg" /></span> </div>
              <div class="eBilling">
                <div class="main_content_desc">
                  <div class="desc_content">
                    <p>您选择了“<strong class="red_text">eBilling电话</strong>”充值方式，您可以拨打家中的固定电话进行充值。充值时请注意以下几个问题：</p>
                    <p></p>
                    <p class="grayText2">1.请确认您所在的地区是否已开通固定电话支付功能。目前此充值方式只支持<span style="color:#FF0000">北京，上海，浙江，福建，广西，广东，重庆，辽宁，山东，河南，黑龙江，海南，南京，云南、江西、湖南、吉林</span>的用户。</p>
                    <p class="grayText2">2.在充值过程中如有提示充值失败，请等待一段时间，不要反复拨打电话充值。</p>
                    <p class="grayText2">3.充值时，要先征得家长的同意或者在家长的帮助下完成充值。</p>
                    <p class="grayText2">4.充值前，建议先查看eBilling充值帮助说明。<a href="cardhelp.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
                    <p class="red_text">如果你不在“eBilling”电话开通的地区，请点击“全国固定电话充值</p>
                  </div>
                </div>
                <br/>
                <div class="btm_desc">
                  <p style="text-indent:30px; font-size:14px; color:#e55701; font-weight:bold;">充值步骤如下：</p>
                  <p style="text-indent:30px;">第一步：填写你要充值的多多号，并选择充值金额，点击“下一步”。</p>
                  <p style="text-indent:30px;">第二步：确认充值信息后，点击“确定”，按照页面提示填写付费电话。</p>
                  <p style="text-indent:30px;">第三步：在3分钟内按页面提示，用刚才填写的付费电话，拨打页面提示的声讯号码。</p>
                  <p style="text-indent:30px;">第四步：根据语音提示完成操作后，请挂机。</p>
                  <p style="text-indent:30px;">第五步：点击“获取服务”，页面提示充值成功。</p>
                </div>
              </div>
              <div class="vPay">
                <div class="main_content_desc_vpay">
                  <div class="desc_content">
                    <p>您选择了“<strong class="red_text">全国固定电话（V币）</strong>”充值方式。<a href="payhelp.html#vpay" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
                    <p></p>
                    <p><strong>请先拨打页面下方地图中您所在地的热线购买V币，根据语音提示购买15V币或30V币。小朋友拨打电话充值前务必取得家长同意。</strong></p>
                    <p style="color:#e84200;padding:0 0 5px 0;margin:0;"><img src="http://assets.9aola.com/baitianpay/images/alarm.jpg" align="absmiddle" />&nbsp;<b>资费说明：</b></p>
                    <p style="color:#e84200;padding:0 0 5px 0;margin:0;">开通一个月 需10奥币，10奥币＝15V币，电话购买15V币，需15元费用。</p>
          			<p style="color:#e84200;padding:0 0 5px 0;margin:0;">开通二个月 需20奥币，20奥币＝30V币，电话购买30V币，需30元费用。</p>
                  </div>
                </div>
              </div>
              <div class="vPay">
                <div class="btm_desc">
                  <div style=" background:url(http://assets.9aola.com/baitianpay/images/site/buy_bj.gif) no-repeat;height:33px;width:540px;margin:5px 0 10px 25px;text-indent:114px; text-align:left;line-height:33px;">（充值过程中如有疑问可拨打V币客服电话：0755－82126199）</div>
                  <div style="background:url(http://assets.9aola.com/baitianpay/images/site/vpay_step.jpg) no-repeat; width:540px; height:133px; margin-left:23px;">
                  	<div style="padding-top:35px; margin-left:5px;">
                    <table style="font-size:12px;">
                      <tr>
                        <td width="105px" style="text-align:center;">查看地图中您所在地的充值热线</td>
                        <td width="42px">&nbsp;</td>
                        <td width="105px">拨打充值热线，根据语音提示购买15V币或30V币</td>
                        <td width="42px">&nbsp;</td>
                        <td width="105px">认真记录电话中播报的15位V币号码和6位V币密码</td>
                        <td width="42px">&nbsp;</td>
                        <td width="105px">在页面上方输入相关信息，点击"下一步"确认开通信息，完成开通过程。</td>
                      </tr>
                    </table>
                    </div>
                  </div>
                </div>
                <div id="vPayMap" style="margin-left:19px; margin-top:10px; margin-bottom:10px; width:575px;">
                  <iframe src="http://map.vnetone.com/?f=62&pic=onlymap&ShowNotOpenedTip=false&g=9" frameborder="0" scrolling="no" width="575px" height="320px" allowtransparency="true"></iframe>
                </div>
              </div>
              <div class="main_contents" style="height:350px">
                <form id="payForm" name="payForm" method="post" action="/orderpay.jsp">
                  <table width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                      <td width="120" align="right">请输入多多号：<!--<a href="javascript:showAnimation('1');" title="看动画演示"><img src="http://assets.9aola.com/baitianpay/images/site/questionmark.jpg" style="vertical-align:middle;" /></a>--></td>
                      <td width="171"><input name="Account" type="text" id="Account" size="20" maxlength="9" class="textbox" />
                      </td>
                      <td><div><span class="grayText">多多号就是登录游戏的帐号哦</span><!--<a href="javascript:fade('accountForget');">忘记奥银帐号？</a>-->
                          <div id="accountForget" style="display:none;">奥银帐号是你在奥比岛银行里使用的帐号，每个小奥比都有一个奥银帐号，如果你还不知道的话，赶快<a href="http://play.aobi.com" target="_blank">进入奥比岛</a>，打开ATM机看看吧！</div>
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
                    <tr class="EB_province">
                    	<td width="120" class="td_first">请选择地区：</td>
                    	<td class="td_second">
                    		<select name="province_select" id="province_select" class="textbox" style="wideth:80px" onchange="selectProvinceForOpenVip(this)"></select>
                    	</td>
                    	<td>
                    		<div id="provinceValidate" class="Validate"></div>
                    	</td>
                    </tr>
                    <tr>
                      <td align="right">开通时长：</td>
                      <td><div id="chkServiceTime">
                          <div class="vPay">
                      		 <label for="ServiceTime_0">
                          		<input name="ServiceTime" type="radio" id="ServiceTime_0"
                            value="1" checked="checked" class="radioStyle" />
                          1个月（10奥币） </label><br/>
                          	<label for="ServiceTime_0">
                         		 <input type="radio" name="ServiceTime" value="2"
                                    id="ServiceTime_1" class="radioStyle" />
                          2个月（20奥币）</label>
                      	</div>
                      	<div class="eBilling">
                      		<div id="eB_month1">
                          			<input name="ServiceTime" type="radio" id="ServiceTime_0"
                            		value="1" checked="checked" class="radioStyle" />
                          			1个月（10奥币）<br/>
                          </div>
                          <div id="eB_month2">
                         		 <input type="radio" name="ServiceTime" value="2"
                                    id="ServiceTime_1" class="radioStyle" />
                          2个月（20奥币）<br/>
                          </div>
                          <div id="eB_month3">
                          		<input type="radio" name="ServiceTime" value="3"
                                   id="ServiceTime_2" class="radioStyle" />
                          		3个月（30奥币）
                          </div>
                      	</div>       
                      </td>
                      <td class="grayText"><div class="vPay"><div><font color="red">只支持15V和30V的V币充值</font> </div>
                        <div id="serviceTimeValidate" class="Validate"></div></div></td>
                    </tr>
                    <tr class="vPay_tr">
                      <td align="right">V币号码：</td>
                      <td><input name="VPayNumber" type="text" id="VPayNumber"
                    size="20" maxlength="15" class="textbox" /></td>
                      <td class="grayText"><div>（15位，尾三位为015是15V币，尾三位为030是30V币）</div>
                        <div id="VPayNumberValidate" class="Validate"></div></td>
                    </tr>
                    <tr class="vPay_tr">
                      <td align="right">V币密码：</td>
                      <td><input name="VPayPassword" type="text" id="VPayPassword"
                    size="20" maxlength="6" class="textbox" /></td>
                      <td class="grayText"><div>（6位）</div>
                        <div id="VPayPasswordValidate" class="Validate"></div></td>
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
		   		  <input type="hidden" name="payType" id="payType" value="4"/>
            	  <input type="hidden" name="Position" id="Position" value="1" />
                </form>
              </div>
              <div class="eBilling"> <br/>
                <div class="eb_desc">
                  <p>资费说明：开通一个月 需10奥币，通过eBilling 充值需支付15元人民币</p>
                  <p>开通两个月 需20奥币，通过eBilling 充值需支付30元人民币</p>
                  <p>开通三个月 需30奥币，通过eBilling 充值需支付45元人民币</p>
                </div>
                
               <!-- <div style="color: #666666;">
            <p style="color: #ff7901;	font-weight: bold; margin: 5px auto;">温馨提示：</p>
            <p style=" margin: 5px auto; text-indent:35px;">1.在填写要充值的奥银帐号时请仔细填写并确认，以免输入错误导致为他人充值。</p>
            <p style=" margin-top: 5px; text-indent:35px;">2.请在父母的指导下操作。</p>
          </div>-->
                
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
    <!--<div class="error"><img src="http://assets.9aola.com/baitianpay/images/site/error.png" alt="出错啦" /></div>-->
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
