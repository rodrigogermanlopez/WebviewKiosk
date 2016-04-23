/**
 * Code by Rodrigo López Peker (grar) on 4/22/16 9:13 PM.
 *
 */
package {

import com.furusystems.logging.slf4as.Logging;

import flash.events.Event;

import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ServerSocketConnectEvent;
import flash.net.ServerSocket;
import flash.net.Socket;
import flash.utils.setTimeout;

public class TestAppServerCode {
	private static var _instance:TestAppServerCode;
	public static function get instance():TestAppServerCode {
		if ( !_instance ) _instance = new TestAppServerCode();
		return _instance;
	}

	public function TestAppServerCode() {
	}

	public function init() {
		createCmd( [
		 "connect",
		 "socketConnect"
		 ], connectSocket, "creates a TCP socket connection in $host(localhost):$port; connect|socketConnect port(int) ?host(string)", "CLIENT" );
		 createCmd( [
		 "close",
		 "socketClose"
		 ], closeSocket, "closes the current connected socket; close | socketClose", "CLIENT" );
		 createCmd( [
		 "send",
		 "socketSend"
		 ], socketSendMessage, "sends a utf message to the server; send | socketSend [\"message\"]", "CLIENT" );
		 createCmd( [
		 "serverStart",
		 "start"
		 ], startServer, "creates a socket server $port ?host(localhost); start|startServer port(int) ?host(string)", "SERVER" );
		 createCmd( ["stop", "serverStop"], stopServer, "kills the running server", "SERVER" );
		 createCmd( [
		 "brodcast",
		 "serverMessage"
		 ], sendServerMessage, "server sends a message to all connected clients.; brodcast msg(str)", "SERVER" );
		 createCmd( "serverInfo", serverInfo, "shows if there's a server currently running and the clients connected to it", "SERVER" );
		 createCmd( "serverDispose", disposeServer, "dispose the current server removing all clients references as well", "SERVER" );
	}
	private function disposeServer():void {
		if ( !server ) {
			info( "server > No socket server to dispose." );
			return;
		}
		disposeClients();
		info( "server > closing and disposing socket server..." );
		server.close();
		server.removeEventListener( ServerSocketConnectEvent.CONNECT, onClientConnected );
		server = null;
		setTimeout( function () {
			info( "server > disposed." );
		}, 500 );
	}

	private function disposeClients():void {
		for each( var client:Socket in clients ) {
			info( "server > disposing connected client " );
			if ( client.connected ) {
				client.writeUTFBytes( "server_die" );
				client.flush();
			}
			removeClient( client );
		}
		clients = [];
	}

	private function serverInfo():void {
		if ( !server ) {
			error( "server > There's no SocketServer currently running. Use command startServer" );
		} else {
			info( "server > Server is listening? " + server.listening );
			info( "server > Server info " + server.localAddress + ":" + server.localPort );
			var list:Array = getCurrentClients();
//			var clientList_str:String = "" ;
			// create a list
			info( "server > clients connected " + list.length );
		}
	}

	public function sendServerMessage( msg:String ):void {
		info( "server > ... sending messages to all clients." );
		for each( var s:Socket in clients ) {
			if ( s && s.connected ) {
				s.writeUTFBytes( msg );
				s.flush();
			}
		}
	}

	private function getCurrentClients():Array {
		var out:Array = [];
		for each( var s:Socket in clients ) {
			if ( s.connected ) {
				out.push( s );
			}
		}
		return out;
	}

	private var clients:Array = [];

	// stores a reference to the last connected client.
	private var lastClient:Socket;

	private function stopServer():void {
		if ( !server ) {
			error( "server > There's no SocketServer running. Use command startServer" );
		} else {
			if ( !server.listening ) {
				info( "server > already stopped." );
			} else {
				server.close();
				info( "server > stopped" );
			}
		}
	}

	private function startServer( port:int = 0, host:String = "127.0.0.1" ):void {
		if ( server && server.bound ) {
			error( "server > dispose server before trying to create another one. Use command serverDispose" );
			return;
		}
		if ( port <= 0 ) {
			error( "server > please, pass a valid port to start the server." );
			return;
		}
		server = new ServerSocket();
		server.bind( port, host );
		// the CONNECT event is dispatched after a client connects
		// to the socket, make sure we handle it
		server.addEventListener( ServerSocketConnectEvent.CONNECT, onClientConnected );
		// start listening for connections
		server.listen();
		info( "server > server started at " + host + ":" + port );
	}

	private function removeClient( client:Socket ):void {
		var idx:int = clients.indexOf( client );
		client.removeEventListener( Event.CLOSE, onClientDisconnected );
		client.removeEventListener( ProgressEvent.SOCKET_DATA, onClientData );
		if ( idx > -1 ) {
			clients.removeAt( idx );
			debug( "server > removing client ", client );
		}
	}

	private function onClientDisconnected( event:Event ):void {
		var client:Socket = event.target as Socket;
//		client.addEventListener(ProgressEvent.SOCKET_DATA, onData);}
		removeClient( client );
	}

	private function onClientConnected( event:ServerSocketConnectEvent ):void {
		lastClient = event.socket;
		if ( clients.indexOf( lastClient ) == -1 ) {
			clients.push( lastClient );
		}
		lastClient.addEventListener( ProgressEvent.SOCKET_DATA, onClientData, false, 0, true );
		lastClient.addEventListener( Event.CLOSE, onClientDisconnected, false, 0, true );
//		info( "server > client connected:" + event.socket.localAddress + ":" + event.socket.localPort );
		info( "server > client connected:" + event.socket );
		// send a message to the client.
		event.socket.writeUTFBytes( "Hi client, Im the server\n" );
		event.socket.flush();
	}

	private function onClientData( event:ProgressEvent ):void {
		var client:Socket = event.target as Socket;
		if ( client.bytesAvailable ) {
			var msg:String = client.readUTFBytes( client.bytesAvailable );
			info( "server > client data: '" + msg + "'" );
		} else {
			info( "server > client data empty" );
		}
	}

	//===================================================================================================================================================
	//
	//      ------  socket stuffs
	//
	//===================================================================================================================================================

	private var server:ServerSocket;
	private var socket:Socket;

	public function closeSocket():void {
		if ( !socket ) {
			error( "No sockets availble" );
			return;
		}
		if ( !socket.connected ) {
			info( "Socket is currently NOT connected." );
			return;
		}
		socket.close();
		info( "...closing the socket" );
		// force the close, if the server doesnt close the session.
		setTimeout( onSocketClose, 500, null );
	}

	public function connectSocket( port:int = 0, host:String = "127.0.0.1" ):void {
		if ( port <= 0 ) {
			error( "client > socketConnect requires a valid [port](Int) ?host(String)" );
			return;
		}
		if ( socket && socket.localPort == port && socket.connected ) {
			info( "client > socket already connected" );
			return;
		}
		socket = new Socket();
		socket.addEventListener( Event.CONNECT, onSocketConnect, false, 0, true );
		socket.addEventListener( Event.CLOSE, onSocketClose, false, 0, true );
		socket.addEventListener( IOErrorEvent.IO_ERROR, onSocketError, false, 0, true );
		socket.addEventListener( ProgressEvent.SOCKET_DATA, onServerData, false, 0, true );
		socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, trace, false, 0, true );
		try {
			socket.connect( host, port );
		} catch ( e:Error ) {
			// there's an error on connection, dispose the socket
			fatal( "client > Socket connect() error = " + e.message + "\n" );
			socket.close();
			disposeSocket();
		}
		info( "creating a new socket connection on " + host + ":" + port );
	}

	private function onServerData( event:ProgressEvent ):void {
		var read:String = socket.readUTFBytes( socket.bytesAvailable );
		// in a real world scenario, we have to analyze the data
		// to make sense out of it.
		info( "client > Server data recieved=", read );
	}

	private function onSocketError( event:IOErrorEvent ):void {
		error( "client > Socket Error=" + event.toString() );
		error( "client > ... disposing socket." );
		if ( socket.connected )
			socket.close();
		setTimeout( onSocketClose, 500, null );
//		disposeSocket() ;
	}

	private function onSocketClose( event:Event ):void {
		debug( "client > Socket closed." );
		disposeSocket();
	}

	private function onSocketConnect( event:Event ):void {
		info( "client > Socket connected!\nYou can send a message now: [ send|socketSend \"hiserver\" ]" );
//		socketSendMessage( "hiserver" ) ;
	}

	private function socketSendMessage( message:String = "" ):void {
		if ( !message ) {
			error( "client > socketSend requires an argument with the message" );
			return;
		}
		// Check if Dennis' server requires an EOF key or something at the end of the string
		// to dinstinguish the packets. (like charCode(0) NULL.
		if ( !socket || !socket.connected ) {
			error( "client > socketSendMessage() requires an existent/connected socket.\nUse connect|socketConnect to create a new connection." );
			return;
		}
		socket.writeUTFBytes( message );
		socket.flush();
	}

	private function disposeSocket():void {
		// leave the socket for GC...
		if ( !socket ) return;
		socket.removeEventListener( Event.CONNECT, onSocketConnect );
		socket.removeEventListener( Event.CLOSE, onSocketClose );
		socket.removeEventListener( IOErrorEvent.IO_ERROR, onSocketError );
		socket.removeEventListener( ProgressEvent.SOCKET_DATA, onServerData );
		socket.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, trace );
		socket = null;
	}

	public function createCmd( exec:*, fun:Function, description:String, group:String = "APP" ):void {
		TestApp.createCmd(exec, fun, description, group) ;
	}

	// --- LOG methods for the console.
	private function warn( ...args ):void {
		Logging.root.warn.apply( this, args );
	}

	private function fatal( ...args ):void {
		Logging.root.fatal.apply( this, args );
	}

	private function error( ...args ):void {
		Logging.root.error.apply( this, args );
	}

	private function debug( ...args ):void {
		Logging.root.debug.apply( this, args );
	}

	private function info( ...args ):void {
		Logging.root.info.apply( this, args );
	}
}
}
