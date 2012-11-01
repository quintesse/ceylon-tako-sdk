
doc "A very simple HTTP server.

Use on the command line like this `ceylon org.codejive.ceylon.httpd --port <portnumber>`"
by "The Ceylon Team"
license "ASLv2"
module org.codejive.ceylon.httpd '1.0.2' {
    import java.base '7';
    import oracle.jdk.httpserver '7';
    import io.netty '3.5.0.Final';
    import org.codejive.ceylon.options '1.0.0';
    import ceylon.interop.java '0.3.3';
}
