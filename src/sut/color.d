module sut.color;



/** Color definitions. */
enum Color: string {
    Reset   = "\033[0;;m",
    Red     = "\033[0;31m",
    //IRed    = "\033[38;5;160m",
    IRed    = "\033[38;5;196m",
    Green   = "\033[0;32m",
    //IGreen  = "\033[38;5;34m",
    IGreen  = "\033[38;5;46m",
    Yellow  = "\033[0;93m",
    White   = "\033[0;97m"
}
