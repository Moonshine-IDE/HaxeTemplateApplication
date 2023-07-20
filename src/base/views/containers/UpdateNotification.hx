package base.views.containers;

import feathers.controls.AssetLoader;
import feathers.controls.TitleWindow;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalLayoutData;
import feathers.controls.HProgressBar;
import openfl.events.Event;
import feathers.events.TriggerEvent;
import feathers.text.TextFormat;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.layout.HorizontalLayout;
import feathers.controls.Button;
import feathers.skins.RectangleSkin;
import feathers.layout.AnchorLayoutData;
import feathers.layout.AnchorLayout;
import feathers.controls.LayoutGroup;
import feathers.core.InvalidationFlag;

class UpdateNotification extends TitleWindow
{
    public static final EVENT_CLOSE:String = "event-close-update-notification";
    public static final EVENT_UPDATE_CONFIRM:String = "event-update-notification-confirmed";
    public static final EVENT_UPDATE_CANCEL:String = "event-update-cancel";

    public var isArbitraryDownload:Bool;

    private var _progressTotal:Float = 100.0;
	@:flash.property
	public var progressTotal(get, set):Float;
	private function get_progressTotal():Float 
    {
		return this._progressTotal;
	}
    private function set_progressTotal(value:Float):Float
    {
        this._progressTotal = value;
        return this._progressTotal;
    }

    private var _progressLoaded:Float = 0.0;
	@:flash.property
	public var progressLoaded(get, set):Float;
	private function get_progressLoaded():Float 
    {
		return this._progressLoaded;
	}
    private function set_progressLoaded(value:Float):Float
    {
        this._progressLoaded = value;
        this.setInvalid(DATA);
        return this._progressLoaded;
    }

    private var rootContainer:LayoutGroup;
    private var lblVersionInformation:Label;
    private var lblConfirmMessage:Label;
    private var yesNoContainer:LayoutGroup;
    private var progressContainer:LayoutGroup;
    private var hProgressBar:HProgressBar;

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
        this.layout = new AnchorLayout();

        var rootContainerLayout = new HorizontalLayout();
        rootContainerLayout.verticalAlign = MIDDLE;
        rootContainerLayout.horizontalAlign = CENTER;
        rootContainerLayout.gap = 10;
        rootContainerLayout.setPadding(30);

        this.rootContainer = new LayoutGroup();
        this.rootContainer.backgroundSkin = new RectangleSkin();
        cast(this.rootContainer.backgroundSkin, RectangleSkin).fill = SolidColor(0xe1e1e1);
        this.rootContainer.layoutData = AnchorLayoutData.center();
        this.rootContainer.layout = rootContainerLayout;
        this.addChild(this.rootContainer);

        /*var btnClose = new Button();
        btnClose.variant = SharedTheme.IMAGE_VARIANT_BIG_CLOSE_ICON;
        btnClose.layoutData = new AnchorLayoutData(90, 86);
        btnClose.width = btnClose.height = 28;
        btnClose.addEventListener(TriggerEvent.TRIGGER, onCloseEvent, false, 0, true);
        this.addChild(btnClose);*/

        var imgInstall = new AssetLoader("theme/images/imgInstall.png");
        imgInstall.width = 135;
        imgInstall.height = 151;
        this.rootContainer.addChild(imgInstall);

        var descriptorContainerLayout = new VerticalLayout();
        descriptorContainerLayout.gap = 4;

        var descripContainer = new LayoutGroup();
        descripContainer.layout = descriptorContainerLayout;
        descripContainer.layoutData = new HorizontalLayoutData(null, null);
        this.rootContainer.addChild(descripContainer);

        var lblTitle = new Label(this.isArbitraryDownload ? "Downloading" : "Updates");
        lblTitle.textFormat = new TextFormat(defaultFont, 15, true);
        descripContainer.addChild(lblTitle);

