package build;

class Build {
    static var system: String;
    static var env: String;
    static var haxeFlag: String;

    public static function main() {
        parseArgs();
        
        Sys.command("haxelib --global update haxelib --quiet");

        Sys.command("haxelib install hxcpp --quiet");
        Sys.command("haxelib install lime --quiet");
        Sys.command("haxelib install openfl --quiet");
        Sys.command("haxelib install actuate --quiet");
        Sys.command("haxelib install feathersui --quiet");
        Sys.command("haxelib install amfio --quiet");
        Sys.command("haxelib git champaign https://github.com/Moonshine-IDE/Champaign.git --quiet");   
        
        var buildCommand = 'haxelib run openfl build ./project.xml ${system} ${haxeFlag} -clean';
        trace('Build command: ' + buildCommand);
        Sys.command(buildCommand);
    }

    public static function parseArgs() {
        var args = Sys.args();

        var i = 0;
        while (i < args.length) {
            switch(args[i]) {
                case "--system":
                    if (i + 1 < args.length) system = args[++i];
                case "--env":
                    if (i + 1 < args.length) env = args[++i];
                case _:
                    Sys.println("Unrecognized parameter: " + args[i]);
                    return;
            }
            i++;
        }

        haxeFlag = env == "production" ? "-final" : "-debug";
    }
}