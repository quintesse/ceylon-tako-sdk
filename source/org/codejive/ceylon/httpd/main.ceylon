import java.io { File { fileSeparator=separator, fileSeparatorChar=separatorChar }, ... }
import java.lang { Throwable, System { sysOut=\iout, getSystemProperty=getProperty }  }
import java.net { InetSocketAddress, URLDecoder { decodeUrl=decode } }
import java.util.concurrent { Executors { newCachedThreadPool } }

import ceylon.interop.java { javaString }

import org.codejive.ceylon.options { Options, Option, OptionsResult, OptionsError }

import org.jboss.netty.bootstrap { ServerBootstrap }
import org.jboss.netty.channel.socket.nio { NioServerSocketChannelFactory }
import org.jboss.netty.channel {
    Channels { createPipeline=pipeline },
    ChannelFutureListener { CLOSE },
    ChannelFutureProgressListener,
    FileRegion,
    DefaultFileRegion,
    ExceptionEvent,
    SimpleChannelUpstreamHandler, ... }
import org.jboss.netty.handler.codec.frame { TooLongFrameException }
import org.jboss.netty.handler.codec.http {
    HttpRequest,
    HttpResponse,
    DefaultHttpResponse,
    HttpRequestDecoder,
    HttpChunkAggregator,
    HttpResponseEncoder,
    HttpResponseStatus { OK, METHOD_NOT_ALLOWED, FORBIDDEN, NOT_FOUND, BAD_REQUEST, INTERNAL_SERVER_ERROR },
    HttpMethod { GET },
    HttpVersion { HTTP_1_1 },
    HttpHeaders {
        setContentLength,
        isKeepAlive,
        Names { CONTENT_TYPE, CONTENT_LENGTH }
    }, ...
}
import org.jboss.netty.handler.stream { ChunkedWriteHandler, ChunkedFile }
import org.jboss.netty.util { CharsetUtil { UTF_8 }}
import org.jboss.netty.buffer { ChannelBuffers { copiedBuffer } }

T assertNotNull<T>(T? arg) given T satisfies Object {
    if (exists arg) {
        return arg;
    } else {
        throw Exception("Unexpected null");
    }
}

HttpRequest httpRequest(Object obj) {
    if (is HttpRequest obj) {
        return obj;
    } else {
        throw Exception("Not a HttpRequest");
    }
}

String? childPath(File parent, File child) {
    String pp = parent.canonicalPath;
    String cp = child.canonicalPath;
    if (cp.startsWith(pp)) {
        return cp.span(pp.size, null);
    } else {
        return null;
    }
}

class MyChannelFutureProgressListener(FileRegion region, String path) satisfies ChannelFutureProgressListener {
    shared actual void operationComplete(ChannelFuture? future) {
        region.releaseExternalResources();
    }

    shared actual void operationProgressed(ChannelFuture? future, Integer amount, Integer current, Integer total) {
        sysOut.printf("%s: %d / %d (+%d)%n", path, current, total, amount);
    }
}
            
class HttpStaticFileServerHandler(Boolean list) extends SimpleChannelUpstreamHandler() {

