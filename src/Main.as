package {

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.external.ExternalInterface;
import flash.utils.getTimer;
import flash.utils.setTimeout;

[SWF(width="50", height="50", backgroundColor="#00ff00", frameRate="30")]
public class Main extends Sprite {
	private var conn:ConnBridge;
	private var hasEI:Boolean;

	public function Main() {
		stage.showDefaultContextMenu = false;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		trace( "testing LC" );
//		testLC();
		init();
	}

//	var lc:LocalConnection;

	/*private function testLC():void {
	 Security.allowDomain( "*" );
	 Security.allowInsecureDomain( "*" );
	 trace( "sandbox", Security.sandboxType );
	 trace( "testing LC, send messages each 5 seconds." );
	 setTimeout( Security.showSettings, 2000 );
	 lc = new LocalConnection();
	 lc.addEventListener( StatusEvent.STATUS, trace );
	 lc.allowDomain( "*" );
	 //		lc.allowDomain("app#com.sn.TestApp") ;
	 lc.allowInsecureDomain( "*" );
	 lc.client = {
	 pepe: function ( val:String ) {
	 trace( "recive val", val );
	 }
	 };
	 lc.connect( "_coco" );
	 //		sndLoopMsg();
	 }*/

	private function sndLoopMsg():void {
//		lc.send( "app#com.sn.TestApp:magical_connection", "message", 1 );
//		lc.send("app#Growler:magical_connection", "message", msg);
		trace( "send()", "magical_connection", "message", 1 );
//		lc.send( "magical_connection", "message", 1 );
		setTimeout( sndLoopMsg, 5000 );
	}

	private function init():void {
		hasEI = ExternalInterface.available;
		trace( "as3 inited." );
		trace( "ExtInt availalbe:", hasEI );
		conn = new ConnBridge( ConnBridge.ID_SWF, ConnBridge.ID_AIR, this );
		//		conn.sendPrefix = "localhost:";
		//		conn.reciever_lc.allowDomain("app#com.sn.TestApp");
		conn.callbackName = "onSignal";
//		conn.recieverOnly = false;
//		conn.connect();
		if ( hasEI ) {
			checkReadyState();
		}
	}

	private var _ping_ts:uint;

	private function pingBridge():void {
		_ping_ts = getTimer();
		conn.send( "_pingRequest" );
	}

	public function onSignal( signal:String, obj:Object ):void {
		if ( !signal ) {
			trace( "recieved empty onSignal()?", signal );
			return;
		}
		trace( "recieved signal::", signal );
		if ( obj ) trace( "recieved obj::", JSON.stringify( obj ) );
		switch ( signal ) {
			// PING stuff
			case "close":
				trace( "LC closing conn" );
				conn.close();
				break;
			case "_pingRequest":
				conn.send( "_pingResponse" );
				break;
			case "_pingResponse":
				var t:uint = getTimer() - _ping_ts;
				trace( "PING ok, lag=" + t + "ms" );
				break;
			case "ping_me":
				if ( !obj ) obj = {dly: 1};
				if ( !obj.dly ) obj.dly = 1;
				trace( "ping in ", obj.dly + "secs" );
				setTimeout( pingBridge, obj.dly * 1000 );
				break;

			case "js_hi":
				if ( !hasEI ) {
					conn.send( "error", {msg: "ExternalInterface not available"} );
					return;
				}
				ExternalInterface.call( "as2js_alert", 'hi from as3!' );
				break;
			case "call_js":
				if ( !hasEI ) {
					conn.send( "error", {msg: "ExternalInterface not available"} );
				}
				if ( !obj.method ) {
					// callback error back.
					conn.send( "error", {msg: "js requires obj.method (and optionally obj.args)"} );
					return;
				}
				var params:Array = [obj.method];
				if ( obj.args ) params = params.concat( obj.args );
				ExternalInterface.call.apply( null, params );
				break;

			case "get_date":
				conn.send( "info", {msg: "current date is::" + new Date()} );
				break;
		}

	}

	private function checkReadyState():void {
		ExternalInterface.addCallback( "js2as_action", onJSAction );
		var ready:Boolean = ExternalInterface.call( "as2js_onSWFLoaded" );
		if ( !ready ) {
			trace( "swf not ready" );
			setTimeout( checkReadyState, 50 );
		} else {
			trace( "swf ready!!!" );
			initJS();
		}
	}

	var _initedJS:Boolean = false;

	private function initJS():void {
		// notify app that's loaded.
		trace( "abount to send js_inited" );
		conn.send( "js_inited" );
		_initedJS = true;
		trace( "sent js_inited" );
		//	http://localhost:8888/KaonCityscape/
	}

	function onJSAction( obj:Object ) {
		if ( obj ) {
			trace( "JS calleD:::", JSON.stringify( obj ) );
		} else {
			trace( "JS called no args." );
		}
		conn.send( "js_action", obj );
		if ( obj && obj.action == "nav" ) {
			conn.close();
		}
	}

}
}
