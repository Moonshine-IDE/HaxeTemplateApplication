package base.haxeScripts.crashreport;

class AppTemplateConfiguration 
{
    private static var INSTANCE:AppTemplateConfiguration;
    
    public static function getInstance():AppTemplateConfiguration
    {
        if (INSTANCE == null)
        {
            INSTANCE = new AppTemplateConfiguration();
        }
        return INSTANCE;
    }

    public function new()
    {
    }

    public var updateCheckURL:String;
    public var crashReportSubmissionURL:String;
    public var checkForUpdates:Bool = true;
}