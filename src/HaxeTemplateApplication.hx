import base.haxeScripts.crashreport.AppTemplateConfiguration;
import openfl.events.Event;
import feathers.core.PopUpManager;
import base.views.containers.CrashNotification;
import feathers.events.FeathersEvent;
import feathers.data.ButtonBarItemState;
import feathers.controls.Alert;
import haxe.ValueException;
import haxe.Exception;
import sys.FileSystem;
import sys.io.File;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;
import base.haxeScripts.updater.ApplicationUpdateManager;
import lime.system.System;
import champaign.sys.logging.targets.FileTarget;
import champaign.sys.logging.targets.SysPrintTarget;
import champaign.core.logging.Logger;

abstract class HaxeTemplateApplication extends feathers.controls.Application
{
	static public final crashLogFile:String = 'logs/crash.txt';

    public var appTemplateConfiguration = AppTemplateConfiguration.getInstance();
    public var applicationQuitUnexpectedly( default, null ):Bool;
    public var isCrashLogExistsFromPreviousSession( default, null ):Bool;
    
    private var _updateCheckURL:String;
    public var updateCheckURL(get, set):String;
    private function get_updateCheckURL():String
    {
        return _updateCheckURL;
    }
    private function set_updateCheckURL(value:String):String
    {
        if (applicationUpdateManager != null)
        {
            applicationUpdateManager.updateCheckURL = value;
        }
        _updateCheckURL = value;
        return _updateCheckURL;
    }    

    private final _startFileName:String = 'start';

    private var isMinimized:Bool;
    private var applicationUpdateManager:ApplicationUpdateManager;
    private var crashNotification:CrashNotification;

