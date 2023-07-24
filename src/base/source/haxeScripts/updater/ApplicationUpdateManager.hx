package base.source.haxeScripts.updater;

import base.source.views.containers.UpdateNotification;
import feathers.controls.Alert;
import feathers.core.PopUpManager;
import feathers.controls.Application;
import openfl.events.Event;

class ApplicationUpdateManager 
{
    public var updateCheckURL:String;
    public var currentVersion:String;

    private var updateNotification:UpdateNotification;
	private var applicationUpdater:ApplicationUpdater;
    
    public function new()
    {
        
    }  

    //--------------------------------------------------------------------------
    //
    //  APPLICATION UPDATER API
    //
    //--------------------------------------------------------------------------

    public function initializeUpdateCheck():Void
    {
        // in case the applicationUpdater already in-progress
        // ideally when minimize-restore triggers the check 
        if (this.applicationUpdater != null)
            return;

        this.initializeApplicationUpdater();
        this.applicationUpdater.check();
    }

    /**
        Mainly ideal for installing from any location
        without a need for an update-test URL.
        Current usage:
        Native version downgrade
    **/
    public function downloadArbitraryInstaller(url:String):Void
    {
        if (this.applicationUpdater != null)
            return;

        this.initializeApplicationUpdater();
        this.applicationUpdater.updateInfo = {
            version: "0.0.0",
            url: url,
            description: ""
        };
        this.onUpdateAvailable(true);
    }

    private function initializeApplicationUpdater():Void
    {
        this.applicationUpdater = new ApplicationUpdater();
        this.applicationUpdater.currentVersion = this.currentVersion;
        this.applicationUpdater.updateCheckURL = this.updateCheckURL;
        this.applicationUpdater.addEventListener(ApplicationUpdateEvent.UPDATE_STATUS_AVAILABLE, onUpdateStatusChange, false, 0, true);
        this.applicationUpdater.addEventListener(ApplicationUpdateEvent.UPDATE_ERROR, onUpdateCheckError, false, 0, true);
        this.applicationUpdater.addEventListener(ApplicationUpdateEvent.DOWNLOAD_PROGRESS, onDownloadProgress, false, 0, true);
        this.applicationUpdater.addEventListener(ApplicationUpdateEvent.DOWNLOAD_ERROR, onDownloadProgressError, false, 0, true);
    }

    private function releaseApplicationUpdater():Void
    {
        this.applicationUpdater.removeEventListener(ApplicationUpdateEvent.UPDATE_STATUS_AVAILABLE, onUpdateStatusChange);
        this.applicationUpdater.removeEventListener(ApplicationUpdateEvent.UPDATE_ERROR, onUpdateCheckError);
        this.applicationUpdater.removeEventListener(ApplicationUpdateEvent.DOWNLOAD_PROGRESS, onDownloadProgress);
        this.applicationUpdater.removeEventListener(ApplicationUpdateEvent.DOWNLOAD_ERROR, onDownloadProgressError);
        this.applicationUpdater = null;
    }

    private function onUpdateStatusChange(event:ApplicationUpdateEvent):Void
    {
        if (event.value == true)
        {
            this.onUpdateAvailable();
        }
        else 
        {
            this.releaseApplicationUpdater();
        }
    }

    private function onUpdateCheckError(event:ApplicationUpdateEvent):Void
    {
        this.releaseApplicationUpdater();
    }

    private function onDownloadProgress(event:ApplicationUpdateEvent):Void
    {
        this.updateNotification.progressLoaded = event.value;
    }

    private function onDownloadProgressError(event:ApplicationUpdateEvent):Void
    {
        Alert.show(cast(event.value, String), "Error!", ["OK"]);
        onUpdateClose(event);
        this.releaseApplicationUpdater();
    }

    private function onUpdateAvailable(?isArbitraryDownload:Bool=false):Void
    {
        this.updateNotification = new UpdateNotification();
        this.updateNotification.isArbitraryDownload = isArbitraryDownload;
        this.updateNotification.addEventListener(UpdateNotification.EVENT_UPDATE_CANCEL, onUpdateCancelled, false, 0, true);
        this.updateNotification.addEventListener(UpdateNotification.EVENT_UPDATE_CONFIRM, onUpdateConfirm, false, 0, true);
        this.updateNotification.addEventListener(UpdateNotification.EVENT_CLOSE, onUpdateClose, false, 0, true);
        
        PopUpManager.addPopUp(this.updateNotification, Application.topLevelApplication);
    }

    private function onUpdateCancelled(event:Event):Void
    {
        onUpdateClose(event);
        this.applicationUpdater.cancelUpdate();
        this.releaseApplicationUpdater();
    }

    private function onUpdateConfirm(event:Event):Void
    {
        this.applicationUpdater.downloadUpdate();
    }

    private function onUpdateClose(event:Event):Void
    {
        this.updateNotification.removeEventListener(UpdateNotification.EVENT_UPDATE_CANCEL, onUpdateCancelled);
        this.updateNotification.removeEventListener(UpdateNotification.EVENT_UPDATE_CONFIRM, onUpdateConfirm);
        this.updateNotification.removeEventListener(UpdateNotification.EVENT_CLOSE, onUpdateClose);

        PopUpManager.removePopUp(this.updateNotification);
        this.updateNotification = null;
    }
}