        this.lblVersionInformation = new Label("New version is available.");
        this.lblVersionInformation.textFormat = new TextFormat(defaultFont, 15);
        descripContainer.addChild(this.lblVersionInformation);

        this.lblConfirmMessage = new Label("Do you want to download it and install?");
        this.lblConfirmMessage.textFormat = new TextFormat(defaultFont, 15);
        descripContainer.addChild(this.lblConfirmMessage);

        this.yesNoContainer = new LayoutGroup();
        this.yesNoContainer.layout = new HorizontalLayout();
        cast(this.yesNoContainer.layout, HorizontalLayout).paddingTop = 20;
        cast(this.yesNoContainer.layout, HorizontalLayout).gap = 6;
        this.yesNoContainer.layoutData = new VerticalLayoutData(100, null);
        descripContainer.addChild(this.yesNoContainer);

        var btnYes = new Button("Yes");
        btnYes.layoutData = new HorizontalLayoutData(30, null);
        //btnYes.variant = SharedTheme.THEME_VARIANT_LARGE_BUTTON;
        btnYes.addEventListener(TriggerEvent.TRIGGER, onYesButtonClicked, false, 0, true);
        this.yesNoContainer.addChild(btnYes);

        var btnNo = new Button("No");
        btnNo.layoutData = new HorizontalLayoutData(30, null);
        //btnNo.variant = SharedTheme.THEME_VARIANT_LARGE_BUTTON;
        btnNo.addEventListener(TriggerEvent.TRIGGER, onCloseEvent, false, 0, true);
        this.yesNoContainer.addChild(btnNo);

        this.progressContainer = new LayoutGroup();
        this.progressContainer.layout = new VerticalLayout();
        cast(this.progressContainer.layout, VerticalLayout).gap = 6;
        this.progressContainer.layoutData = new VerticalLayoutData(100, null);
        this.progressContainer.includeInLayout = this.progressContainer.visible = false;
        descripContainer.addChild(this.progressContainer);

        this.hProgressBar = new HProgressBar();
        this.hProgressBar.value = 0.0;
        this.hProgressBar.layoutData = new VerticalLayoutData(80, null);
        this.progressContainer.addChild(this.hProgressBar);

        var btnCancel = new Button("Cancel Download");
        btnCancel.layoutData = new HorizontalLayoutData(30, null);
        ///btnCancel.variant = SharedTheme.THEME_VARIANT_LARGE_BUTTON;
        btnCancel.addEventListener(TriggerEvent.TRIGGER, onCancelDownloadEvent, false, 0, true);
        this.progressContainer.addChild(btnCancel);

        super.initialize();

        if (this.isArbitraryDownload)
        {
            this.showArbitraryDownloadView();
        }
    }

    override private function update():Void 
    {
        var dataInvalid = this.isInvalid(InvalidationFlag.DATA);
        if (dataInvalid) 
        {
            if (this.hProgressBar.visible)
            {
                this.hProgressBar.minimum = 0.0;
                this.hProgressBar.maximum = this.progressTotal;
                this.hProgressBar.value = this.progressLoaded;
            }
        }

        super.update();
    }

    private function showArbitraryDownloadView():Void
    {
        this.lblVersionInformation.text = "Downloading ";
        this.lblConfirmMessage.includeInLayout = this.lblConfirmMessage.visible = false;
        this.onYesButtonClicked(null);
    }

    private function onCloseEvent(event:TriggerEvent):Void
    {
        this.dispatchEvent(new Event(EVENT_UPDATE_CANCEL));
    }

    private function onYesButtonClicked(event:TriggerEvent):Void
    {
        this.yesNoContainer.includeInLayout = this.yesNoContainer.visible = false;
        this.progressContainer.includeInLayout = this.progressContainer.visible = true;

        this.dispatchEvent(new Event(EVENT_UPDATE_CONFIRM));
    }

    private function onCancelDownloadEvent(event:TriggerEvent):Void
    {
        this.dispatchEvent(new Event(EVENT_UPDATE_CANCEL));
    }
}