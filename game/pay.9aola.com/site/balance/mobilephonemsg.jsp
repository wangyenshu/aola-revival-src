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
*html .main_content_desc {
margin-left:12px;
}
.main_content_desc {
	background:url(http://assets.9aola.com/baitianpay/images/site/mobile_msg_bg.jpg) no-repeat 0 0;
	width:543px;
	height:250px;
	margin-left:-3px;
}
.desc_content {
	position:relative;
	top:15px;
	left:15px;
	width:480px;
}
.desc_content p {
	text-indent:0px;
	padding-bottom:6px;
}

*html #msg_head{
	margin-left:-5px;
}

#msg_head{
	text-align:center;
	line-height:0;
	margin-left:-35px;
	_line-height:1px ;_font-size:1px ;
}

#dianxin_mobile{
	line-height:20px;
}

#dianxin_mobile p{
	padding-left:15px;
}

#buy_btn{
	text-align:center;
}

#yidong_table table{
	border:1px solid #999999;
	font-size:12px;
	height:125px;
	margin-left:2px;
	width:510px;
	z-index:10px;
}

.pelev table{
	border:1px solid #999999;
	background-color:#FFFFFF;
	font-size:12px;
	width:510px;
	z-index:10px;
	margin-left:40px;
	_margin-left:-10px;
}

#c_one .pelev {
	padding-bottom: 20px;
}

.pelev td{
	 border: solid 1px #999999;
     font-size:13px;
     line-height:20px;
     padding:7px 0;
} 

