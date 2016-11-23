
"A very simple HTTP server.
     
 Use on the command line like this `ceylon run org.codejive.ceylon.httpd -- --port <portnumber>`"
by("The Ceylon Team")
license("ASLv2")
native("jvm")
module org.codejive.ceylon.httpd "1.2.6" {
    import java.base "7";
    import oracle.jdk.httpserver "7";
    import org.codejive.ceylon.options "1.5.3";
    import ceylon.interop.java "1.3.1";
}
