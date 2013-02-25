
doc "A very simple HTTP server.
     
     Use on the command line like this `ceylon run org.codejive.ceylon.httpd -- --port <portnumber>`"
by "The Ceylon Team"
license "ASLv2"
module org.codejive.ceylon.httpd '1.1.0' {
    import java.base '7';
    import oracle.jdk.httpserver '7';
    import org.codejive.ceylon.options '1.3.0';
    import ceylon.interop.java '0.5';
}
