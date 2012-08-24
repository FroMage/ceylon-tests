import ceylon.io.buffer { newByteBuffer, ByteBuffer, newCharacterBufferWithData, CharacterBuffer }
import ceylon.io.charset { Charset, Decoder, Encoder }
import ceylon.io.impl { SocketImpl, SelectorImpl }

import java.net { InetSocketAddress }
import java.nio.channels { SocketChannel { openSocket=open } }

shared interface Selector {
    shared formal void process();
    shared formal void addConsumer(FileDescriptor socket, Boolean callback(FileDescriptor s));
    shared formal void addProducer(FileDescriptor socket, Boolean callback(FileDescriptor s));
}

shared abstract class FileDescriptor() {

    shared formal Integer read(ByteBuffer buffer);
    
    shared void readFully(void consume(ByteBuffer buffer), ByteBuffer buffer = newBuffer()){
        // FIXME: should we allocate the buffer ourselves?
        // FIXME: should we clear the buffer passed?
        // I guess not, because there might be something left by the consumer at the beginning that we don't want to override?
        // FIXME: should we check that the FD is in blocking mode? 
        while(read(buffer) >= 0){
            buffer.flip();
            consume(buffer);
            // FIXME: should we clear the buffer or should the consumer do it?
            // I suppose the consumer should do it, because he might find it convenient to leave something that he couldn't consume?
            // In which case we should probably not try to read if the buffer is still full?
            // OTOH we could require him to consume it all
            buffer.clear();
        }
    }
    
    shared void readAsync(Selector selector, void consume(ByteBuffer buffer), ByteBuffer buffer = newBuffer()){
        setNonBlocking();
        Boolean readData(FileDescriptor socket){
            buffer.clear();
            if(socket.read(buffer) >= 0){
                buffer.flip();
                // FIXME: should the consumer be allowed to stop us?
                print("Calling consumer");
                consume(buffer);
                return true;
            }else{
                // EOF
                return false;
            }
        }
        selector.addConsumer(this, readData);
    }
    
    shared formal Integer write(ByteBuffer buffer);

    shared void writeFully(ByteBuffer buffer){
        while(buffer.hasAvailable
            && write(buffer) >= 0){
            print("Wrote total bytes: " buffer.position ", remaining: " buffer.available "");
        }
    }
    
    shared void writeFrom(void producer(ByteBuffer buffer), ByteBuffer buffer = newBuffer()){
        // refill
        while(true){
            // fill our buffer
            producer(buffer);
            // flip it for reading
            buffer.flip();
            if(!buffer.hasAvailable){
                // EOI
                return;
            }
            writeFully(buffer);
            buffer.clear();
        }
    }
    
    shared void writeAsync(Selector selector, void producer(ByteBuffer buffer), ByteBuffer buffer = newBuffer()){
        setNonBlocking();
        variable Boolean needNewData := true;
        Boolean writeData(FileDescriptor socket){
            // get new data if we ran out
            if(needNewData){
                buffer.clear();
                producer(buffer);
                // flip it for reading
                buffer.flip();
                if(!buffer.hasAvailable){
                    // EOI
                    return false;
                }
                needNewData := false;
            }
            // try to write it
            if(socket.write(buffer) >= 0){
                // did we manage to write everything?
                needNewData := !buffer.hasAvailable;
                return true;
            }else{
                // EOF
                return false;
            }
        }
        selector.addProducer(this, writeData);
    }

    shared formal void close();
    shared formal void setNonBlocking();
    
    ByteBuffer newBuffer() {
        return newByteBuffer(4096);
    }
}

shared class SocketAddress(address, port) {
    shared String address;
    shared Integer port;
}

shared class SocketConnector(SocketAddress addr){
    shared Socket connect(){
        value channel = openSocket(InetSocketAddress(addr.address, addr.port));
        return SocketImpl(channel);
    }
}

shared Selector newSelector(){
    return SelectorImpl();
}

shared abstract class Socket() extends FileDescriptor(){
}


