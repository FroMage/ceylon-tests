import java.nio { JavaByteBuffer = ByteBuffer { allocateJavaByteBuffer = allocate }}
import ceylon.io.buffer { ByteBuffer }

Boolean needsWorkarounds = true;

shared class ByteBufferImpl(Integer initialCapacity) extends ByteBuffer(){
    variable JavaByteBuffer buf := allocateJavaByteBuffer(initialCapacity);
    shared JavaByteBuffer underlyingBuffer {
        return buf;
    }
    
    shared actual Integer capacity {
        return buf.capacity();
    }
    shared actual Integer limit {
        return buf.limit();
    }
    shared actual Integer position {
        return buf.position();
    }
    shared actual Integer get() {
        return signedByteToUnsigned(buf.get());
    }
    shared actual void put(Integer byte) {
        buf.put(unsignedByteToSigned(byte));
    }
    shared actual void clear() {
        buf.clear();
    }
    shared actual void flip() {
        buf.flip();
    }
    Integer signedByteToUnsigned(Integer b) { 
        if(needsWorkarounds && b < 0){
            return b + 256;
        }
        return b;
    }
    
    Integer unsignedByteToSigned(Integer b) { 
        if(needsWorkarounds && b > 127){
            return b - 256;
        }
        return b;
    }
    
    shared actual void resize(Integer newSize) {
        if(newSize == capacity){
            return;
        }
        if(newSize < 0){
            // FIXME: type
            throw;
        }
        JavaByteBuffer dest = allocateJavaByteBuffer(newSize);
        // save our position and limit
        value position = min({this.position, newSize});
        value limit = min({this.limit, newSize});
        // copy everything unless we shrink
        value copyUntil = min({this.capacity, newSize});
        // prepare our limits for copying
        buf.position(0);
        buf.limit(copyUntil);
        // copy
        dest.put(buf);
        // change buffer
        buf := dest;
        // now restore positions
        buf.limit(limit);
        buf.position(position);
    }
}

