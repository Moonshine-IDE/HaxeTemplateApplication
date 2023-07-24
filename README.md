# HaxeTemplateApplication

An abstract template to use as OpenFL/Feathers-UI application.

## Minimum Requirements

- Haxe 4.1
- OpenFL 8.9.7
- Feathers UI 1.0.0-rc.1
- Champaign

## Installation

Update dependencies in your application's [project.xml](https://github.com/Moonshine-IDE/HaxeTemplateApplication/project.xml).

Extend application using the base _Application_ template:

`class YourApplication extends BaseTemplateApplication`

## Features

### Application, excepion/crash logging

Automatic

### Crash-log submission (optional)

To enable, provide an URL to submit, in extending Application.
For more information on fields to submit:
https://github.com/Moonshine-IDE/FormBuilder-Crash-Report

`appTemplateConfiguration.crashReportSubmissionURL = "-url-to-report-post-";`

### Application update check (optional)

To enable, provide an URL to update-check/XML, in extending Application:

`appTemplateConfiguration.updateCheckURL = "-url-to-update-check-/updater.xml";`

Supported XML format:
```
<update>
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
```