    public function new()
    {
        super();

        var currentVersion = Lib.application.meta.get("version");

        // initialize update-checker
        this.applicationUpdateManager = new ApplicationUpdateManager();
        this.applicationUpdateManager.currentVersion = currentVersion;

        this.isCrashLogExistsFromPreviousSession = this.crashLogExists();

        // Logger
        Logger.init( #if logverbose LogLevel.Verbose #else LogLevel.Debug #end, false ); // DO NOT capture trace!
        Logger.addTarget( new SysPrintTarget( #if logverbose LogLevel.Verbose #else LogLevel.Debug #end, true, false, true ) );
        Logger.addTarget( new FileTarget( System.applicationStorageDirectory + "/logs", "current.txt", 9, LogLevel.Debug, true, false ) );
        Logger.addTarget( new FileTarget( System.applicationStorageDirectory, crashLogFile, 0, LogLevel.Fatal, true, false, false ) );
        Logger.debug('Prominic application started');

        // uncaught error
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.onUncaughtError);

        // Haxe main thread exceptions
        ApplicationMain.onException.add(this.onHaxeException);
        
        // application minimized
        lime.app.Application.current.window.onMinimize.add(this.onApplicationWindowMinimized);

        // application activate
        #if windows
            lime.app.Application.current.window.onRestore.add(this.onApplicationWindowRestoredOrActivated);
        #else
            lime.app.Application.current.window.onActivate.add(this.onApplicationWindowRestoredOrActivated);
        #end
        
        // application exit handle
        lime.app.Application.current.window.onClose.add(this.onApplicationCloseRequest);

        // application exit event
        lime.app.Application.current.onExit.add( onApplicationExit );

        // Check if 'start' exists. If it does, it means the application quit unexpectedly earlier
        applicationQuitUnexpectedly = FileSystem.exists( System.applicationStorageDirectory + _startFileName );

        // Create 'start' file
        if ( !applicationQuitUnexpectedly ) {

            File.saveContent( System.applicationStorageDirectory + _startFileName, "start" );

        }
    }

    override private function initialize():Void 
    {
        super.initialize();

        if (applicationUpdateManager != null)
        {
            applicationUpdateManager.updateCheckURL = this.appTemplateConfiguration.updateCheckURL;
        }

        // Check if the application quit unexpectedly during the previous run
		if ( this.applicationQuitUnexpectedly || this.isCrashLogExistsFromPreviousSession) {

            this.crashNotification = new CrashNotification();
            this.crashNotification.title = "Warning!";
            this.crashNotification.crashLogExists = this.crashLogExists();
            this.crashNotification.crashLogFilePath = System.applicationStorageDirectory + crashLogFile;
            this.crashNotification.addEventListener(CrashNotification.EVENT_CLOSE, onCrashNotificationClose, false, 0, true);
            this.crashNotification.addEventListener(CrashNotification.EVENT_SUBMIT_REPORT, onSubmitReport, false, 0, true);
            PopUpManager.addPopUp(this.crashNotification, this);

		}
        else
        {
            this.addEventListener(FeathersEvent.INITIALIZE, initializeHandler, false, 0, true);
        }
    }

    public function initializeUpdateCheck():Void
    {
        if (!this.appTemplateConfiguration.checkForUpdates || (this.appTemplateConfiguration.updateCheckURL == null))
        {
            return;
        }
        
        if (applicationUpdateManager.updateCheckURL == null) 
            Logger.warning("Warning: update check URL is missing.");
        else 
            applicationUpdateManager.initializeUpdateCheck();
    }

    public function deleteCrashLog():Bool {

        try {

            if ( FileSystem.exists( System.applicationStorageDirectory + crashLogFile ) )
                FileSystem.deleteFile( System.applicationStorageDirectory + crashLogFile );

            return true;

        } catch ( e ) {

            // File deletion unsuccessful

        }

        return false;

    }

    public function deleteStartFile():Bool {

        try {

            if ( FileSystem.exists( System.applicationStorageDirectory + _startFileName ) )
                FileSystem.deleteFile( System.applicationStorageDirectory + _startFileName );

            return true;

        } catch ( e ) {

            // File deletion unsuccessful

        }

        return false;

    }

    private function onCrashNotificationClose(event:Event):Void
    {
        this.crashNotification.removeEventListener(CrashNotification.EVENT_CLOSE, onCrashNotificationClose);
        this.crashNotification.removeEventListener(CrashNotification.EVENT_SUBMIT_REPORT, onSubmitReport);
        PopUpManager.removePopUp(this.crashNotification);

        this.initializeUpdateCheck();
    }

    private function onSubmitReport(event:Event):Void
    {
        var crashReport = this.crashNotification.crashReport;
        crashReport.crashReportSubmissionURL = this.appTemplateConfiguration.crashReportSubmissionURL;
        crashReport.submit();
        
        this.onCrashNotificationClose(event);
    }

    private function initializeHandler(event:FeathersEvent):Void
    {
        this.removeEventListener(FeathersEvent.INITIALIZE, initializeHandler);   
        this.initializeUpdateCheck();
    }

    private function crashLogExists():Bool {

        return FileSystem.exists( System.applicationStorageDirectory + crashLogFile );

    }

    private function onUncaughtError(event:UncaughtErrorEvent):Void
    {
        Logger.fatal( 'Fatal error. UncaughtErrorEvent: ${event}' );
    }

    private function onHaxeException( e:Dynamic ):Void
    {
        if ( Std.isOfType( e, Exception ) && !Std.isOfType( e, ValueException ) ) {
            Logger.fatal( 'Fatal exception : ${e}\nDetails : ${e.details()}\nNative : ${e.native}' );
        } else {
            Logger.fatal( 'Fatal error: ${e}' );
        }
    }

    private function onApplicationWindowMinimized():Void
    {
        this.isMinimized = true;
    }

    private function onApplicationWindowRestoredOrActivated():Void
    {
        if (this.isMinimized)
        {
            this.applicationUpdateManager.initializeUpdateCheck();
            this.isMinimized = false;
        }
    }

    private function onApplicationCloseRequest():Void
    {        
        
    }

    private function onApplicationExit( exitCode:Int ):Void
    {
        deleteStartFile();
        deleteCrashLog();
    }
}
