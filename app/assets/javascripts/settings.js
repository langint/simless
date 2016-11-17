
function launchListeners(){
	
	$("li[name='env']").click(function(event){
		event.stopImmediatePropagation	
		var id = $(event.target).parent().attr("id");	// Environment selected, open editing form
		$.get( "/simulation/stop" );
		$.get( "/settings/"+ id +"/edit" ).done(function(data){
			$("li[name='env").removeClass('active');
			$("#connections").html(data);
			$("li[name='env'][id= " + id + " ]").addClass('active');
			launchListeners();
		});
	});

	$("button[name='con']").on('click', function(event){
	event.stopImmediatePropagation();
	console.log('listener here');
	handleConnections(event)
	});

	$("div[name='panel-header']").click(function(event){  // Collapse/unfold Connections and API Messages
	$(event.target).siblings().first().toggle();
	$(event.target).find(".btn-group").toggle()
	})
}

function setMenu(event){
	var link = $(event.target).html().toLowerCase().split(" ").join("_");
	$("form").hide();
	console.log(link);
	switch(link){
		case 'front_end_connections':
			$("form[name='conn']").show();
			break;
		case 'back_end_connections':
			$("form[name='conn2']").show();
			break;
		case 'interface_messages':

			break;
	}
	launchListeners();
}

function handleConnections(event){
	var btn = $(event.target).html().toLowerCase();
	var inputs = $("tr[name='connection']").find("input");
	switch(btn){
		case 'unlock':
			$.each(inputs, function(ind, val){$(val).prop('disabled', false).prop('readonly', false)});
			$("button:contains('Save')" ).prop('disabled', false);
			$("button:contains('Cancel')" ).prop('disabled', false);
			$("button:contains('Test')" ).prop('disabled', true);
			break;
		case 'cancel':
			$.each(inputs, function(ind, val){$(val).attr('disabled', true).attr('readonly', true)});
			$("button:contains('Save')" ).prop('disabled', true);
			$("button:contains('Test')" ).prop('disabled', false);
			break;
		case 'test':
			$("#loader").show();
			$("#conn_test").hide();
			var conn_id = $(event.target).attr('conn_id');
			$.get("/settings/test?conn_id=" + conn_id + "&env=" + $("#env").val()).done(function(data){
				$("#loader").hide();
				$("#conn_test").html(data).show();
			});
			break;
		case 'save':
			var env_id = $("#env").val();
			var rows = $("form[name='conn'] tr[name='connection']");
			var inputs = $("form[name='conn'] input");
			var obj = new Object;
			$.each(rows, function(i, row){ 
				var set = obj[ $(row).attr('conn_id') ] = {};
				$.each( $(row).find("input"), function(j,k){ 
					if($(k).attr('type') == 'checkbox'){ 
						set[ $(k).attr('name') ] =  $(k).prop('checked')
					} else { 
						set[ $(k).attr('name') ] = $(k).val() 
					};
				});
			});
			$.ajax({
			    url: "/settings/" + $("#env").val(),
			    data: obj,
			    type: 'PATCH'
			}).done(function(data){
				$("button:contains('Test')" ).prop('disabled', false);;
			});
			break;
		case "select this environment":
			$.ajax({ 
				url: "/settings/" + $("#env").val() + "?mode=set_default",
				type: 'PATCH'
			});
	}
}