#addMobile:hover{
	cursor: pointer;
}
</style>
<script type="text/javascript" src="http://assets.9aola.com/baitianpay/js/iepng.js"></script>
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
	var isHtml = false;
	var type = 0;
	var mobile = -1;
	
	var domReady = function(){
		selectYidong();
		$('#mobileNum').focus(mobileFocus);
		$('#imgCaptcha').focus(captchaFocus);
		if(duoduoId==0){
			window.location.href="http://pay.9aola.com";
		}
	}	
	
	function mobileFocus(){
		hideValidate('mobileValidate');
	};
	
	function captchaFocus(){
		hideValidate('CaptchaValidate');	
	};
	
	function selectYidong(){
		if(type==1){
			return;
		}
		type = 1;
		if(mobile == -1){
			hasBind(duoduoId);
		}
		$('#yidong_mobile').css('display','block');
		$('#yidong_des').css('display', 'none');
		var yd_src = $('#yd_head').attr('src');
		$('#yd_head').attr('src', yd_src.replace('.jpg','_active.jpg'));
		
		var dx_src = $('#dx_head').attr('src');
		$('#dx_head').attr('src', dx_src.replace('_active.jpg','.jpg'));
		$('#dianxin_mobile').css('display','none');
		$('#DuoduoId').val(duoduoId);
	};

	function selectDianxin(){
		if(type==2){
			return;
		}
		type = 2;
		$('#dianxin_mobile').css('display','block');
		var dx_src = $('#dx_head').attr('src');
		$('#dx_head').attr('src', dx_src.replace('.jpg','_active.jpg'));
		
		var yd_src = $('#yd_head').attr('src');
		$('#yd_head').attr('src', yd_src.replace('_active.jpg','.jpg'));
		$('#yidong_mobile').css('display','none');
		$('#DuoduoId').val(duoduoId);
	}
	
	function mobileMsgNextStep(){
		var mobileNum = $("#mobileNum").val();
		var captcha = $("#captcha").val();
		if(mobileNum == ''){
			showValidate('mobileValidate', '请填写手机号!');
			return;
		}
		if(captcha == ''){
			showValidate('CaptchaValidate', '请填写验证码!');
			return;
		}
		$.post("/mobilemsgpay.jsp",{mobileNum:mobileNum, captcha:captcha},callback);
	};
	
	function callback(data){
		var values = data.split('|');
		if(values[0] == 'ok'){
			$('#op_des').css("display", 'block');
			$('#mobileMsgTb').css("display", 'none');
		} else{
			showValidate('CaptchaValidate', '验证码错误');
			showValidate('mobileValidate', '手机号错误');
			changeImg();
		}
	};
	
	function resetBindData(){
		$("#mobileNum").val('');
		$("#bind_error").text('');
	}
	$(function(){
	    $(".input_2").click(function(){
	    	//前端验证
	    	
	       if(mobileNoCheck($("#mobileNum").val())){
	       		//后端验证
	       		mobileNoServerCheck($("#Account").val(),$("#mobileNum").val());
	       } else{
	       		$("#mobile_tip").hide();
	       	    $("#bind_error").show();
	       	    $("#bind_error").text("请输入11位移动手机号!");
	       }
		})
		$("#c_one .input_4").click(function(){
		   mobileBind($("#Account").val(),$("#mobileNum").val());
		})
		
		$("#c_one .input_5").click(function(){
		   $("#c_one").hide();
		   $(".new_yd").show();
		   $(".suoping").hide();
		  
		   
		})
		$("#c_two .input_4").click(function(){
		   $("#c_two").hide();
		   $(".new_yd").show();
		   $("#mobileNum").val('');
		   $(".suoping").hide()
		})
		$("#c_two .input_5").click(function(){
		   $("#c_two").hide();
		   $("#bindSuccessMobile").text($("#mobileNum").val());
		   $("#c_three").show();
		   //hasBind(duoduoId);
		})
		$("#c_three .input_4").click(function(){
		   $("#c_three").hide();
		   $(".now_cz").show();
		   $(".suoping").hide();
		   $(".new_yd").hide();
		})
		$("#c_three .input_5").click(function(){
		   $("#c_three").hide();
		   $(".new_yd").show();
		})
		$(".now_cz .input_6").click(function(){
		   var duoduoId = $('#DuoduoId').val();
		   var gameId = $('#GameId').val();
		   var goodsId = $('#GoodsId').val();
		   var mobileNo = $('#UserMobileNo').val();
		   if(goodsId==1){
		   	alert('请选择要开通的服务!');
		   	return;
		   }
		   if(!mobileNoCheck(mobileNo)){
		   	alert('请输入11位移动手机号');
		   	return;
		   }
		   checkMobileMsgOrder(duoduoId,goodsId,mobileNo);
		})
		$(".now_cz .input_7").click(function(){
		  $('#UserMobileNo').val('');
		})
		$("#addMobile").click(function() {
			$("#bindMobile").show();
			$("#mobileNum").val("");
			$(".new_yd").show();
			$(".now_cz").hide();
		});
	});
		
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
<style type="text/css">
.new_yd,.now_cz{ width:510px; height:230px; /*background:#FDFAEA;*/ line-height:20px;}
.new_yd p,.now_cz p{ padding:0;}
.p_red{ color:red;}
.small_font{font-size:11px;}
.xuzhi p{ float:left; width:40px;}
.xuzhi ul{ float:left; width:460px; margin-left:5px;}
.cz_box{}
.cz_box #bindTable input{ width:120px;}
.nie_blank{ height:0; font-size:0; overflow:hidden; clear:both;}
.cz_box .p_red{line-height:20px;}
.cz_box strong{ float:left; font-weight:normal;}
/** .cz_box input{ float:left;} */
.cz_box .input_1{ border:1px solid #2F822F; height:16px; width:150px;}
.cz_box #bindTable  .input_2{ width:80px; height:40px; background:url(http://assets.9aola.com/baitianpay/images/ok.jpg) no-repeat 0 0; border:0; cursor:pointer;}
/*.cz_box .input_2,.cz_box .input_3{ width:80px; height:26px; border:0; background:url(http://assets.9aola.com/baitianpay/images/site/bangding1.jpg) no-repeat; margin:-5px 0 0 20px; cursor:pointer;}*/
.cz_box .input_3{ background:url(http://assets.9aola.com/baitianpay/images/site/reset1.gif) no-repeat;}
.cz_first{line-height:22px; font-size:14px; display:none; position:fixed; _position:absolute; left:50%; top:50%; width:600px; min-height:250px!important; _height:250px; margin:-75px 0 0 -200px; z-index:2000;}
/*.cz_two{line-height:22px; font-size:14px; display:none; position:fixed; _position:absolute; left:50%; top:50%; width:450px; min-height:250px!important; _height:250px; margin:-50px 0 0 -120px; z-index:2000;}*/
.cz_two .mdbg .pelev{ position:relative; top:-30px;}
.cz_two .topbg{ height:61px; background:url(http://assets.9aola.com/baitianpay/images/dialog_mobile_top.gif) no-repeat}
.cz_two .mdbg{background:url(http://assets.9aola.com/baitianpay/images/dialog_mobile_cen.gif) repeat-y;}
.cz_first .mdbg .pelev{ position:relative; top:-30px;}
.cz_two .bottombg{ height:11px; background:url(http://assets.9aola.com/baitianpay/images/dialog_mobile_btm.gif) no-repeat}
.cz_first .input_4,.cz_first .input_5{width:74px; height:36px;  background:url(http://assets.9aola.com/baitianpay/images/ok.jpg) no-repeat; border:0;cursor:pointer; }
.cz_first .input_5{ background:url(http://assets.9aola.com/baitianpay/images/cancel.jpg) no-repeat}
.cz_two p{ padding:10px 60px 0 60px;}
.cz_first .none_qd{ width:170px; height:25px; position:absolute; background:#E8EEF7; top:16px; left:42px;}
.cz_two .input_4{width:80px; height:40px; background:url(http://assets.9aola.com/baitianpay/images/site/bangding1.jpg) no-repeat 0 0}
.cz_two .input_5{ height:42px; width:88px; background:url(http://assets.9aola.com/baitianpay/images/site/tiaoguo.jpg) no-repeat;}
.cz_three p{ padding-top:40px;}
.cz_three {display:none;}
.cz_three .input_4{margin-top:10px;width:80px; height:40px; background:url(http://assets.9aola.com/baitianpay/images/ok.jpg) no-repeat 0 0; border:0;cursor:pointer;}
.cz_three .input_5{ background:url(http://assets.9aola.com/baitianpay/images/site/cancel.jpg) no-repeat}
.now_cz{ display:none; line-height:18px; }
.now_cz table td{ border:0; border-bottom:solid 1px #999}
.now_cz input.inp_t{ border:1px solid #2F822F; height:16px; width:150px;}
.now_cz select{border:1px solid #2F822F; }
.now_cz .input_6,.now_cz .input_7{ width:100px; height:40px; background:url(http://assets.9aola.com/baitianpay/images/ok.jpg) no-repeat 0 0; border:0; margin-left:150px;cursor:pointer;}
.now_cz .input_7{ background-position:-103px 0; margin-left:20px;}
.now_cz .t_24{ text-indent:24px; display:block;}
.cz_true{ display:none;}
.cz_true .fs{ height:40px; border:1px solid #999; width:200px; font-size:16px; font-weight:bold; line-height:28px; padding:0 0 0 0px;letter-spacing:4px}
#go_topup {margin-left:7px;}
#bind_error{height:20px;}
#mobile_dlg_top{width:450px; height:61px;background:url(http://assets.9aola.com/baitianpay/images/dialog_mobile_top.gif)no-repeat 0 0}
#mobile_dlg_cen{width:450px; height:80px;background:url(http://assets.9aola.com/baitianpay/images/dialog_mobile_cen.gif)}
#mobile_dlg_btm{width:450px; height:11px;background:url(http://assets.9aola.com/baitianpay/images/dialog_mobile_btm.gif)no-repeat 0 0}


.suoping{ position:absolute; z-index:1000; left:0; top:0; width:100%; background:#000;}
</style>
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
                <td><a href="mobilephonemsg.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/mobile_msg_active.jpg" alt="手机短信" /></a></td>
                <td><a href="onecard.jsp"><img src="http://assets.9aola.com/baitianpay/images/site/other.jpg" alt="其它方式" /></a></td>
              </tr>
            </table>
          </div>
          <div class="main_cen">
            <div class="main_top"></div>
            <div class="main_contents" style="height:309px">
			  <div id="msg_head">
			  	<a href="javascript:selectYidong()"><img id="yd_head" src="http://assets.9aola.com/baitianpay/images/site/yd_msg_btn.jpg" /></a>
			  	<a href="javascript:selectDianxin()"><img id="dx_head" src="http://assets.9aola.com/baitianpay/images/site/dx_msg_btn_active.jpg" /></a>
			  </div>
              <div class="main_content_desc">
                <div class="desc_content" style="top:5px;">
					<div id="yidong_mobile">
						<div id="bindMobile">
							 <div class="new_yd">                        
                              <p>你选择了<b class="p_red">中国移动短信充值</b>方式</p>
                              <p>第一步：手机号码绑定</p>
                              <div class="cz_box">
                                 <table id="bindTable" style="width:480px; height:80px">
                          <tr >
                                <td style="text-align:right; width:80px">多多号:</td>
                                <td style="text-align:left; width:125px"><input name="Account" type="text" class="textbox moble_haoma" id="Account" disabled="disabled" /></td>
                                <td><div><span class="grayText">多多号就是登录游戏的帐号哦</span></td>
                              </tr>
                          <tr>
                                <td style="text-align:right; width:80px">手机号:</td>
                                <td style="text-align:left; width:125px"><input type="text" class="textbox moble_haoma" name="MobileNo" id="mobileNum" maxlength="11"/></td>
                              	<td><span class="grayText" id="mobile_tip">11位移动手机号</span><span class="p_red" id="bind_error"></span></td>
                              </tr>
                          <tr>
                                <td colspan="3" style="text-align:center"><input type="button" class="input_2" /></td>
                              </tr>
                        </table>
                              </div>
                              <div class="xuzhi" style="zoom:1;overflow:auto;">
                                <p>须知：</p>
                                <ul>
                                  <li>1、一个多多号最多绑定2个手机号码，绑定成功后，只能使用已绑定的手机号码完成充<br />&nbsp;&nbsp;&nbsp;&nbsp;值，请在家长的指导下完成以下步骤。</li>
                                  <li>2、用户不能更换已绑定的手机号码，如果需要更换手机号码，请联系客服提出申请，<br />&nbsp;&nbsp;&nbsp;&nbsp;审核通过后才可以更换。客服电话020-83995251</li>
                                </ul>
                              </div>
                            </div>
                        	
                        	</div>
                        	  <div class="now_cz">
                          <p>你选择了<b class="p_red">中国移动短信充值</b>方式</p>
                          <form>
                            <table border="0" style="width:490px;">
                              <tr>
                                <td width="158" align="right">多多号：</td>
                                <td width="320"><input type="text" id="DuoduoId" class="inp_t" disabled='disabled'/></td>
                              </tr>
                              <tr>
                                <td align="right">请输入手机号码：</td>
                                <td>
                                	<input type="text" class="textbox moble_haoma" id="UserMobileNo" maxlength="11"/>
                                	   <input type="button" value="新增手机号" disable="disabled" id="addMobile"></input> <br />
                                </td>
                              </tr>
                              <tr>
                                <td align="right">奥币金额：</td>
                                <td>
                                  <select id="GoodsId">
                                    <option value="150" selected="selected">10奥币</option>
                                  </select>
                                </td>
                              </tr>
                              <tr>
                                <td colspan="2"><input type="button" class="input_6" value="&nbsp;" /></td>
                              </tr>
                            </table>
                            <input type="hidden" name="GameId" id="GameId" value="2"/> 
                          </form>
                          <p>充值须知：</p>
                          <span class="t_24">1、资费标准：15元/次，即成功充值10个奥币扣话费15元；</span>
                          <span class="t_24">2、一个手机号码每月只能充值4次；</span>
                          <span class="t_24">3、请在家长指导下使用手机充值。</span>
                        </div>
                        <div class="cz_true">
                          <p class="p_red">请编写以下验证码：</p>
                          <p class="fs"><img id="ValidateCode" height="40" width="200" src="#"/></p>
                          通过手机短信发送到指定号码<b class="p_red">1065800885761</b>，然后根据短信回复提示操作。
                        </div>
                        <!--改版充值 end-->
					</div>
						</div>
					<div id="dianxin_mobile">
						<br/>&nbsp;&nbsp;你选择了<strong class="red_text">中国电信手机短信购卡</strong>方式。<br/>
						&nbsp;&nbsp;购卡须知:<br/>
						<p>1、资费标准：15元/次，即成功购买一张多多卡，扣话费15元；</p>
						<p>2、一个手机号码当天最多扣费50元（3张），一个月最多扣费120元（8张）；</p>
						<p>3、获得多多卡卡号密码后，请尽快登陆奥拉星，选择多多卡开通方式充值蓝宝石或者奥币，防止卡密泄露。</p>
						<div id="buy_btn"><a href="http://km.5151pay.com/hd/BTKM/index.html" target="_blank"><img src="http://assets.9aola.com/baitianpay/images/buy.jpg"/></a></div>
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

<div id="block"></div>

<div class="cz_first" id="c_one">
  <div class="dialog_top"><span style="position: relative; top: 30px; left: -120px;"><img src="http://assets.9aola.com/baitianpay/images/site/confirm_desc.jpg"/></span></div>
  <div class="dialog_cen">
    <div class="pelev">
      <table width="100%" border="1" cellspacing="0" cellpadding="0">
      	<tr>
      		<td style="text-align:right;">绑定的多多号：</td>
      		<td style="text-align:left; width:300px; _width:200px;"><span id="bindAccount" ></span></td>
      	</tr>
      	<tr>
      		<td style="text-align:right;">绑定的手机号：</td>
      		<td style="text-align:left; width:300px; _width:200px;"><span id="checkMobileNo"></span></td>
      	</tr>
      	<tr>
      		<td colspan="2"><font color="#cc3300">再次核对你的绑定信息，确认无误后请点击“确定”，信息有误请选择“取消”</font></td>
      	</tr>
      	<tr>
      		<td colspan="2"> <input type="button" class="input_4" /> &nbsp;&nbsp;&nbsp;&nbsp;
     						 <input type="button" class="input_5" />
     						 </td>
      	</tr>
      </table>
      <!--  <p>你需要绑定的手机号码是：<span id="checkMobileNo" style="color:red"></span><br />请再次确认手机号码是否正确！</p> -->
    </div>
  </div>    
  <div class="dialog_btm"></div>
</div>
<div class="cz_first cz_two" id="c_two">
<div class="dialog_top"><span style="position: relative; top: 30px; left: -120px;"><img src="http://assets.9aola.com/baitianpay/images/site/bind_success.jpg"/></span></div>
  <div class="dialog_cen">
    <div class="pelev">
      <table width="100%" border="1" cellspacing="0" cellpadding="0">
      	<tr height="130px">
      		<td><font size="3px">你还可以绑定一个手机号，现在需要绑定吗？</font><br/>
      			<font color="#cc3300">如果需要，请点击“绑定”，如果不需要，请点击“跳过”</font>
      		</td>
      	</tr>
      	<tr>
      		<td> <input type="button" class="input_4" /> &nbsp;&nbsp;&nbsp;&nbsp;
     						 <input type="button" class="input_5" />
     		</td>
      	</tr>
      </table>
    </div>
  </div>    
  <div class="dialog_btm"></div>
  <!--  <div class="topbg"></div>
  <div class="mdbg">
    <div class="pelev">
      <p>绑定成功，你还可以再绑定一个手机号码，现在需要绑定吗？</p>
      <input type="button" class="input_4" />
      <input type="button" class="input_5" />
    </div>
  </div>
  <div class="bottombg"></div>-->    
</div>
<div class="cz_first cz_three "  id="c_three">
  <div class="dialog_top"></div>
  <div class="dialog_cen">
    <div class="pelev">
      <table width="100%" border="1" cellspacing="0" cellpadding="0">
      	<tr height="130px">
      		<td><div id="go_topup">你现在可以使用手机号：<span id="bindSuccessMobile" style="color:red;"></span><br/>完成以下充值！<br/>
      		</td>
      	</tr>
      	<tr>
      		<td> <input type="button" class="input_4" /></td>
      	</tr>
      </table>
    </div>
  </div>    
  <div class="dialog_btm"></div>
  <!-- <div class="topbg"></div>
  <div class="mdbg">
    <div class="pelev">
     
      <div id="go_topup">你现在可以使用手机号：<span id="bindSuccessMobile"></span><br/>完成以下充值！<br/></div>
      <input type="button" class="input_4" />
    </div>
  </div>
  <div class="bottombg"></div>   -->     
</div>
<div class="suoping" style="display:none"></div>
</body>
</html>