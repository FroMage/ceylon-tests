import ceylon.io { Selector, Socket, FileDescriptor }
import java.nio.channels { 
    JavaSelector = Selector { javaOpenSelector = open },
    SelectionKey { 
        javaReadOp = \iOP_READ,
        javaWriteOp = \iOP_WRITE
    } 
}
import ceylon.collection { HashMap, MutableMap }

shared class SelectorImpl() satisfies Selector {
    
    JavaSelector javaSelector = javaOpenSelector();
    class Key(onRead, onWrite, socket) {
        shared variable Callable<Boolean, FileDescriptor>? onRead;
        shared variable Callable<Boolean, FileDescriptor>? onWrite;
        shared Socket socket;
    }
    MutableMap<SelectionKey, Key> map = HashMap<SelectionKey, Key>();
    
    shared actual void addConsumer(FileDescriptor socket, Boolean callback(FileDescriptor s)) {
        if(is SocketImpl socket){
            SelectionKey? javaKey = socket.channel.keyFor(javaSelector);
            if(exists javaKey){
                value key = map[javaKey];
                if(exists key){
                    // update our key
                    key.onRead := callback;
                    javaKey.interestOps(javaKey.interestOps().or(javaReadOp));
                }else{
                    throw;
                }
            }else{
                // new key
                value key = Key(callback, null, socket);
                value newJavaKey = socket.channel.register(javaSelector, javaReadOp, key);
                map.put(newJavaKey, key);
            }
        }else{
            throw;
        }
    }

    shared actual void addProducer(FileDescriptor socket, Boolean callback(FileDescriptor s)) {
        if(is SocketImpl socket){
            SelectionKey? javaKey = socket.channel.keyFor(javaSelector);
            if(exists javaKey){
                value key = map[javaKey];
                if(exists key){
                    // update our key
                    key.onWrite := callback;
                    javaKey.interestOps(javaKey.interestOps().or(javaWriteOp));
                }else{
                    throw;
                }
            }else{
                // new key
                value key = Key(null, callback, socket);
                value newJavaKey = socket.channel.register(javaSelector, javaWriteOp, key);
                map.put(newJavaKey, key);
            }
        }else{
            throw;
        }
    }

    shared actual void process() {
        while(!map.empty){
            print("Select! with " javaSelector.keys().size() " keys ");
            javaSelector.select();
            // process results
            print("Got " javaSelector.selectedKeys().size() " selected keys");
            value it = javaSelector.selectedKeys().iterator();
            while(it.hasNext()){
                value selectedKey = it.next();
                if(is Key key = selectedKey.attachment()){
                    if(selectedKey.valid && selectedKey.readable){
                        if(exists callback = key.onRead){
                            // backend bug https://github.com/ceylon/ceylon-compiler/issues/733
                            value cb = callback;
                            value goOn = cb(key.socket);
                            print("Do we keep it for reading? " goOn "");
                            if(!goOn){
                                // are we still writing?
                                if(exists key.onWrite){
                                    // drop the reading bits
                                    print("Dropping read interest");
                                    selectedKey.interestOps(javaWriteOp);
                                    key.onRead := null;
                                }else{
                                    print("Cancelling key");
                                    selectedKey.cancel();
                                    map.remove(selectedKey);
                                }
                            }
                        }else{
                            throw;
                        }
                    }
                    if(selectedKey.valid && selectedKey.writable){
                        if(exists callback = key.onWrite){
                            // backend bug https://github.com/ceylon/ceylon-compiler/issues/733
                            value cb = callback;
                            value goOn = cb(key.socket);
                            print("Do we keep it for writing? " goOn "");
                            if(!goOn){
                                // are we still reading?
                                if(exists key.onRead){
                                    // drop the reading bits
                                    print("Dropping write interest");
                                    selectedKey.interestOps(javaReadOp);
                                    key.onWrite := null;
                                }else{
                                    print("Cancelling key");
                                    selectedKey.cancel();
                                    map.remove(selectedKey);
                                }
                            }
                        }else{
                            throw;
                        }
                    }
                }else{
                    throw;
                }
            }
        }
    }
}
