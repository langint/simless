
GWA_URL = "http://10.32.28.212:8080"
MENU_ITEMS = {'simulation' : '/simulation/dashboard', "user_interface" : GWA_URL}

$(document).ready(function(){ 
	$("input[name='slider'").slider();
	$.get("/simulation/stop"); // Kill threads generated in previous sessions if the page gets refreshed
	$("#landing").css('height', $( document ).height()-120);
	$("li[name='menu-item']").click( function(event){changeTab(event.target) } );
	launchListeners();
});


function changeTab(target){
	if($(target).html().length == 0){
		var tab = "settings";
	}else{
		var tab = $(target).html().toLowerCase().replace(" ", "_");
	}
	console.log('tab=' + tab);
	if( Object.keys(MENU_ITEMS).includes(tab) ){
		var ttab = MENU_ITEMS[tab];
	}else{ttab = "/" + tab};
	console.log(ttab);
	document.location.href = ttab;
	switch(tab){
		case 'simulation':
//			document.location.href = "/simulation/dashboard";
			break;
		case 'settings':
//			document.location.href = "/settings";
			break;
		case 'system_status':
//			document.location.href = "/system_status";
			break;
		default:
			$.get("/change_tab?tab=" + tab).done(function(data){ 
			$("#main").html(data);
			launch_listeners();});
	}
}