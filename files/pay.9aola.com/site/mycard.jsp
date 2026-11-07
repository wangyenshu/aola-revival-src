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
	background:url(http://assets.9aola.com/baitianpay/images/site/desc_bg.jpg) no-repeat scroll 0 0;
	width:540px;
	height:174px;
	position:relative;
	left:33px;
}
.desc_content {
	position:relative;
	top:15px;
	left:35px;
	width:440px;
}
.desc_content p {
	text-indent:0px;
	padding-bottom:3px;
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
	var isAola = true;
	var account = "";
	var confirmAccount = "";
	var opId = "";
	var gameId = "";
	var cardNumber = "";
	var cardPassword = "";
	var serviceTime = "";
	var captcha = "";
	var isUseAobi = false;
	var isHtml = false;

	var domReady = function(){
		$('#Account').focus(AccountFocus);
		$('#Account').blur(AccountBlur);
		$('#ConfirmAccount').focus(ConfirmAccountFocus);
		$('#ConfirmAccount').blur(ConfirmAccountBlur);
		$('#CardNumber').blur(CardNumberBlur);
		$('#CardNumber').focus(CardNumberFocus);
		$('#CardPassword').focus(CardPasswordFocus);
		$('#chkServiceTime').click(ServiceTimeFocus);
		$('#captcha').focus(captchaFocus);
		$('#captcha').keydown(function(event){if(event.keyCode == 13) checkData();});
	};
	
	var loadValues = function(){
		account = $('#Account').val();
		confirmAccount = $('#ConfirmAccount').val();
		opId = $("#OpId").val();
		gameId = $("#GameId").val();
		cardNumber = $('#CardNumber').val();
		cardPassword = $('#CardPassword').val();
		captcha = $('#captcha').val();
		var length = cardNumber.length;
		var str = cardNumber.substring(length - 3, length - 1);
		if(str == "30") {
			serviceTime = "3";
		} else {
			serviceTime = "1";
		} 
		return true;
	}
		
	
	var clientCheck = function(){
		hideValidate('AccountValidate');
		hideValidate('ConfirmAccountValidate');
		hideValidate('CardNumberValidate');
		hideValidate('CardPasswordValidate');
		hideValidate('ServiceTimeValidate');
		hideValidate('CaptchaValidate');
		
		return (checkAccount(account, confirmAccount) && checkCardNumber(cardNumber) && checkCardPassword(cardPassword) && checkCaptcha(captcha));
	}
	
	function checkCallBack(){
		this.userName;
		this.money;
		this.fun = function(){
			var intServiceTime = parseInt(serviceTime);	
			$('#showAccount').text(account);
			$('#showServiceTime').text(intServiceTime==12?'1年':intServiceTime + '个月');
			$('#showMoney').text(this.money + " 元");
			var balance = this.money - intServiceTime *10;
			if(balance > 0){
				$('#showTips').text('友情提示：多多卡内剩余的 ' + balance + '奥币 将存入你的多多号帐户中。');
				$('#showTips').css('display', 'block');
			}else{
				$('#showTips').css('display', 'none');
			}
			$("#dialoglink").click();
		}
	}
	
	function checkData(){
		if(check()){
			var arr = { Account:account, CardNumber:cardNumber, CardPassword:cardPassword, ServiceTime:serviceTime, captcha:captcha, OpId:opId, GameId:gameId };
			serverCheck(arr, checkCallBack);
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
                <td id="active_waybar"><a href="mycard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/duoduocard2_active.jpg" alt="多多卡充值" /></a></td>
                <td><a href="mobile.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/mobile.jpg" alt="手机充值卡" /></a></td>
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
              <div class="main_content_desc">
                <div class="desc_content">
                  <p>您选择了"多多卡"（<span style="color:red;font-weight:bold;">原奥比建设卡</span>）的充值方式，如果你还没有"多多卡"，请参考以下步骤：</p>
                  <p></p>
                  <p class="grayText2">1.请查询您家或学校附近的多多卡售卖点；<a href="duocardsold.html" target="_blank" title="查询售卖点"><img src="http://assets.9aola.com/baitianpay/images/site/search_saler_btn.png" alt="查询售卖点" style="vertical-align:middle" /></a></p>
                  <p class="grayText2">2.请您到附近的售卖点购买多多卡；</p>
                  <p class="grayText2">3.刮开密码涂层，打开本页面按步骤完成充值；</p>
                  <p class="grayText2">4.充值前，建议您先查看多多卡的充值帮助说明。<a href="cardhelp.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/site/pay_help_btn.png" alt="充值说明" style="vertical-align:middle" /></a></p>
                  <p class="grayText2">5.多多卡就是原奥比建设卡，你可以使用原奥比建设卡进行充值。</p>
                </div>
              </div>
              <div class="main_contents" style="height:309px;">
                <form id="cardpayForm" name="cardpayForm" method="post"
		action="cardpay.jsp">
                  <table cellspacing="0" cellpadding="0">
                  	<tr>
                      <td width="138" class="td_first">请输入多多卡卡号：<img src="http://assets.9aola.com/baitianpay/images/site/questionmark.jpg" style="vertical-align:middle;" title="多多卡就是原奥比建设卡" alt="多多卡就是原奥比建设卡" /></td>
                      <td width="193" class="td_second"><input name="CardNumber" type="text" id="CardNumber" size="20" maxlength="11" class="textbox" />
                      </td>
                      <td width="204" class="td_third"><div>多多卡号（11位阿拉伯数字）</div>
                        <div id="CardNumberValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                      <td class="td_first">请输入多多卡密码：</td>
                      <td class="td_second"><input name="CardPassword" type="text" id="CardPassword" size="20" maxlength="16" class="textbox" />
                      </td>
                      <td class="td_third"><div>刮开涂层，得到的密码（16位）</div>
                        <div id="CardPasswordValidate" class="Validate"></div></td>
                    </tr>
                    <tr>
                      <td class="td_first">请输入多多号：</td>
                      <td class="td_second"><input name="Account" type="text" id="Account" size="20" maxlength="9" class="textbox" />
                      </td>
                      <td class="td_third"><div>
                      	<span class="grayText">多多号就是登录游戏的帐号哦</span>
                        </div>
                        <div id="AccountValidate" class="Validate"></div></td>
                    </tr>
                    <tr id="confirmTr">
                      <td class="td_first">请再次输入多多号：</td>
                      <td class="td_second"><input name="ConfirmAccount" type="text" id="ConfirmAccount"
						size="20" maxlength="9" class="textbox" />
                      </td>
                      <td class="td_third"><div>确定充值的多多号正确</div>
                        <div id="ConfirmAccountValidate" class="Validate"></div></td>
                    </tr>
                     <tr>
                    	<td colspan="3" align="center" valign="middle">
                    		<strong class="red_text">别轻信网络上“系统漏洞”，“系统错误”等诈骗手段，别填写骗子的多多号，防止被骗！</strong>
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
                      <td colspan="3" align="center" valign="middle"><div id="checkButton" style="margin:5px 0px;"> <a href="javascript:checkData();"><img src="http://assets.9aola.com/baitianpay/images/openmember_03.jpg" alt="确认开通" /></a> </div>
                        <div id="loading" style="display:none;">loading....</div></td>
                    </tr>
                  </table>
				  <p><input type="hidden" name="Position" id="Position" value="1" /></p>
       	 		  <p><input type="hidden" name="GameId" id="GameId" value="2" /></p>
        		  <p><input type="hidden" name="MemberType" id="MemberType" value="4" /></p>
        		  <p><input type="hidden" name="OpId" id="OpId" value="200" /></p>
                </form>
              </div>
            </div>
            <div class="main_btm"></div>
          </div>
          <div style="color: #666666; top:100px;">
            <p style="color: #ff7901;	font-weight: bold; margin: 5px auto;">温馨提示：</p>
            <p style=" margin: 5px auto; text-indent:35px;">1.在填写要充值的多多号时请仔细填写并确认，以免输入错误导致为他人充值。</p>
            <p style=" margin-top: 5px; text-indent:35px;">2.请在父母的指导下操作。</p>
          </div>
        </div>
		<div></div>
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
</div>
<div style="display:none">
<a href="#dialog" id="dialoglink" class="fancybox" style="display:none;"></a>
<div id="dialog">
  <div class="dialog_top"><span style="position: relative; top: 30px; left: 120px;"><img src="http://assets.9aola.com/baitianpay/images/site/confirm_desc.jpg"/></span></div>
  <div class="dialog_cen">
    <div class="dialog_contents">
      <table width="100%" border="1" cellspacing="0" cellpadding="0">
        <tr>
          <td align="right" width="188px">你要充值的多多号：</td>
          <td id="showAccount" width="360px;" align="left"></td>
        </tr>
        <tr>
          <td align="right">开通时长：</td>
          <td id="showServiceTime" align="left"></td>
        </tr>
        <tr>
          <td align="right">多多卡面值：</td>
          <td id="showMoney" align="left"></td>
        </tr>
        <tr>
          <td colspan="2" style="padding: 1em 1em; text-align:center;"><div>再次核对你的充值信息，确认无误后请点击“确定”，信息有误请选择“取消”。</div>
            <div id="showTips" style="color:#FF0000;">友情提示：多多卡内剩余的奥币将存入你的多多帐户中。</div></td>
        </tr>
        <tr>
          <td colspan="2"><div style="margin-top:5px; text-align:center;"> <a href="javascript:submitForm()"><img src="http://assets.9aola.com/baitianpay/images/ok.jpg" alt="确定" /></a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="javascript:$.fancybox.close();"><img src="http://assets.9aola.com/baitianpay/images/cancel.jpg" alt="取消" /></a> </div></td>
        </tr>
      </table>
    </div>
  </div>
  <div class="dialog_btm"></div>
</div>
</div>
</body>
</html>
