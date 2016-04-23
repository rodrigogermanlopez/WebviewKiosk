package {

import com.demonsters.debugger.MonsterDebugger;

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
		MonsterDebugger.enabled = true;
		MonsterDebugger.initialize( this );
		MonsterDebugger.log( "hello.." );
		stage.showDefaultContextMenu = false;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
//		testLC();
		init();
		log( "testing LC" );
	}

//	var lc:LocalConnection;

	/*private function testLC():void {
	 Security.allowDomain( "*" );
	 Security.allowInsecureDomain( "*" );
	 log( "sandbox", Security.sandboxType );
	 log( "testing LC, send messages each 5 seconds." );
	 setTimeout( Security.showSettings, 2000 );
	 lc = new LocalConnection();
	 lc.addEventListener( StatusEvent.STATUS, trace );
	 lc.allowDomain( "*" );
	 //		lc.allowDomain("app#com.sn.TestApp") ;
	 lc.allowInsecureDomain( "*" );
	 lc.client = {
	 pepe: function ( val:String ) {
	 log( "recive val", val );
	 }
	 };
	 lc.connect( "_coco" );
	 //		sndLoopMsg();
	 }*/

	private function sndLoopMsg():void {
//		lc.send( "app#com.sn.TestApp:magical_connection", "message", 1 );
//		lc.send("app#Growler:magical_connection", "message", msg);
		log( "send()", "magical_connection", "message", 1 );
//		lc.send( "magical_connection", "message", 1 );
		setTimeout( sndLoopMsg, 5000 );
	}

	private function init():void {
		hasEI = ExternalInterface.available;
		log( "as3 inited." );
		log( "ExtInt availalbe:", hasEI );
		conn = new ConnBridge( ConnBridge.ID_SWF, ConnBridge.ID_AIR, this );
		//		conn.sendPrefix = "localhost:";
		//		conn.reciever_lc.allowDomain("app#com.sn.TestApp");
		conn.callbackName = "onSignal";
		conn.tracer = log;

		// maybe it was previously connected.
		conn.send( "_handshake" );

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
		conn.recieverWorks();
		if ( !signal ) {
			log( "recieved empty onSignal()?", signal );
			return;
		}
		log( "recieved signal::", signal );
		if ( obj ) log( "recieved obj::", JSON.stringify( obj ) );
		switch ( signal ) {
			// PING stuff
			case "_handshake":
				conn.recieverWorks();
				break;
			case "close":
				log( "LC closing conn" );
				conn.close();
				break;
			case "_pingRequest":
				conn.send( "_pingResponse" );
				break;
			case "_pingResponse":
				var t:uint = getTimer() - _ping_ts;
				log( "PING ok, lag=" + t + "ms" );
				break;
			case "ping_me":
				if ( !obj ) obj = {dly: 1};
				if ( !obj.dly ) obj.dly = 1;
				log( "ping in ", obj.dly + "secs" );
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
		ExternalInterface.addCallback( "js2as_unload", onUnload );
		var ready:Boolean = ExternalInterface.call( "as2js_onSWFLoaded" );
		if ( !ready ) {
			log( "swf not ready" );
			setTimeout( checkReadyState, 50 );
		} else {
			log( "swf ready!!!" );
			initJS();
		}
	}

	private function onUnload():void {
		log( "UNLOADING BROWSER." );
		conn.close();
	}

	var _initedJS:Boolean = false;

	private function initJS():void {
		// notify app that's loaded.
		log( "abount to send js_inited" );
		conn.send( "js_inited" );
		_initedJS = true;
		log( "sent js_inited" );
		//	http://localhost:8888/KaonCityscape/
	}

	function onJSAction( obj:Object ) {
		if ( obj ) {
			log( "JS calleD:::", JSON.stringify( obj ) );
		} else {
			log( "JS called no args." );
		}
		conn.send( "js_action", obj );
		if ( obj && obj.action == "nav" ) {
			log( "LC closing conn" );
			conn.close();
		}
	}


	public function log( ...args ) {
		trace( "loggin:", args );
//		var o:String = args.join( ";" );
//		MonsterDebugger.trace( this, o, "Main", "lbl" );
		MonsterDebugger.log.apply( this, args );
	}

}
}
