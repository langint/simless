// Listeners

MONITORING_RATE = 3000;
graph_mode = 'static';
rt_graph = false;
// INITIATION  ////////

////////////////////////////////

function launchListeners(){
	$("#save_settings").click(function(){ updateModeSettings()	}); // Save Settings listener
	
	$("li[name='modes']").click(function(event){	// Sim Mode listener				
		var mode = $(event.target).html().toLowerCase();
		location.href = "/simulation?ops=change_mode&mode=" + mode; 
	});
	
	$("button[name='start']").click(function(event){  //Start/Stop Sim listener
		var action = $(event.target).html().toLowerCase() ;
		if(action == "start"){
			$(event.target).html("Stop");
			startSim();
		}else{
			$(event.target).html("Start");  //Stop button pressed
			$.get("/simulation/stop");
			rt_graph = false;
			setTimeout(function(){$("#clients_online").html(0);}, MONITORING_RATE);
		}
	});

	$("li[name='graph_mode']").click( function(event){ 
		graph_mode = $(event.target).html().toLowerCase();
	});
	$("input[name='slider']").on("slideStop", function(slideEvt) { 
		slideEvt.stopImmediatePropagation();
		v = slideEvt;
		var slider = $(v.currentTarget).attr('id');
		$.ajax({ url: "/simulation/" + slider + "?value=" + v.value, method: "PUT" });
	});

	
	$("button[name='con']").on('click', function(event){
		event.stopImmediatePropagation();
		changeConnections(event)});
	
	$("button[name='testcon']").on('click', function(event){
		event.stopImmediatePropagation();
		changeConnections(event)});

	$("input[type='checkbox'][name='active']").on('click', function(event){
		event.stopImmediatePropagation;
		$.each($("input[type='checkbox'][name='active']"), function (ind, val) { $(val).prop('checked', false); });
		$(this).prop('checked', true);
	});


	$("button[name='intercept']").on('click', function(event){
		startIntercept();});

	$(".server-status").click( function(event){ serverStatus(event); });
	monitorServers();
//	setInterval(function(){ monitorServers() }, 2000);
}

function startSim(){
	$("#visualization").html("");
	var obj = new Object;
	var token = $('#token').html();
	$("#dataset").data("sample", {timestamp: vis.moment(), count: 0, failures: 0, traffic: 0, clients: 0, token: token, heartbeats: 0});
	var settings = collectSettings();
	realTimeGraph(settings);
	$("#loader").show();

	$.get("/simulation/start").success( function(data){
		if(typeof(data.failures) == "undefined"){
			$("#visualization").html("<h2>Connection to GWA server failed</h2>");
			return;
		}else{
			$("#visualization").html("");
			$("#loader").hide();
			$('#dataset').data("sample", data);
			rt_graph = true;
			simMonitor(settings);
			realTimeGraph(settings);
		}
	}).fail(function(data){
		$("#loader").hide();
		$.get("/simulation/stop"); 
		online = true;
		$("#visualization").html("<h2>GWA server returned error code " + data.status + "</h2>");
	});

}

function monitorServers(){
	$.get("/text911/" + 1).complete( function(res){
	 	networkData(res);
	 });
}

function networkData(obj){
	 if(obj.status == '200'){
		var nodes = new Array;
		var data = JSON.parse(obj.responseText)
			$.each(data, function(key, value) {
				console.log(value.id) 
				nodes.push({id: value.id, psap: value.psap_id, color: 'orange'});
			} 
				)
	 			$("#network").val(obj.responseText);
	 	}
console.log(nodes);

}
function serverStatus(event){
	event.stopImmediatePropagation();
	var s = $(event.target).html();
	var num = s.charAt(s.length - 1);
	$.get("/text911/" + num).done( function(data){
		console.log(data.status);
		var color = $.isEmptyObject(data) ? 'red' : 'green';
		$(event.target).css('background-color', color);
	});
}

function whoIsOnline(num){
	var response =  $.get("/text911/" + num).complete( function(data){return data;});
	return response;
}

function collectSettings(){  // Collecting readings from all sliders
	var obj = new Object; 
	$.each( $("input[name='slider']"), function(ind, v){
		var value = $(v).val().length == 0 ? $(v).attr('data-slider-min') : $(v).val();
		obj[$(v).attr('id')] =  value; 
	});
	return obj;	
}

