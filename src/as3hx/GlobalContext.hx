package as3hx;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.collection.SynchronizedArray;
import as3hx.As3.Program;
import hx.concurrent.thread.ThreadPool;
import concurrent.ConcurrentMap;
import sys.io.File;
import sys.FileSystem;
using haxe.io.Path;
using StringTools;

class GlobalContext {

    var cfg:Config;
    var threadPool:ThreadPool;
    var errors:SynchronizedArray<String> = new SynchronizedArray();
    var warnings:ConcurrentMap<String, Map<String, Bool>> = new ConcurrentMap();
    var programs:SynchronizedArray<Program> = new SynchronizedArray();
    var imports:SynchronizedArray<Program> = new SynchronizedArray();
    var lookup:Lookup;

    public function new(config:Config) {
        cfg = config;
        Sys.println("Thread pool size: " + cfg.threadPoolSize);
        threadPool = new ThreadPool(cfg.threadPoolSize);
    }

    public function parse():String {
        for (path in cfg.importPaths) {
            if (FileSystem.exists(path)) {
                walk(path, cfg.dst, imports);
            }
        }
        walk(cfg.src, cfg.dst, programs);
        threadPool.awaitCompletion(-1);
        return "Parsed";
    }

    public function process():String {
        lookup = new Lookup(cfg);
        for (program in programs) {
            threadPool.submit(function(_) {
                lookup.process(program);
            });
        }
        for (p in imports) {
            threadPool.submit(function(_) {
                lookup.process(p);
            });
        }
        threadPool.awaitCompletion(-1);
        return "Processed";
    }

    public function write():String {
        var written:AtomicInt = new AtomicInt(0);
        var pool:ThreadPool = new ThreadPool(cfg.threadPoolSize);
        for (program in programs) {
            threadPool.submit(function(_) {
                Utils.ensureDirectoryExists(program.dst);
                writeProgram(program);
                written++;
            });
        }
        threadPool.awaitCompletion(-1);

        printWarningsAndErrors();

        return "Written " + written + "/" + programs.length + " files";
    }

    private function walk(src:String, dst:String, list:SynchronizedArray<Program>) {
        if (src == null) {
            Sys.println("source path cannot be null");
        }
        if (dst == null) {
            Sys.println("destination path cannot be null");
        }
        src = src.normalize();
        dst = dst.normalize();
        var subDirList = new Array<String>();
        for(f in FileSystem.readDirectory(src)) {
            var srcChildAbsPath = src.addTrailingSlash() + f;
            if (FileSystem.isDirectory(srcChildAbsPath)) {
                subDirList.push(f);
            } else if(f.endsWith(".as") && !Utils.isExcludeFile(cfg.excludePaths, srcChildAbsPath)) {
                threadPool.submit(function(ctx:ThreadContext) {
                    parseFile(src, dst, f, list);
                });
            }
        }
        for (name in subDirList) {
            walk((src.addTrailingSlash() + name), (dst.addTrailingSlash() + name), list);
        }
    }

    private function parseFile(src:String, dst:String, f:String, list:SynchronizedArray<Program>) {
        var srcChildAbsPath = src.addTrailingSlash() + f;
        var file = srcChildAbsPath;
        Sys.println("parsing AS3 file: " + file);
        var p = new Parser(cfg);
        var content = File.getContent(file);
        var program = try p.parseString(content, src, f, dst) catch(e : Error) {
            if(cfg.errorContinue) {
                errors.add("In " + file + "(" + p.tokenizer.line + ") : " + Utils.errorString(e));
                return;
            } else {
                neko.Lib.rethrow("In " + file + "(" + p.tokenizer.line + ") : " + Utils.errorString(e));
            }
        }
        program.dst = dst;
        list.add(program);
    }

    private function writeProgram(program:Program) {
        var writer = new Writer(cfg, lookup);
        var name = program.dst.addTrailingSlash() + Writer.properCase(program.filename.substr(0, -3), true) + ".hx";
        Sys.println("writing HX file: " + name);
        var fw = File.write(name, false);
        warnings.set(name, writer.process(program, fw));
        fw.close();
        if(cfg.postProcessor != "") {
            postProcessor(cfg.postProcessor, name);
        }
        if(cfg.verifyGeneratedFiles) {
            verifyGeneratedFile(program.filename, program.dst, name);
        }
    }

    static function postProcessor(?postProcessor:String = "", ?outFile:String = "") {
        if(postProcessor != "" && outFile != "") {
            Sys.println('Running post-processor ' + postProcessor + ' on file: ' + outFile);
            if (postProcessor.indexOf(" ") > -1) {
                var args = postProcessor.split(" ");
                var cmd = args.shift();
                args.push(outFile);
                Sys.command(cmd, args);
            } else {
                Sys.command(postProcessor, [outFile]);
            }
        }
    }

    //if a .hx file with the same name as the .as file is found in the .as
    //file directory, then it is considered the expected output of the conversion
    //and is diffed against the actual output
    static function verifyGeneratedFile(file:String, src:String, outFile:String) {
        var test = src.addTrailingSlash() + Writer.properCase(file.substr(0, -3), true) + ".hx";
        if (FileSystem.exists(test) && FileSystem.exists(outFile)) {
            Sys.println("expected HX file: " + test);
            var expectedFile = File.getContent(test);
            var generatedFile = File.getContent(outFile);
            if (generatedFile != expectedFile) {
                Sys.println('Don\'t match generated file:' + outFile);
                Sys.command('diff', [test, outFile]);
            }
        }
    }

    private function printWarningsAndErrors() {
        var wke : Map<String,Array<String>> = new Map(); // warning->files
        for(filename in warnings.keys()) {
            for(errname in warnings.get(filename).keys()) {
                var a = wke.get(errname);
                if(a == null) a = [];
                a.push(filename);
                wke.set(errname,a);
            }
        }
        var println = Sys.println;
        for(warn in wke.keys()) {
            var a = wke.get(warn);
            if(a.length > 0) {
                switch(warn) {
                    case "EE4X": println("ERROR: The following files have xml notation that will need porting. See http://haxe.org/doc/advanced/xml_fast");
                    case "EXML": println("WARNING: There is XML that may not have translated correctly in these files:");
                    case "Vector.<T>": println("FATAL: These files have a Vector.<T> call, which was not handled. Check versus source file!");
                    case "ETypeof": println("WARNING: These files use flash 'typeof'. as3hx.Compat is required, or recode http://haxe.org/doc/cross/reflect");
                    case "as Class": println("WARNING: These files casted using 'obj as Class', which may produce incorrect code");
                    case "as number", "as int": println("WARNING: "+warn+" casts in these files");
                    case "as array": println("ERROR: type must be determined for 'as array' cast for:");
                    case "EDelete": println("FATAL: Files will not compile due to 'delete' keyword. See README");
                    default: println("WARNING: " + warn);
                }
                for(f in a)
                    println("\t"+f);
            }
        }
        if(errors.length > 0) {
            Sys.println("ERRORS: These files were not written due to source parsing errors:");
            for(i in errors)
                Sys.println(i);
        }
    }

}
