var socket, port;

	port = window.location.port
	socket = io.connect( "http://" + document.domain + ':' + port + '/' );
	socket.on('connect', function () {
		socket.on( 'refresh', function () {
			window.location.reload();
		} );
		socket.on( 'reconnect_failed', function() {
			console.log( 'Reconnected to anvil failed', 'error' );
		} );
	} );