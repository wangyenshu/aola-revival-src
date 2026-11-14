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
	background:url(http://assets.9aola.com/baitianpay/images/site/bank_desc_bg.jpg) no-repeat scroll 0 0;
	width:530px;
	height:202px;
	position:relative;
	left:38px;
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
</style>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/swfobject.js"></script>
<script language="JavaScript" type="text/javascript">
        var homePage = true; 		
</script>
<script src="http://assets.9aola.com/baitianpay/js/nav.js" language="javascript" type="text/javascript"></script>
<link href="http://assets.9aola.com/baitianpay/css/jquery.fancybox.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/jquery.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/jquery.fancybox.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/global.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/site.js"></script>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/site_ruby.js"></script>
<script type="text/javascript">
	var account = "";
	var confirmAccount = "";
	var serviceTime = "";
	var opId = "";
	var gameId = "";
	var captcha = "";
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
		$('#captcha').keydown(function(event){if(event.keyCode == 13) checkData();});
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
		
		return true;
	}
	
	var clientCheck = function(){
		hideValidate('AccountValidate');
		hideValidate('ConfirmAccountValidate');
		hideValidate('ServiceTimeValidate');
		hideValidate('CaptchaValidate');
		
		return (checkAccount(account, confirmAccount) && checkCaptcha(captcha));
	}
	
	function checkCallBack(){
		this.userName;
		this.fun = function(){
			var intServiceTime = parseInt(serviceTime);	
			$('#orderAccount').text(account);
			$('#orderServiceTime').text(intServiceTime==12?'1年':intServiceTime + '个月');
			$('#orderAmount').text(intServiceTime * 10 + '元');			
			$("#dialoglink").click();
		}
	}
	
	function checkData(){
		if(check()){
			var arr = { Account:account, captcha:captcha, OpId:opId, GameId:gameId, ServiceTime:serviceTime};
			serverAccountCheck(arr, checkCallBack);
		}
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
                <td><a href="onlinebanking.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/bank_active.jpg" alt="网上银行" /></a></td>
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
              <div class="main_content_desc">
                <div class="desc_content">
                  <p>您选择了“网上银行”充值方式，在使用此充值方式时，请确认您的银行卡已开通网上
                    银行支付功能（开通网上银行支付功能可到当地银行办理，一般1个工作日即可完成）。
                    您可以通过以下几种途径完成网上银行充值过程：</p>
                  <p></p>
                  <p class="grayText2">1.家长使用本人的网上银行并按照步骤完成充值；<a href="cardhelp.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
                  <p class="grayText2">2.可以请经常在网上购物的亲戚、朋友等年轻人帮忙完成充值；</p>
                  <p class="grayText2">特别提醒：为了您的银行帐号安全，请不要在公共场所（例如网吧、学校）使用网上
                    银行支付功能。</p>
                </div>
              </div>
              <div class="main_contents">
                <form id="payForm" name="payForm" method="post" action="/orderpay.jsp">
                  <table width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                      <td width="120" align="right">请输入多多号：<!--<a href="javascript:showAnimation('1');" title="看动画演示"><img src="http://assets.9aola.com/baitianpay/images/site/questionmark.jpg" style="vertical-align:middle;" /></a>--></td>
                      <td width="171"><input name="Account" type="text" id="Account" size="20" maxlength="9" class="textbox" /></td>
                      <td><div><span class="grayText">多多号就是登录游戏的帐号哦</span><!--<a href="javascript:fade('accountForget');">什么是奥银帐号？</a>-->
                          <div id="accountForget" style="display:none;">奥银帐号是你在奥比岛银行里使用的帐号，每个小奥比都有一个奥银帐号，如果你还不知道的话，赶快<a href="http://play.aobi.com" target="_blank">进入奥比岛</a>，打开ATM机看看吧！</div>
                        </div>
                        <div id="AccountValidate" class="Validate"></div></td>
                    </tr>
                    <tr id="confirmTr">
                      <td align="right">请再输入多多号：</td>
                      <td><input name="ConfirmAccount" type="text" id="ConfirmAccount"
						size="20" maxlength="9" class="textbox" />
                      </td>
                      <td class="grayText"><div>确定充值的多多号正确</div>
                        <div id="ConfirmAccountValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                    	<td colspan="3" align="center" valign="middle">
                    		<strong class="red_text">别轻信网络上“系统漏洞”，“系统错误”等诈骗手段，别填写骗子的多多号，防止被骗！</strong>
                    	</td>
                    </tr>
                    <tr>
                      <td align="right">开通时长：</td>
                      <td colspan="2"><div id="chkServiceTime">
                          <label for="ServiceTime_0">
                          <input type="radio" name="ServiceTime" value="1"
								id="ServiceTime_0" class="radioStyle" />
                          1个月（10元） </label>
                          <label for="ServiceTime_1">
                          <input type="radio" name="ServiceTime" value="2"
								id="ServiceTime_1" class="radioStyle" />
                          2个月（20元） </label>
                          <label for="ServiceTime_2">
                          <input type="radio" name="ServiceTime" value="3"
								id="ServiceTime_2" checked="checked" class="radioStyle" />
                          3个月（30元） </label><br/>
                          <label for="ServiceTime_3">
                          <input type="radio" name="ServiceTime" value="5"
								id="ServiceTime_3" class="radioStyle" />
                          5个月（50元） </label>
                          <label for="ServiceTime_4">
                          <input type="radio" name="ServiceTime" value="10"
								id="ServiceTime_4" class="radioStyle" />
                          10个月（100元） </label>
                          <label for="ServiceTime_5">
                          <input type="radio" name="ServiceTime" value="12"
								id="ServiceTime_5" class="radioStyle" />
                          12个月（120元） </label>
                        </div>
                        <div></div>
                        <div id="serviceTimeValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                      <td align="right">选择支付银行：</td>
                      <td colspan="2" style="padding:0px;"><div style="height:310px; overflow-y:scroll;">
                          <table style="width:100%;_width:96%;">
                            <tr>
                              <td><label for="CMB">
                                <input id="CMB" name="bankId" type="radio" value="CMB" checked />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_03.jpg" alt="招商银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="ICBC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_05.jpg" alt="中国工商银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="CCB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_09.jpg" alt="中国建设银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="BCOM" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_10.jpg" alt="交通银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="ABC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_13.jpg" alt="中国农业银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="SPDB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_14.jpg" alt="上海浦东发展银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="CMBC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_17.jpg" alt="中国民生银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="SDB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_18.jpg" alt="深圳发展银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="CIB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_21.jpg" alt="兴业银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="BOB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_22.jpg" alt="北京银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="BOC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_25.jpg" alt="中国银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="CEB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_26.jpg" alt="中国光大银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="GDB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_29.jpg" alt="广东发展银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="CITIC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_12.jpg" alt="中信银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="HXB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_30.jpg" alt="华夏银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="GZCB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_03.jpg" alt="广州市商业银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="SHRCC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_05.jpg" alt="上海农村商业银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="CPSRB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_07.jpg" alt="中国邮政储蓄" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="GZRCC" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_13.jpg" alt="广州市农村信用合作社" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="CBHB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_14.jpg" alt="渤海银行" class="bank_icon" /></label></td>
                            </tr>
                            <tr>
                              <td><label>
                                <input name="bankId" type="radio" value="BJRCB" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_18.jpg" alt="北京农村商业银行" class="bank_icon" /></label></td>
                              <td><label>
                                <input name="bankId" type="radio" value="UPOP" />
                                <img src="http://assets.9aola.com/baitianpay/images/bank/bank_icon_other_30.jpg" alt="中国银联" class="bank_icon" /></label></td>
                            </tr>
                          </table>
                        </div>
                        <input type="hidden" name="OpId" id="OpId" value="200"/>
						<input type="hidden" name="GameId" id="GameId" value="2"/>
						<input type="hidden" name="MemberType" id="MemberType" value="4"/>
						<input type="hidden" name="payType" id="payType" value="2"/>
       					<input type="hidden" name="Position" id="Position" value="1" />
                      </td>
                    </tr>
                    <tr>
                      <td class="td_first">验证码：</td>
                      <td colspan="2"><input name="captcha" type="text" id="captcha" size="15" maxlength="4" class="textbox" />
                        <img id="imgCaptcha" src="/imagecaptcha.jsp?actionType=2" /> <a href="javascript:changeImg()">看不清，换一张</a>
                        <div></div>
                        <div id="CaptchaValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                      <td colspan="3" align="center" valign="middle"><div id="checkButton" style="margin:5px 0px;"> <a href="javascript:checkData()"><img src="http://assets.9aola.com/baitianpay/images/next_step.jpg" alt="下一步" /></a>
                        <div id="loading" style="display:none;">loading....</div></div></td>
                    </tr>
                  </table>
                </form>
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
<div style="display:none">
<a href="#dialog" id="dialoglink" class="fancybox" style="display:none;"></a>
<div id="dialog">
  <div class="dialog_top"><span style="position:relative; top:30px; left:120px;"><img src="http://assets.9aola.com/baitianpay/images/site/confirm_desc.jpg" /></span></div>
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