function simMonitor(settings){  	// This function monitors the database and stores data in the #dataset div
	var token = $('#dataset').data('sample').token;
	$.get("/simulation/monitor?token=" + token + "&pool_size=" + settings.pool_size).done( function(data){
		$("#dataset").data("sample", data);
			console.log(data);
		$("#clients_online").html(data.clients_online);
		$("#failures").html(data.failures);
		var max_res_time = data.max_response_time ? data.max_response_time : '&nbsp;'
		$("#max_res_time").html(data.max_response_time);
		$("#failures").parent().css('color', '#777');
		if(data.failures > 0){
			$("#failures").css('color', 'red');
		}else{
			$("#failures").css('color', '#777');
		}
		if(rt_graph){ setTimeout(function(){ simMonitor(settings)}, MONITORING_RATE); }	
	}).fail(function(){
			$("#failures").html("500").css('font-weight', 'bold').parent().css('color', 'red');
			if(rt_graph){ setTimeout(function(){ simMonitor(settings)}, MONITORING_RATE); }	
		}
	);
}

function align_inputs(form){
	var titles = $(form).find("div[name='input_title']");
	var sizes = [];
	$.each(titles, function(ind, t){ sizes.push($(t).width()) });
	var max_width = Math.max(...sizes);
	$.each(titles, function(ind, t){ $(t).css('width', max_width).css('text-align','left') });
}

function validateInputs(form){
	$.each(form.find("input"), function(ind, v){
		var value = $(v).val();
		if( !isNaN(value)  ){ 
			alert("Wrong value entered ");
			return; 
			}
		});
}

// *** REAL-TIME GRAPHICS **************
function realTimeGraph(settings){   // create a graph2d with a (currently empty) dataset
	var container = document.getElementById('visualization');
	var dataset = new vis.DataSet();
	
	var groups = new vis.DataSet();
    groups.add({ id: 0, content: 'traffic, calls/sec', options: { drawPoints: true
    	//    	dataAxis: {left:{ range:{ min:0,} }}  
	    } });
    groups.add({ id: 1,content: 'response time, msec', 
    	options: {yAxisOrientation: 'right'},
	   	dataAxis: {right: { range: {min:0}} }  	    	
	});
  //  groups.add({ id: 2, content: 'failures', options: {drawPoints: true} });

	var options = {
	    width: '100%',
	    height: '400px',
	    legend: {left:{position:"bottom-left"}},
	    start: vis.moment().add(-30, 'seconds'), // changed so its faster
	    end: vis.moment(),
	    drawPoints: { style: 'circle' },// square, circle 
	    shaded: { orientation: 'bottom'     }// top, bottom
	};
	var graph2d = new vis.Graph2d(container, dataset, groups, options);	
	
	function renderStep() {
    	// move the window (you can think of different strategies)
    	var now = vis.moment();
    	var range = graph2d.getWindow();
    	var interval = range.end - range.start;
	    switch (graph_mode) {
	      case 'continuous':
	        // continuously move the window
	    	if(rt_graph){ 
	    		graph2d.setWindow(now - interval, now, {animation: false});
	       		requestAnimationFrame(renderStep); 
	       	}else{
	       		return
	       	}
	        break;

	      case 'discrete':
	        if(rt_graph){ 
	        	graph2d.setWindow(now - interval, now, {animation: false});
	        	setTimeout(renderStep, MONITORING_RATE); 
	    	}else{
	    		return
	    	}
	        break;

	      default: // 'static'
	        // move the window 90% to the left when now is larger than the end of the window
		    if(rt_graph){  
		        if (now > range.end) {
		        	graph2d.setWindow(now - 0.1 * interval, now + 0.9 * interval);
		        }
		        	setTimeout(function(){renderStep();}, MONITORING_RATE);
		    }else{ 
		    	return 
		    }
	        break;
	    }
  	}
	
	function addSample() { // Add options new sample to the graph
	    var sample = $("#dataset").data('sample');
		failures = sample.failures ? sample.failures : 0;
		clients = typeof(sample.threads) == 'undefined' ? 0 : sample.clients_online;
		var now = vis.moment(); // add a new data point to the dataset
	    var res_time = sample.response_time > 0 ? sample.response_time : 0;
	    var traffic = sample.traffic > 0 ? sample.traffic : 0 ;
	    dataset.add(
	    [	{x: now, y: traffic, group: 0},
	    	{x: now, y: res_time, group: 1}
	    ]
	    );
    // remove all data points which are no longer visible
		var range = graph2d.getWindow();
		var interval = range.end - range.start;
		var oldIds = dataset.getIds({
	    	filter: function (item) { return item.x < range.start - interval; }
	    });
    	dataset.remove(oldIds);
    	if(rt_graph){
    		setTimeout(function(){addSample();}, MONITORING_RATE);
		}else{
			return
		}
	}

	// Initiation
	addSample();
	renderStep();

}


function startIntercept(){
	$.get("/simulation/start_interception", function(data){
		console.log(data);
	})
	setInterval( function(){refreshEvents()}, 3000)
}

function refreshEvents(){
	$.get("/simulation/refreshEvents", function(data){})

}