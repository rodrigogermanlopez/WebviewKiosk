/**
 * Code by Rodrigo López Peker (grar) on 4/22/16 9:28 PM.
 *
 */
package {
import flash.events.StatusEvent;
import flash.net.LocalConnection;
import flash.utils.setTimeout;

public class ConnBridge {

	public static const ID_SWF:String = "_swf";
//	public static const ID_AIR:String = "app#com.sn.TestApp:_myConn2";
	public static const ID_AIR:String = "_air";

	public var myId:String;
	public var otherId:String;

	public var listener:Object;
	public var callbackName:String = "onSignal"; // both "listener" needs to implement this method,

	public var sender_lc:LocalConnection;
	public var reciever_lc:LocalConnection;

	// can replace with log.
	public var tracer:Function = trace;
	public var sendPrefix:String;
	public var recieverOnly:Boolean = false;

	public function ConnBridge( myId:String, otherId:String, listener:Object, sendPrefix:String = "" ) {
		this.myId = myId;
		this.otherId = otherId;
		this.sendPrefix = sendPrefix;
		this.listener = listener;

		sender_lc = new LocalConnection();
		reciever_lc = new LocalConnection();

		sender_lc.allowDomain( "*" );
		reciever_lc.allowDomain( "*" );

		sender_lc.addEventListener( StatusEvent.STATUS, handleSenderStatus );
		reciever_lc.addEventListener( StatusEvent.STATUS, handleRecieverStatus );
		tracer( "ConnBridge:: connect myId=" + myId + " otherId=" + otherId );
		reciever_lc.client = listener;
		connect();
	}

	public function connect():void {
		/*if( myId.indexOf(":")>-1){
		 myId = "_myConn" ;
		 }*/

        
		trace( "connect()", myId );
		try {
			reciever_lc.connect( myId );
		} catch ( e ) {
			tracer( "ERROR CONNECTION::", e );
			close();
			tracer( "try reconnection in 3000" );
			setTimeout( connect, 3000 );
		}
	}

	public function send( signal:String, obj:Object = null ):void {
		if ( recieverOnly ) return;
		trace( "send()", sendPrefix + otherId, callbackName, signal, obj );
		sender_lc.send( sendPrefix + otherId, callbackName, signal, obj );
	}

	private function reconnect() {
		tracer( "trying to reconnect to:", otherId );
		reciever_lc.connect( myId );
	}

	private function handleRecieverStatus( event:StatusEvent ):void {
		tracer( "handleRecieverStatus()  ", event.code, event.level );
		if ( event.level == "error" ) {
			tracer( "I'm not connected, reconnect in 1000ms" );
			setTimeout( reconnect, 1000 );
		}
	}

	private function handleSenderStatus( event:StatusEvent ):void {
		if ( recieverOnly ) return;
//		tracer( "handleSenderStatus()::", event.code, event.level );
		if ( event.level == "error" ) {
			tracer( "client not connected apparently." );
		}
	}

	public function close():void {
		try { reciever_lc.close()} catch ( e:Error ) {trace( "LC close error", e )}
		try { sender_lc.close()} catch ( e:Error ) {trace( "LC close error", e )}
	}
}
}
