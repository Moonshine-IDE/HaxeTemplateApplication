package build;

class Main {
    public static function main() {
        switch (Sys.systemName()) {
            case "Mac":
                trace("Running on macOS");
            case "Windows":
                trace("Running on Windows");
            case "Linux":
                trace("Running on Linux");
            case _:
                trace("Running on another platform");
        }
    }
}