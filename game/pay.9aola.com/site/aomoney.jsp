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
<meta http-equiv="keywords" content="奥拉星,开通蓝宝石" />
<meta http-equiv="description" content="奥拉星,开通蓝宝石" />
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
	var account = "";
	var confirmAccount = "";
	var cardNumber = "";
	var cardPassword = "";
	var captcha = "";
	var isAola = true;
	var isUseAobi = true;
	var isHtml = false;
		
	var domReady = function(){
		$('#Account').focus(AccountFocus);
		$('#ConfirmAccount').focus(ConfirmAccountFocus);
		$('#ConfirmAccount').blur(ConfirmAccountBlur);
		$('#CardNumber').blur(CardNumberBlur);
		$('#CardNumber').focus(CardNumberFocus);
		$('#CardPassword').focus(CardPasswordFocus);
		$('#captcha').focus(captchaFocus);
	};
	
	var loadValues = function(){
		account = $('#Account').val();
		confirmAccount = $('#ConfirmAccount').val();
		cardNumber = $('#CardNumber').val();
		cardPassword = $('#CardPassword').val();
		serviceTime = "";
		captcha = $('#captcha').val();
		
		return true;
	}
	
	var clientCheck = function(){
		hideValidate('AccountValidate');
		hideValidate('ConfirmAccountValidate');
		hideValidate('CardNumberValidate');
		hideValidate('CardPasswordValidate');
		hideValidate('CaptchaValidate');
		
		return (checkAccount(account, confirmAccount) && checkCardNumber(cardNumber) && checkCardPassword(cardPassword) && checkCaptcha(captcha));
	}
	
	function checkCallBack(){
		this.userName;
		this.money;
		this.fun = function(){
			$('#orderAccount').text(account);
			$('#orderAobiMoney').text(this.money);
			$('#orderAmount').text(this.money + "奥币");
			$("#dialoglink").click();
		}
	}
	
	function checkData(){
		if(check()){
			var arr = { Account:account, CardNumber:cardNumber, CardPassword:cardPassword, captcha:captcha, CheckType:'WebSiteBalance' };
			serverCheck(arr, checkCallBack);
		}
	}
	
	function getCheckButton(form){
		for(var i=0; i<form.ServiceTime.length; i++){
			if(form.ServiceTime[i].checked){
				return i;
			}
		}
	}
	
	function openvip(){
		form = document.forms[0];
		var checkRadioId = getCheckButton(form);
		var serviceTime = form.ServiceTime[checkRadioId].value;
		if(serviceTime*1000>parseFloat(MyAobiBalance)){
			$('errorMsg').text = "你的奥币不足哦！";
			return;
		}
		var memberType = $('#memberType').val();
		var gameId = $('#gameId').val();		
		var arr = {"Account":duoduoId, "ServiceTime":serviceTime,"MemberType":memberType,"GameId":gameId};
		$.post("/useaobi.jsp",arr,function(data){
			deal(data);
		});
	}
	function deal(data){
		var values = data.split("|");
		if(values[0]=="success"){
			$('#aobi_success1').css('display','block');
			$('#aobiForm').css('display','none');
			$(".main_contents").height(60);
		} else{
			$('.error3').css('display','block');
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
      <div class="title" style="left:45px;"><img src="http://assets.9aola.com/baitianpay/images/site/vip_title.jpg" alt="" /><br/></div>
      <div class="mainbg">
        <div class="mainContainer">
          <div class="payWayDesc grayText">你可以选择下面的方式开通蓝宝石</div>
          <div class="payWayBar">
            <table cellspacing="0" cellpadding="0">
              <tr>
                <td><a href="aomoney.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/money_active.jpg" alt="奥币" /></a></td>
                <td id="active_waybar"><a href="mycard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/duoduocard2.jpg" alt="多多卡充值" /></a></td>
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
              <div class="main_contents" style="height:209px">
			  <form id="aobiForm">
                <table width="550" cellpadding="0" cellspacing="0" class="aomtable">
                  <tr>
                    <td width="97" align="right">多多号：</td>
                    <td width="423"><input id="account" class="namecolor" disabled="disabled"/></td>
                  </tr>
                  <tr>
                    <td align="right">我的奥币：</td>
                    <td><input id="aobi" class="mcolor" disabled="disabled"/></td>
                  </tr>
                  <tr>
                    <td align="right">选择开通时长：</td>
                    <td>
                    	<p><input type="radio" name="ServiceTime" id="ServiceTime_0" checked="checked" value="1"/>1个月（需10奥币）&nbsp;&nbsp;&nbsp;<input type="radio" name="ServiceTime" id="ServiceTime_1" value="3"/>3个月（需30奥币）</p>
                        <p><input type="radio" name="ServiceTime" id="ServiceTime_2" value="5"/>5个月（需50奥币）&nbsp;&nbsp;&nbsp;<input type="radio" name="ServiceTime" id="ServiceTime_3" value="10"/>10个月（需100奥币）</p>
                    </td>
                  </tr>
                 <!-- <tr>
                    <td colspan="2"><input type="checkbox" id="autopay" name="autopay" />&nbsp;自动续费<span class="pray">（每月自动从你的帐号中扣除额定的费用）</span></td>
                  </tr>-->
                  <tr>
                    <td colspan="2" align="center"><a href="javascript:openvip()"><img src="http://assets.9aola.com/baitianpay/images/openmember_03.jpg" alt="确认开通" /></a></td>
                  </tr>
                </table>
                <input type="hidden" id="memberType" name="MemberType" value="4"/>
                <input type="hidden" id="gameId" name="GameId" value="2"/>
				</form>
              </div>
            <div id="errorMsg"></div>
			<div id="aobi_success1" class="aom_success">
            	<p><img src="http://assets.9aola.com/baitianpay/images/site/cosuccess_words.png" alt="恭喜你开通/续费蓝宝石成功！
重新登录之后即可拥有尊贵的蓝宝石服务！" /></p>
            	<p><img src="http://assets.9aola.com/baitianpay/images/site/refurbish_words.png" alt="你的游戏将会进行刷新，请重新登录游戏。" /></p>
                <p><a href="http://www.9aola.com"><img src="http://assets.9aola.com/baitianpay/images/site/enter_btn.jpg" alt="立即进入奥拉星" /></a></p></div>
            <div id="aobi_success2" class="aom_success">
            	<p><img src="http://assets.9aola.com/baitianpay/images/site/cosuccess_words3.png" alt="恭喜你开通/续费蓝宝石成功！
重新登录之后即可拥有尊贵的蓝宝石服务！" /></p>
            	<p><img src="http://assets.9aola.com/baitianpay/images/site/refurbish_words.png" alt="你的游戏将会进行刷新，请重新登录游戏。" /></p>
                <p><a href="http://www.9aola.com"><img src="http://assets.9aola.com/baitianpay/images/site/enter_btn.jpg" alt="立即进入奥拉星" /></a></p></div>
                <div class="error3"><img src="http://assets.9aola.com/baitianpay/images/site/error3.jpg" alt="" /></div>
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
</body>
</html>
