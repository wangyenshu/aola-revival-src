// JavaScript Document

//亚比展示
function arrowRight(){
	times = setTimeout(function(){
		$("#ybShow ul").animate({marginLeft:"-=114px"},150,function(){
			$(this).css({marginLeft:"0px"}).find("li:first").appendTo(this);
		});
	},150);
	$("#arrow_right")[document.all?"mouseup":"mousedown"](function(){
		clearTimeout(times);
	})
}
function arrowLeft(){
	times = setTimeout(function(){
		$("#ybShow ul").css({marginLeft:"-114px"}).find("li:last").prependTo($("#ybShow ul"));
		$("#ybShow ul").animate({marginLeft:"+=114px"},150);
	},150);
	$("#arrow_left")[document.all?"mouseup":"mousedown"](function(){
		clearTimeout(times);
	})
}
function arrowHover(){
	$("#arrow_left").hover(
		function(){
			$(this).attr("src","images/arrow_left_hover.gif");
		},
		function(){
			$(this).attr("src","images/arrow_left.jpg");
		}
	)
	$("#arrow_right").hover(
		function(){
			$(this).attr("src","images/arrow_right_hover.jpg");
		},
		function(){
			$(this).attr("src","images/arrow_right.jpg");
		}
	)
}
//切换
function tab(){
	$("#t02").click(function(){
		$("#tabBar").addClass("tab_bar2");
		$("#tab02").show();
		$("#tab01").hide();
		$("#span02").show();
		$("#span01").hide();
	})
	$("#t01").click(function(){
		$("#tabBar").removeClass("tab_bar2");
		$("#tab02").hide();
		$("#tab01").show();
		$("#span02").hide();
		$("#span01").show();
	})
}
//焦点图
function focusPic(focusId,picLiF,picLi,nuLi,cN){
	var i = 1;
	$(picLiF).show().siblings().hide();
	liLength = $(picLi).length;
	$(nuLi).hover(
		function(){
			var index = $(this).index();				 
			$(picLi).eq(index).fadeIn("slow").siblings().fadeOut("slow");
			$(nuLi).eq(index).addClass(cN).siblings().removeClass(cN);
			i = index + 1;
		},
		function(){
			$(picLi).stop(true,true);
			$(nuLi).stop(true,true)
		}
	)
	function setAuto(){autoRun = setInterval(autoPic,3000)};
	function clearAuto(){clearInterval(autoRun)};
	setAuto();		
	$(focusId).hover(
		function(){clearAuto()},
		function(){setAuto()}
	)
	function autoPic(){
		if(i < liLength){				 
			$(picLi).eq(i).fadeIn("slow").siblings().fadeOut("slow");
			$(nuLi).eq(i).addClass(cN).siblings().removeClass(cN);
			i++;
		}
		else{
			$(picLi).eq(0).fadeIn("slow").siblings().fadeOut("slow");
			$(nuLi).eq(0).addClass(cN).siblings().removeClass(cN);
			i = 1;
		}
	}
}

//调用flash
function flash(id,src,w,h){
	var flashStr = '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,45,0"	name="myFlash" width="'+w+'" height="'+h+'" id="myFlash"><param name="movie" value="'+src+'" /><param name="bgcolor" value="#FFFFFF" /><param name="scale" value="noborder" /><param name="wmode" value="transparent" /><embed src="'+src+'" name="myFlash" wmode="transparent" swliveconnect="true" width="'+w+'" height="'+h+'" quality="high"	pluginspage="http://www.macromedia.com/go/getflashplayer"	type="application/x-shockwave-flash" bgcolor="#FFFFFF" scale="noborder"></embed></object>';
	$("#" + id).html(flashStr);
}



$(function(){
	flash("nav","/nav.swf",760,62);
	$("#enter").html('<a href="http://www.9aola.com/" target="_blank"></a>')
})
