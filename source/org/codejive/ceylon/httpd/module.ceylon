Module module {
    name='org.codejive.ceylon.httpd';
    version='1.0.0';
    doc = "A very simple HTTP server";
    by = { "The Ceylon Team" };
    license = 'http://www.gnu.org/licenses/gpl.html';
    dependencies = {
        Import {
            name = 'io.netty';
            version = '3.5.0.Final';
            optional = false;
            export = false;
        },
        Import {
            name = 'org.codejive.ceylon.options';
            version = '0.1';
            optional = false;
            export = false;
        },
        Import {
            name = 'ceylon.interop.java';
            version = '0.3.1';
            optional = false;
            export = false;
        }
    };
}