    shared actual void messageReceived(ChannelHandlerContext? ctx2, MessageEvent? e2) {
        ChannelHandlerContext ctx = assertNotNull<ChannelHandlerContext>(ctx2);
        MessageEvent e = assertNotNull(e2);
        
        HttpRequest request = httpRequest(e.message);
        if (request.method != \iGET) {
            sendError(ctx, \iMETHOD_NOT_ALLOWED);
            return;
        }

        String? path2 = sanitizeUri(request.uri);
        if (!exists path2) {
            sendError(ctx, \iFORBIDDEN);
            return;
        }
        String path = assertNotNull(path2);

        File root = File("");
        File file = File(path);
        if (file.hidden || !file.\iexists() || !exists childPath(root, file)) {
            sendError(ctx, \iNOT_FOUND);
            return;
        }
        
        Channel ch = e.channel;
        ChannelFuture writeFuture;
        if (!file.file) {
            if (!file.directory || !list) {
                sendError(ctx, \iFORBIDDEN);
                return;
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
            
            // Build the response object.
            HttpResponse response = DefaultHttpResponse(\iHTTP_1_1, \iOK);
            response.content := copiedBuffer(javaString(buf.string), \iUTF_8);
            response.setHeader(\iCONTENT_TYPE, "text/html; charset=UTF-8");
    
            if (isKeepAlive(request)) {
                // Add 'Content-Length' header only for a keep-alive connection.
                response.setHeader(\iCONTENT_LENGTH, response.content.readableBytes());
            }
            
            // Write the initial line, header and content.
            writeFuture = ch.write(response);
        } else {
            RandomAccessFile raf;
            try {
                raf = RandomAccessFile(file, "r");
            } catch (FileNotFoundException fnfe) {
                sendError(ctx, \iNOT_FOUND);
                return;
            }
            Integer fileLength = raf.length();
    
            HttpResponse response = DefaultHttpResponse(\iHTTP_1_1, \iOK);
            setContentLength(response, fileLength);
    
            // Write the initial line and the header.
            ch.write(response);
    
            // Write the content.
//            if (ch.pipeline.get(SslHandler.class) != null) {
//                // Cannot use zero-copy with HTTPS.
//                writeFuture = ch.write(ChunkedFile(raf, 0, fileLength, 8192));
//            } else {
                // No encryption - use zero-copy.
                FileRegion region =
                    DefaultFileRegion(raf.channel, 0, fileLength);
                writeFuture = ch.write(region);
                writeFuture.addListener(MyChannelFutureProgressListener(region, path));
//            }
        }
        
        // Decide whether to close the connection or not.
        if (!isKeepAlive(request)) {
            // Close the connection when the whole content is written out.
            writeFuture.addListener(\iCLOSE);
        }
    }

    shared actual void exceptionCaught(ChannelHandlerContext? ctx2, ExceptionEvent? e2) {
        ChannelHandlerContext ctx = assertNotNull<ChannelHandlerContext>(ctx2);
        ExceptionEvent e = assertNotNull(e2);
        
        Channel ch = e.channel;
        Object cause = e.cause;
        if (is TooLongFrameException cause) {
            sendError(ctx, \iBAD_REQUEST);
            return;
        }

        if (is Throwable cause) {
            cause.printStackTrace();
        }
        if (ch.connected) {
            sendError(ctx,  \iINTERNAL_SERVER_ERROR);
        }
    }

    String? sanitizeUri(String orgUri) {
        // Decode the path.
        variable String uri := orgUri;
        try {
            uri := decodeUrl(uri, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            try {
                uri := decodeUrl(uri, "ISO-8859-1");
            } catch (UnsupportedEncodingException e1) {
                throw Exception();
            }
        }

        // Convert file separators.
        uri := uri.replace("/", fileSeparatorChar.string);

        // Simplistic dumb security check.
        // You will have to do something serious in the production environment.
        if (uri.contains(fileSeparator + ".") ||
            uri.contains("." + fileSeparator) ||
            uri.startsWith(".") || uri.endsWith(".")) {
            return null;
        }

        // Convert to absolute path.
        return getSystemProperty("user.dir") + fileSeparator + uri;
    }

    void sendError(ChannelHandlerContext ctx, HttpResponseStatus status) {
        HttpResponse response = DefaultHttpResponse(\iHTTP_1_1, status);
        response.setHeader(\iCONTENT_TYPE, "text/plain; charset=UTF-8");
        response.content := copiedBuffer(
                javaString("Failure: " + status.string + "\r\n"),
                \iUTF_8);

        // Close the connection as soon as the error message is sent.
        ctx.channel.write(response).addListener(\iCLOSE);
    }
}

class HttpStaticFileServerPipelineFactory(Boolean list) satisfies ChannelPipelineFactory {
    shared actual ChannelPipeline pipeline {
        // Create a default pipeline implementation.
        ChannelPipeline pipeline = createPipeline();

        // Uncomment the following line if you want HTTPS
        //SSLEngine engine = SecureChatSslContextFactory.serverContext.createSSLEngine();
        //engine.useClientMode := false;
        //pipeline.addLast("ssl", new SslHandler(engine));

        pipeline.addLast("decoder", HttpRequestDecoder());
        pipeline.addLast("aggregator", HttpChunkAggregator(65536));
        pipeline.addLast("encoder", HttpResponseEncoder());
        pipeline.addLast("chunkedWriter", ChunkedWriteHandler());

        pipeline.addLast("handler", HttpStaticFileServerHandler(list));
        return pipeline;
    }
}

void start(Integer port, Boolean list) {
    // Configure the server.
    ServerBootstrap bootstrap = ServerBootstrap(
        NioServerSocketChannelFactory(
            newCachedThreadPool(),
            newCachedThreadPool()));
  
    // Set up the event pipeline factory.
    bootstrap.pipelineFactory := HttpStaticFileServerPipelineFactory(list);
  
    // Bind and start to accept incoming connections.
    bootstrap.bind(InetSocketAddress(port));
}

void run() {
    value opts = Options {
        usage = "Usage: ceylon org.codejive.ceylon.httpd --port <portnumber> <options>";
        noArgsHelp = "use -h or --help for a list of possible options";
        Option("help", "-h|--help", "This help"),
        Option {
            name="port";
            match="-p|--port=";
            docs="The port number to run the service on";
            hasValue=true;
            required=true;
        },
        Option {
            name="list";
            match="-l|--list=";
            docs="Allows listing of directories";
        }
    };
    
    value res = opts.parse(process.arguments);
    switch(res)
    case (is OptionsResult) {
        if (res.options.containsKey("help")) {
            opts.printUsage();
            opts.printHelp();
        } else {
            value err = opts.validate(res);
            if (exists err) {
                print(err.messages);
            } else {
                Integer port = parseInteger(res.options.get("port").first) else 8080;
                Boolean list = res.options.containsKey("list");
                start(port, list);
            }
        }
    }
    case (is OptionsError) {
        print(res.messages);
    }
}

