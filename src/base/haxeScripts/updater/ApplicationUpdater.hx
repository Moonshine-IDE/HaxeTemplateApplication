package base.haxeScripts.updater;

import lime.system.System;
import openfl.net.URLLoaderDataFormat;
import openfl.utils.ByteArray;
import openfl.events.ProgressEvent;
import openfl.filesystem.FileMode;
import openfl.filesystem.File;
import haxe.xml.Access;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLStream;
import openfl.filesystem.FileStream;
import openfl.net.URLLoader;
import openfl.events.EventDispatcher;

typedef ApplicationUpdateInfo = {
    var version:String;
    var url:String;
    var description:String;
}

class ApplicationUpdater extends EventDispatcher 
{
    public var updateCheckURL:String;
    public var currentVersion:String;
    public var updateInfo:ApplicationUpdateInfo;

    private var updatingVersion:String;
    private var updateCheckFileLoader:URLLoader;
    private var downloadFileLoader:URLLoader;
    private var downloadedFile:File;

    public function new()
    {
        super();
    }

    public function check():Void
    {
        if (this.updateCheckURL == null) 
            return;

        this.updateCheckFileLoader = new URLLoader();
        this.updateCheckFileLoader.addEventListener(Event.COMPLETE, onUpdaterFileDownloaded, false, 0, true);
        this.updateCheckFileLoader.addEventListener(IOErrorEvent.IO_ERROR, onUpdaterFileError, false, 0, true);
        this.updateCheckFileLoader.load(new URLRequest(this.updateCheckURL));
    }

    public function downloadUpdate():Void
    {
        var fileName = this.updateInfo.url.substr(this.updateInfo.url.lastIndexOf("/") + 1);
        downloadedFile = File.createTempDirectory().resolvePath(fileName);
        
        this.downloadFileLoader = new URLLoader();
        this.downloadFileLoader.dataFormat = URLLoaderDataFormat.BINARY;
        this.downloadFileLoader.addEventListener(ProgressEvent.PROGRESS, downloadFileProgressHandler);
        this.downloadFileLoader.addEventListener(Event.COMPLETE, downloadFileCompleteHandler);
        this.downloadFileLoader.addEventListener(IOErrorEvent.IO_ERROR, downloadFileErrorHandler);
        
        try
        {
            this.downloadFileLoader.load(new URLRequest(this.updateInfo.url)); 
        }
        catch (e)
        {
            this.dispatchEvent(new ApplicationUpdateEvent(ApplicationUpdateEvent.DOWNLOAD_ERROR, 
                "Error downloading update file: " + e.message));
        }
    }

    public function cancelUpdate():Void
    {
        if (this.downloadFileLoader != null)
        {
            this.releaseDownloadFileLoader();
        }
    }

    private function closeUpdateCheckFileLoader():Void
    {
        this.updateCheckFileLoader.removeEventListener(Event.COMPLETE, onUpdaterFileDownloaded);
        this.updateCheckFileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onUpdaterFileError);
        this.updateCheckFileLoader.close();
    }

    private function onUpdaterFileDownloaded(event:Event):Void
    {
        this.closeUpdateCheckFileLoader();

        parseUpdates(this.updateCheckFileLoader.data);
    }

    private function onUpdaterFileError(event:IOErrorEvent):Void 
    {
        this.closeUpdateCheckFileLoader();

        this.dispatchEvent(new ApplicationUpdateEvent(ApplicationUpdateEvent.UPDATE_ERROR));
    }

    private function parseUpdates(value:String):Void
    {
        var accessData = new Access(Xml.parse(value));
        var accessNode:Access = null;

        #if windows
            accessNode = accessData.node.update.node.exe; 
        #elseif mac
            accessNode = accessData.node.update.node.pkg;
        #end

        updateInfo = {
            version: accessNode.node.version.innerData,
            url: accessNode.node.url.innerData,
            description: accessNode.node.description.innerData
        }; 
        
        var updateAvailable = this.isNewerVersion(this.currentVersion, this.updateInfo.version);
        this.dispatchEvent(new ApplicationUpdateEvent(ApplicationUpdateEvent.UPDATE_STATUS_AVAILABLE, updateAvailable));
    }

    private function isNewerVersion(currentVersion:String, updateVersion:String):Bool
    {
        var tmpSplit = updateVersion.split(".");
        var uv1 = Std.parseInt(tmpSplit[0]);
        var uv2 = Std.parseInt(tmpSplit[1]);
        var uv3 = Std.parseInt(tmpSplit[2]);

        var currentSplit = currentVersion.split(".");
        var currentMajor = Std.parseInt(currentSplit[0]);
        var currentMinor = Std.parseInt(currentSplit[1]);
        var currentRevision = Std.parseInt(currentSplit[2]);
        
        if (uv1 > currentMajor) return true;
        else if (uv1 >= currentMajor && uv2 > currentMinor) return true;
        else if (uv1 >= currentMajor && uv2 >= currentMinor && uv3 > currentRevision) return true;
        
        return false;   
    }

    private function releaseDownloadFileLoader():Void
    {
        downloadFileLoader.removeEventListener(ProgressEvent.PROGRESS, downloadFileProgressHandler);
        downloadFileLoader.removeEventListener(Event.COMPLETE, downloadFileCompleteHandler);
        downloadFileLoader.removeEventListener(IOErrorEvent.IO_ERROR, downloadFileErrorHandler);
        downloadFileLoader.close();
    }

    private function downloadFileErrorHandler(event:IOErrorEvent):Void
    {
        this.releaseDownloadFileLoader();
        
        this.dispatchEvent(new ApplicationUpdateEvent(ApplicationUpdateEvent.DOWNLOAD_ERROR, 
            "Error downloading update file: " + event.text));
    }

    private function downloadFileProgressHandler(event:ProgressEvent):Void
    {
        var bytesLoaded = event.bytesLoaded;
        var bytesTotal = event.bytesTotal; 
        if (bytesLoaded != 0 && bytesTotal != 0)
        {
            var progress = bytesLoaded / bytesTotal * 100.0;
            dispatchEvent(new ApplicationUpdateEvent(ApplicationUpdateEvent.DOWNLOAD_PROGRESS, progress));
        } 
        else 
        {
            dispatchEvent(new ApplicationUpdateEvent(ApplicationUpdateEvent.DOWNLOAD_PROGRESS, 100.0));
        }
    }

    private function downloadFileCompleteHandler(event:Event):Void
    {
        this.releaseDownloadFileLoader();
        
        var fs = new FileStream();
        fs.open(this.downloadedFile, FileMode.WRITE);
        fs.writeBytes(this.downloadFileLoader.data);
        fs.close();
        
        System.openFile(this.downloadedFile.nativePath);
        System.exit(0);
    }
}