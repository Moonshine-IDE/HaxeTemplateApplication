/*
Usage:
haxe \
--run build/MakeWinInstaller.hx
*/

package build;

class MakeWinInstaller {
    static function main() {
        downloadNsProcess();
    }

    // static function parseArgs() {
	// 	var args = Sys.args();        

    //     for (i in 0...args.length) {
    //         switch (args[i]) {
    //             case "--app_name":
    //                 appName = args[i + 1];
    //         }
    //     }

    //     trace("appName: " + appName);
	// }

    static function downloadNsProcess() {
        var url = "https://nsis.sourceforge.io/mediawiki/images/1/18/NsProcess.zip";
        var localFile = "NsProcess.7z";
        if (!sys.FileSystem.exists(localFile)) {
            Sys.command('wget ${url} --output-document ${localFile} --no-clobber');
            Sys.command("7z x NsProcess.7z -o'NsProcess'"); 
        }
        
        
    }
}