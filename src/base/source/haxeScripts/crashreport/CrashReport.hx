package base.source.haxeScripts.crashreport;

import lime.system.System;
import feathers.controls.Alert;
import haxe.Json;
import haxe.xml.Access;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import openfl.net.URLLoader;
import haxe.Resource;
import openfl.filesystem.File;
import openfl.filesystem.FileMode;
import openfl.filesystem.FileStream;
import sys.FileSystem;
import openfl.Lib;
import openfl.system.Capabilities;
import openfl.events.EventDispatcher;

class CrashReport extends EventDispatcher
{
    private var _os:String;
    public var os(get, never):String;
    private function get_os():String
    {
        return _os;
    }

    private var _appName:String;
    public var appName(get, never):String;
    private function get_appName():String
    {
        return _appName;
    }

    private var _appVersion:String;
    public var appVersion(get, never):String;
    private function get_appVersion():String
    {
        return _appVersion;
    }

    private var _userIdentity:String;
    public var userIdentity(get, set):String;
    private function get_userIdentity():String
    {
        return _userIdentity;
    }
    private function set_userIdentity(value:String):String
    {
        _userIdentity = value;
        return _userIdentity;
    }

    private var _log:String;
    public var log(get, never):String;
    private function get_log():String
    {
        return _log;
    }

    public var crashReportSubmissionURL:String;

    private var httpService:URLLoader;

    public function new(filePath:String)
    {
        super();

        var config = Lib.application.meta;

        this._os = Capabilities.os;
        this._appName = config.get("name");
        this._appVersion = config.get("version");

        if (FileSystem.exists(filePath))
        {
            this._log = this.readFrom(new File(filePath));
        }
    }

    public function getReportInText():String
    {
        var reportFormat:String = "";
        
        if (FileSystem.exists(System.applicationDirectory + "resources/REPORTFORMA.template"))
        {
            reportFormat = this.readFrom(new File(System.applicationDirectory + "resources/REPORTFORMA.template"));
            reportFormat = StringTools.replace(reportFormat, "$applicationName", _appName);
            reportFormat = StringTools.replace(reportFormat, "$applicationVersion", _appVersion);
            reportFormat = StringTools.replace(reportFormat, "$OS", _os);
            reportFormat = StringTools.replace(reportFormat, "$userID", "N/A");
            reportFormat = StringTools.replace(reportFormat, "$crashLog", _log);    
        }
        
        return reportFormat;
    }

    public function submit():Void
    {
        var request = new URLRequest(this.crashReportSubmissionURL);
        request.data = getReportToPost();
        request.method = "POST";

        this.httpService = new URLLoader();
        this.httpService.addEventListener(Event.COMPLETE, onReportPostSuccess, false, 0, true);
        this.httpService.addEventListener(IOErrorEvent.IO_ERROR, onReportPostError, false, 0, true);
        this.httpService.load(request);
    }

    private function getReportToPost():URLVariables
    {
        var variables = new URLVariables();
        variables.App = this._appName;
        variables.AppVersion = this._appVersion;
        variables.OS = this._os;
        variables.OSVersion = this._os;
        variables.User = this._userIdentity;
        variables.Log = StringTools.urlEncode(this._log);

        return variables;
    }

    private function onReportPostSuccess(event:Event):Void
    {
        var response = Json.parse(event.target.data);
        if ((response.errorMessage != null) && (response.errorMessage != ""))
        {
            Alert.show(response.errorMessage, "Warning (Server)", ["OK"]);
        }
        else
        {
            Alert.show("Report submitted successfully!", "Note!", ["OK"]);
        }
    }

    private function onReportPostError(event:IOErrorEvent):Void
    {
        Alert.show("Failed to submit crash report!\n"+ event.text, "Error!", ["OK"]);
    }

    private function readFrom(file:File):String
    {
        var fs = new FileStream();
        fs.open(file, FileMode.READ);
        var value = fs.readUTFBytes(fs.bytesAvailable);
        fs.close();

        return value;
    }
}