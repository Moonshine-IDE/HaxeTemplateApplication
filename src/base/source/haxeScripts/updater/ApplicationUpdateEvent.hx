package base.source.haxeScripts.updater;

import openfl.events.Event;

class ApplicationUpdateEvent extends Event 
{
    public static final INITIALIZED = "initialized";
    public static final UPDATE_STATUS_AVAILABLE = "update-status-available";
    public static final UPDATE_ERROR = "update-check-error";
    public static final DOWNLOAD_ERROR = "download-file-error";
    public static final DOWNLOAD_STARTED = "download-started";
    public static final DOWNLOAD_PROGRESS = "download-progress";
    public static final DOWNLOADED = "downloaded";

    public var value:Dynamic;

    public function new(type:String, value:Dynamic=null, canBubble:Bool=false, isCancelable:Bool=true)
    {
        super(type, canBubble, isCancelable);
        
        this.value = value;
    }
    
    override public function clone():Event 
    {
        return new ApplicationUpdateEvent(this.type, this.value, this.bubbles, this.cancelable);
    }
}