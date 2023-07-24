package base.source.views.containers;

import base.source.haxeScripts.crashreport.AppTemplateConfiguration;
import base.source.haxeScripts.crashreport.CrashReport;
import base.feathers.controls.TitleWindow;
import openfl.Lib;
import feathers.controls.TextArea;
import feathers.controls.ScrollContainer;
import feathers.core.PopUpManager;
import openfl.events.MouseEvent;
import feathers.controls.AssetLoader;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalLayoutData;
import openfl.events.Event;
import feathers.events.TriggerEvent;
import feathers.text.TextFormat;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.HorizontalLayout;
import feathers.controls.Button;
import feathers.skins.RectangleSkin;
import feathers.controls.LayoutGroup;

class CrashNotification extends TitleWindow
{
    public static final EVENT_CLOSE:String = "event-close-update-notification";
    public static final EVENT_SUBMIT_REPORT:String = "event-submit-crash-report";

    public var crashLogFilePath:String;
    public var crashLogExists:Bool;

    private var _crashReport:CrashReport;
    public var crashReport(get, never):CrashReport;
    private function get_crashReport():CrashReport
    {
        return _crashReport;
    }

    private final messageWithCrashLog = "Application crashed during the previous session. Please contact $companyName Support for further assistance. You may review the report before a submit.";
    private final messageWithoutCrashLog = "Application crashed during the previous launch. Please contact $companyName Support for further assistance.";

    private var messageContainer:LayoutGroup;
    private var isReportShowing:Bool;
    private var reviewContainer:ScrollContainer;
    private var lblReview:Label;
    private var windowOriginalHeight:Float;

    #if windows
		private var defaultFont:String = "Arial";
	#else
        private var defaultFont:String = "_sans";
	#end
	private var defaultFontSize:Int = 13;

    public function new()
    {
        super();
    }

    override private function initialize():Void
    {
        this.width = 600;

        var rootLayout = new VerticalLayout();
        rootLayout.horizontalAlign = CENTER;
        rootLayout.verticalAlign = TOP;
        rootLayout.gap = 12.0;
        rootLayout.paddingBottom = 20;
        this.layout = rootLayout;

        this.backgroundSkin = new RectangleSkin();
        cast(this.backgroundSkin, RectangleSkin).fill = SolidColor(0xf8f8f8);

        var messageContainerLayout = new HorizontalLayout();
        messageContainerLayout.verticalAlign = MIDDLE;
        messageContainerLayout.gap = 20;
        messageContainerLayout.paddingTop = messageContainerLayout.paddingLeft = messageContainerLayout.paddingRight = 30;

        this.messageContainer = new LayoutGroup();
        this.messageContainer.layoutData = new VerticalLayoutData(100);
        this.messageContainer.layout = messageContainerLayout;
        this.addChild(this.messageContainer);

        var imgInstall = new AssetLoader("images/warning.png");
        imgInstall.width = 62;
        imgInstall.height = 55;
        this.messageContainer.addChild(imgInstall);

        var message = "";
        var config = Lib.application.meta;
        if (this.crashLogExists)
        {
            message = StringTools.replace(messageWithCrashLog, "$companyName", config.get("company"));
        }
        else
        {
            message = StringTools.replace(messageWithoutCrashLog, "$companyName", config.get("company"));   
        }

        var lblMessage = new Label(message);
        lblMessage.layoutData = new HorizontalLayoutData(100);
        lblMessage.wordWrap = true;
        lblMessage.textFormat = new TextFormat(defaultFont, 16, 0x292929);
        this.messageContainer.addChild(lblMessage);

        var footerLayout = new HorizontalLayout();
        footerLayout.paddingLeft = 114;

        var footerContainer = new LayoutGroup();
        footerContainer.layout = footerLayout;
        footerContainer.layoutData = new VerticalLayoutData(100);
        this.addChild(footerContainer);

        var buttonsLinesContainer = new LayoutGroup();
        buttonsLinesContainer.layout = new VerticalLayout();
        buttonsLinesContainer.layoutData = new HorizontalLayoutData(100);
        footerContainer.addChild(buttonsLinesContainer);

        var hLine = new LayoutGroup();
        hLine.height = 1;
        hLine.backgroundSkin = new RectangleSkin(SolidColor(0xCCCCCC));
        hLine.layoutData = new VerticalLayoutData(96);
        buttonsLinesContainer.addChild(hLine);

        var buttonsContainerLayout = new HorizontalLayout();
        buttonsContainerLayout.gap = 10;
        buttonsContainerLayout.paddingTop = 12;
        buttonsContainerLayout.verticalAlign = BOTTOM;

        var buttonsContainer = new LayoutGroup();
        buttonsContainer.layout = buttonsContainerLayout;
        buttonsContainer.layoutData = new VerticalLayoutData(100);
        buttonsLinesContainer.addChild(buttonsContainer);

        var appConfig = AppTemplateConfiguration.getInstance();
        var showSubmitButton = this.crashLogExists && (appConfig.crashReportSubmissionURL != null);
        if (showSubmitButton)
        {
            var btnSubmit = new Button("Submit Crash Report");
            btnSubmit.addEventListener(TriggerEvent.TRIGGER, onSubmit, false, 0, true);
            buttonsContainer.addChild(btnSubmit);    
        }

        var btnContinue = new Button(showSubmitButton ? "Do Not Submit" : "Continue");
        btnContinue.addEventListener(TriggerEvent.TRIGGER, onCloseEvent, false, 0, true);
        buttonsContainer.addChild(btnContinue);

        if (this.crashLogExists)
        {
            this.lblReview = new Label("Preview Report");
            this.lblReview.textFormat = new TextFormat(defaultFont, 13, 0x000000, false, false, true);
            this.lblReview.buttonMode = true;
            this.lblReview.addEventListener(MouseEvent.CLICK, onReview, false, 0, true);
            buttonsContainer.addChild(this.lblReview);    
        }
        
        super.initialize();
    }

