package build;

// Usage:
// $: haxe --run build/InstallDependencies.hx --main InstallDependencies

class InstallDependencies {
    public static function main() {        
        Sys.command("haxelib --global update haxelib --quiet");

        Sys.command("haxelib install hxcpp --quiet");
        Sys.command("haxelib install lime --quiet");
        Sys.command("haxelib install openfl --quiet");
        Sys.command("haxelib install actuate --quiet");
        Sys.command("haxelib install feathersui --quiet");
        Sys.command("haxelib install amfio --quiet");
        Sys.command("haxelib git champaign https://github.com/Moonshine-IDE/Champaign.git --quiet");
    }
}