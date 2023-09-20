/*
Usage:
haxe \
--run build/Build.hx \
--app_name HaxeTemplateApplication \
--app_id net.prominic.HaxeTemplateApplication \
--env development \
--version 1.2.3 \
--build_number 42	
*/

package build;

class Build {
	static var appName: String = "";
    static var appId: String = "";
	static var env: String = "";
	static var version: String = "";
    static var buildNumber: String = "";
		
    static function main() {
        parseArgs();

        overrideProjectXml();
        installHaxelibDependencies();
        build();
    }

    static function parseArgs() {
		var args = Sys.args();        

        for (i in 0...args.length) {
            switch (args[i]) {
                case "--app_name":
                    appName = args[i + 1];
                case "--app_id":
                    appId = args[i + 1];
                case "--env":
                    env = args[i + 1];
                case "--version":
                    version = args[i + 1];
                case "--build_number":
                    buildNumber = args[i + 1];
                default:
            }
        }

        trace("appName: " + appName);
        trace("appId: " + appId);
        trace("env: " + env);
        trace("version: " + version);
        trace("buildNumber: " + buildNumber);
	}

    static function overrideProjectXml() {
        var content = sys.io.File.getContent('./project.xml');
        var xml = Xml.parse(content);
        var project = xml.elementsNamed('project').next();
        var meta = project.elementsNamed('meta').next();
        meta.set('title', '${appName} ${version} (Build ${buildNumber})');
        meta.set('package', appId);
        meta.set('version', version);
        var app = project.elementsNamed('app').next();
        app.set('file', appName);
        sys.io.File.saveContent('./project.xml', xml.toString());
    }

    static function installHaxelibDependencies() {        
        Sys.command("haxelib --global update haxelib --quiet");

        Sys.command("haxelib install hxcpp --quiet");
        Sys.command("haxelib install lime --quiet");
        Sys.command("haxelib install openfl --quiet");
        Sys.command("haxelib install actuate --quiet");
        Sys.command("haxelib install feathersui --quiet");
        Sys.command("haxelib install amfio --quiet");
        Sys.command("haxelib git champaign https://github.com/Moonshine-IDE/Champaign.git --quiet");
    }

    static function build() {
        var flags = "";
        if (env == "development") {
            flags = "-debug";
        } else {
            flags = "-final";
        }
        Sys.command('haxelib run openfl build ./project.xml ${Sys.systemName()} ${flags}');
    }
}