    private function reviewReportContainer():ScrollContainer
    {
        var containerLayout = new VerticalLayout();
        containerLayout.paddingBottom = containerLayout.paddingTop = 10;
        containerLayout.paddingLeft = 98;

        var container = new ScrollContainer();
        container.layout = containerLayout;

        var lblReviewTitle = new Label("Preview Report Before Submission");
        lblReviewTitle.layoutData = new VerticalLayoutData(100);
        container.addChild(lblReviewTitle);

        var txtDetails = new TextArea(this.crashReport.getReportInText());
        txtDetails.textFormat = new TextFormat("_typewriter", 14);
        txtDetails.layoutData = new VerticalLayoutData(100, 100);
        txtDetails.wordWrap = true;
        txtDetails.editable = false;
        container.addChild(txtDetails);
        
        return container;
    }

    private function onCloseEvent(event:TriggerEvent):Void
    {
        this.dispatchEvent(new Event(EVENT_CLOSE));
    }

    private function onSubmit(event:TriggerEvent):Void
    {
        this.initializeReport();
        this.dispatchEvent(new Event(EVENT_SUBMIT_REPORT));
    }

    private function onReview(event:MouseEvent):Void
    {
        if (this.isReportShowing) 
            this.hideReview();
        else 
            this.showReview();
    }

    private function showReview():Void
    {
        this.initializeReport();

        this.reviewContainer = this.reviewReportContainer();
        this.reviewContainer.layoutData = new VerticalLayoutData(95, 100);
        this.addChild(this.reviewContainer);

        this.isReportShowing = true;
        this.windowOriginalHeight = this.height;
        this.width = 700;
        this.height = 600;
        this.validateNow();

        this.lblReview.text = "Hide Report";
        this.reviewContainer.includeInLayout = this.reviewContainer.visible = true;

        PopUpManager.centerPopUp(this);
    }

    private function hideReview():Void
    {
        this.reviewContainer.includeInLayout = this.reviewContainer.visible = false;
        this.lblReview.text = "Preview Report";
        this.isReportShowing = false;
        this.width = 600;
        this.height = this.windowOriginalHeight;
        this.validateNow();
    }

    private function initializeReport():Void
    {
        if (_crashReport == null)
        {
            _crashReport = new CrashReport(this.crashLogFilePath);
        }   
    }
}