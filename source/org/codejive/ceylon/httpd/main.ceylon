
import java.io { File, OutputStream, RandomAccessFile, FileNotFoundException }
import java.lang { System { sysOut=\iout, getSystemProperty=getProperty }, Thread { currentThread } }
import java.net {
    URI,
    InetSocketAddress,
    HttpURLConnection { \iHTTP_OK, \iHTTP_BAD_METHOD, \iHTTP_FORBIDDEN, \iHTTP_NOT_FOUND, \iHTTP_INTERNAL_ERROR }
}
import java.nio.file { Files { probeContentType } }

import ceylon.interop.java { javaString, createByteArray }

import org.codejive.ceylon.options { Options, Option }

import com.sun.net.httpserver { HttpServer { createHttpServer=create }, HttpHandler, HttpExchange, Headers }

class CeylonHttpHandler(Boolean list, String[] indices, Boolean verbose) satisfies HttpHandler {
    
    shared actual void handle(HttpExchange x) {
        if (x.requestMethod.uppercased != "GET") {
            sendError(x, \iHTTP_BAD_METHOD);
            if (verbose) {
                sysOut.println("405 Method Not Allowed");
            }
            return;
        }
        
        try {
            if (verbose) {
                sysOut.print("GET " x.requestURI " ");
            }
            String result = handleGet(x);
            if (verbose) {
                sysOut.println(result);
            }
        } catch (Exception ex) {
            sendError(x, \iHTTP_INTERNAL_ERROR);
            if (verbose) {
                sysOut.println("500 Internal Server Error");
                ex.printStackTrace();
            }
        }
    }
    
    String handleGet(HttpExchange x) {
        File path = uriToFile(x.requestURI);
        File root = File(".");
        variable File file = path;
        if (file.hidden || !file.\iexists() || !childPath(root, file) exists) {
            sendError(x, \iHTTP_NOT_FOUND);
            return "404 Not Found";
        }
        
        if (file.directory) {
            if (exists index = findIndex(file, indices)) {
                file = index;
            }
        }
        if (file.directory) {
            if (!file.directory || !list) {
                sendError(x, \iHTTP_FORBIDDEN);
                return "403 Forbidden";
            }
            
            value buf = StringBuilder();
            buf.append("<html><head>");
            buf.append("<title>Contents of ...</title>");
            buf.append("</head><body>");
            
            value files = file.listFiles();
            for (File f in files) {
                String? p = childPath(root, f);
                if (!f.hidden) {
                    if (exists p) {
                        buf.append("<a href=\"");
                        buf.append(p.replace("\\", "/"));
                        buf.append("\">");
                        buf.append(f.name);
                        buf.append("</a><br>");
                    }
                }
            }
            
            buf.append("</body></html>");
            
            sendHtmlResponse(x, buf.string);
        } else {
            String? ct = probeContentType(file.toPath());
            String contentType = ct else "application/octet-stream";
            if (verbose) {
                sysOut.print("(" contentType ") ");
            }
            RandomAccessFile raf;
            try {
                raf = RandomAccessFile(file, "r");
            } catch (FileNotFoundException fnfe) {
                sendError(x, \iHTTP_NOT_FOUND);
                return "404 Not Found";
            }
            Integer fileLength = raf.length();

            Headers headers = x.responseHeaders;
            headers.set("Content-Type", contentType);
            x.sendResponseHeaders(200, fileLength);
            OutputStream os = x.responseBody;
            
            try {
                value buf = createByteArray(1024);
                variable Integer size = raf.read(buf);
                while (size > 0) {
                    os.write(buf, 0, size);
                    size = raf.read(buf);
                }
            } finally {
                os.close();
                raf.close();
            }
        }
        return "200 OK";
    }

    void sendError(HttpExchange x, Integer status) {
        sendHtmlResponse(x, wrapHtml("Failure: " status "", "HTTPD Error Page for " status ""), status);
    }
    
    String wrapHtml(String body, String title="HTTPD Page") {
        return "<html><head><title>" + title + "</title></head><body>" + body + "</body></html>";
    }
    
    void sendHtmlResponse(HttpExchange x, String response, Integer status = \iHTTP_OK) {
        Headers headers = x.responseHeaders;
        headers.set("Content-Type", "text/html; charset=UTF-8");
        x.sendResponseHeaders(status, response.size);
        OutputStream os = x.responseBody;
        os.write(javaString(response).getBytes("UTF-8"));
        os.close();
    }

    File uriToFile(URI uri) {
        File cwd = File(getSystemProperty("user.dir"));
        File result = File(cwd, uri.path).canonicalFile;
        if (!result.path.startsWith(cwd.canonicalPath)) {
            return cwd;
        }
        return result;
    }

    String? childPath(File parent, File child) {
        String pp = parent.canonicalPath;
        String cp = child.canonicalPath;
        if (cp.startsWith(pp)) {
            return cp.spanFrom(pp.size);
        } else {
            return null;
        }
    }
    
    File? findIndex(File dir, String[] indices) {
        return indices
            .map((String idx) => File(dir, idx))       // Get the File for each index
            .find((File f) => f.\iexists() && f.file); // Return it if the file exists
    }
}

void start(Integer port, Boolean list, String[] indices, Boolean verbose) {
    // Create server and bind the port to listen to
    HttpServer server = createHttpServer(InetSocketAddress(port), 0);
    server.createContext("/", CeylonHttpHandler(list, indices, verbose));
    server.executor = null;
    // Start to accept incoming connections
    server.start();
    if (verbose) {
        sysOut.println("Started server on port " port "");
    }
}

void run() {
    value opts = Options {
        usage = "Usage: ceylon run org.codejive.ceylon.httpd/1.0.2 -- --port <portnumber> <options>";
        noArgsHelp = "use -h or --help for a list of possible options";
        options = [ Option("help", ["h", "help"], "This help"),
        Option {
            name="port";
            matches=["p", "port"];
            docs="The port number to run the service on";
            hasValue=true;
            required=true;
        },
        Option {
            name="list";
            matches=["l", "list"];
            docs="Allows listing of directories";
        },
        Option {
            name="indices";
            matches=["i", "index"];
            docs="Defines an index file to be served instead of a directory listing";
            hasValue=true;
            multiple=true;
        },
        Option {
            name="verbose";
            matches=["v", "verbose"];
            docs="Shows messages about the server's operation";
        } ];
    };
    
    value res = opts.parse(process.arguments);
    switch(res)
    case (is Options.Result) {
        if (res.options.defines("help")) {
            opts.printUsage();
            opts.printHelp();
        } else {
            value err = opts.validate(res);
            if (exists err) {
                print(err.messages);
            } else {
                Integer port = parseInteger(res.options["port"]?.first else "8080") else 8080;
                Boolean list = res.options.defines("list");
                String[] indices = res.options["indices"] else {};
                Boolean verbose = res.options.defines("verbose");
                start(port, list, indices, verbose);
                currentThread().join();
            }
        }
    }
    case (is Options.Error) {
        print(res.messages);
    }
}

