package {

import com.furusystems.dconsole2.DConsole;
import com.furusystems.dconsole2.plugins.StatsOutputUtil;
import com.furusystems.logging.slf4as.Logging;

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.filesystem.File;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.utils.getTimer;
import flash.utils.setTimeout;

[SWF(width="800", height="600", backgroundColor="#FFFFFF", frameRate="60")]
public class TestApp extends Sprite {
//	private var bridge:LocalConnector;
	private var conn:ConnBridge;
	private var connected:Boolean;
	private var appDir:File;

	public function TestApp() {
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.addEventListener( Event.RESIZE, onStageResize );
		init();
	}

	private function init():void {
		// setup an error logger, just in case.
		addChild( DConsole.view );
		DConsole.registerPlugins( StatsOutputUtil );
		DConsole.show();
		DConsole.setMagicSequence( [] );
		DConsole.clear();


		// define base app
		appDir = File.applicationDirectory;
		if ( appDir.name == "bin" ) {
			appDir = new File( appDir.nativePath ).parent.resolvePath( "bin-assets" );
		}
		info( "app dir::", appDir.exists, " - ", appDir.nativePath );

		// -- map some commands.
		// type "cmd" to have an idea of what's available.
		// fs > toggles fullscren.
		// exit > quit the app
		// ... etc
		createCmd( ["exit", "quit"], exit, "quit the app; exit | quit" );
		createCmd( ["fs", "fullscreen"], toggleFullscreen, "toggles the fullscreen; fs | fullscreen" );
		createCmd( ["exec", "open"], openFile, "executes a file; open | exec \"filepath\"" );
		createCmd( "ping", pingBridge, "ping the other client." );
		createCmd( "send", sendBridge, "sed a message to the bridge." );
		createCmd( "cityscape", navurl, "opens cityscape on the browser." );
		createCmd( "close", closeConnection, "opens cityscape on the browser." );

		createCmd( "run", bat_run, "opens cityscape on the browser with batch." );
		createCmd( "killIE", bat_killIE, "kills ie program." );

//		testServer() ;
//		TestAppServerCode.instance.init() ;
		initLC();
	}

	public function bat_run() {
		var f:File = appDir.resolvePath( "win/run.lnk" );
		if ( f.exists ) {
			debug( "exec run" );
			f.openWithDefaultApplication();
		}
	}

	public function bat_focus() {
		var f:File = appDir.resolvePath( "win/focus.lnk" );
		if ( f.exists ) {
			debug( "exec focus" );
			f.openWithDefaultApplication();
		}
	}

	public function bat_killIE() {
		var f:File = appDir.resolvePath( "win/killie.lnk" );
		if ( f.exists ) {
			debug( "exec killIE" );
			f.openWithDefaultApplication();
		}
	}

	private function closeConnection():void {
		sendBridge( "close" );
		conn.close();
		debug( "closing local and remote connection " );
	}

	private function navurl():void {
		navigateToURL( new URLRequest( "http://localhost:8888/KaonCityscape/" ) );
	}

	private var _ping_ts:uint;

	private function pingBridge():void {
		_ping_ts = getTimer();
		conn.send( "_pingRequest" );
	}

	private function sendBridge( signal:String, info:Object = null ):void {
//		options::    call_js (method,args)
		if ( info is String && ( info.charAt( 0 ) == "[" || info.charAt( 0 ) == "{") ) {
			try {
				info = JSON.parse( String( info ) );
			} catch ( e ) {
			}
		}
		// js_hi
		// get_date
		conn.send( signal, info );
	}

	//===================================================================================================================================================
	//
	//      ------  local connection code.
	//
	//===================================================================================================================================================

	public function message( val:int ):void {
		debug( "message recieved::", val );
	}

	private function initLC():void {
		conn = new ConnBridge( ConnBridge.ID_AIR, ConnBridge.ID_SWF, this );
		conn.tracer = debug;
		conn.callbackName = "onSignal";
	}

	public function onSignal( signal:String, obj:Object ):void {
		if ( !signal ) {
			warn( "recieved empty onSignal()?" );
			return;
		}

		switch ( signal ) {
			case "_pingRequest":
				conn.send( "_pingResponse" );
				break;
			case "_pingResponse":
				var t:uint = getTimer() - _ping_ts;
				info( "PING ok, lag=" + t + "ms" );
				break;

			case "error":
				error( "error:", obj.msg );
				break;
			case "info":
				info( "info:", obj.msg );
				break;

			// key features.
			case "js_inited":
				info( "JS INITED! :) " );
				break;
			case "js_action":
				if ( obj && obj.action == "nav" ) {
//					bat_killIE();
					bat_focus();
				}
				// obj has action;id from JS side.
				info( "JS ACTION>>", JSON.stringify( obj ) );
				break;
		}
		debug( "--message recieved::", signal, JSON.stringify( obj ) );
		// call_js
	}

	//===================================================================================================================================================
	//
	//      ------  BASIC app execution
	//
	//===================================================================================================================================================

	public function openFile( appPath:String = "" ):void {
		if ( !appPath ) {
			error( "open requires a filepath as a parameter" );
			return;
		}
		if ( appPath.indexOf( File.separator ) == -1 ) {
			error( "open invalid filepath" );
			return;

		}

		var file:File = new File();
		file.nativePath = appPath;
		if ( !file.exists ) {
			error( "File '" + appPath + "' doesn't exists" );
			return;
		}
		info( "Executing program... " );
		setTimeout( function () {
			file.openWithDefaultApplication();
		}, 500 );
	}

	private function exit():void {
		debug( "Quitting app in 1 sec." );
		closeConnection();
		setTimeout( function () {
			NativeApplication.nativeApplication.exit();
		}, 1000 );
	}

	private function toggleFullscreen():void {
		if ( stage.displayState != StageDisplayState.NORMAL ) {
			stage.displayState = StageDisplayState.NORMAL;
			debug( "Normal screen mode" );
		} else {
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			debug( "Fullscreen mode" );
		}
	}

	private function onStageResize( event:Event ):void {
		debug( "Stage resize=" + stage.stageWidth + "x" + stage.stageHeight );
	}


	//===================================================================================================================================================
	//
	//      ------  UTILS
	//
	//===================================================================================================================================================

	// factory/utility to create several commands for the same callback.
	public static function createCmd( exec:*, fun:Function, description:String, group:String = "APP" ):void {
		var arr:Array = exec as Array;
		if ( exec is String ) arr = [exec];
		for each( var cmd:String in arr ) DConsole.createCommand( cmd, fun, group, description );
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
