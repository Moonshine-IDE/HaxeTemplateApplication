import feathers.text.TextFormat;
import feathers.controls.Label;
import feathers.layout.VerticalLayout;
import feathers.data.ArrayCollection;
import feathers.layout.AnchorLayoutData;
import feathers.events.TriggerEvent;
import feathers.controls.Button;

class Main extends HaxeTemplateApplication
{
	/**
	 * Property going to use in application
	 * to generate a null index-point exception, 
	 * intentionally
	 **/ 
	private var collection:ArrayCollection<String> = new ArrayCollection();
	
	public function new()
	{
		super();

		/* 
		 * Provide an URL to XML for an update-check
		 * Supported XML format:
		 * <update>
				<!--  Mac update  -->
				<pkg>
					<version>1.0.0</version>
					<url> -- url to pkg installer -- </url>
					<description>
						<![CDATA[ * This a Mac update ]]>
					</description>
				</pkg>
				<!--  Win update  -->
				<exe>
					<version>1.0.0</version>
					<url> -- url to windows installer -- </url>
					<description>
						<![CDATA[ * This a Win update ]]>
					</description>
					</exe>
				</update>
		 */
		//this.appTemplateConfiguration.updateCheckURL = "-url-to-update-check-/updater.xml";

		/*
		 * To disable an update-check, either leaves `updateCheckURL` blank, or
		 * set `checkForUpdates` to false
		 */
		//this.appTemplateConfiguration.checkForUpdates = false;

		/*
		 * Provide an URL to submit the crash-report. 
		 * Leave it blank will enable the crash-log view-only, and no submission.
		 * 
		 * For more information on fields to submit:
		 * https://github.com/Moonshine-IDE/FormBuilder-Crash-Report
		 */
		//this.appTemplateConfiguration.crashReportSubmissionURL = "-url-to-report-post-";
	}

	override private function initialize():Void
	{
		super.initialize();

		var thisLayout = new VerticalLayout();
		thisLayout.horizontalAlign = CENTER;
		thisLayout.verticalAlign = MIDDLE;
		thisLayout.gap = 20;
		this.layout = thisLayout;
		
		var lblHelloWorld = new Label("Hello World!");
		lblHelloWorld.textFormat = new TextFormat("_sans", 32);
		this.addChild(lblHelloWorld);

		var btnCrashMe = new Button("Crash Me!");
		btnCrashMe.layoutData = AnchorLayoutData.center();
		btnCrashMe.addEventListener(TriggerEvent.TRIGGER, onCrashRequest, false, 0, true);
		this.addChild(btnCrashMe);

		
	}

	private function onCrashRequest(event:TriggerEvent):Void
	{
		/* 
		 * While the `collection` property only initialized
		 * but never populated with data,
		 * a specific index call will generate
		 * an immediate no-index exception followed by
		 * the application crash.
		 */
		this.collection.get(1);
	}
}