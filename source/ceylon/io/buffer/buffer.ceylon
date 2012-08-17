import ceylon.io.buffer.impl { ByteBufferImpl }
shared abstract class Buffer() satisfies Iterable<Integer> {
    shared formal Integer position;
    shared formal Integer capacity;
    shared formal Integer limit;
    
    shared Boolean hasAvailable {
        return available > 0;
    }
    
    shared Integer available {
        return limit - position;
    }
    
    shared formal Integer get();
    shared formal void put(Integer byte);
    shared formal void reset();
    shared formal void clear();
    shared formal void flip();
    
    shared actual Iterator<Integer> iterator {
        object it satisfies Iterator<Integer> {
            shared actual Integer|Finished next() {
                if(hasAvailable){
                    return get();
                }
                return exhausted;
            }
        }
        return it;
    } 
}

shared Buffer newByteBuffer(Integer capacity){
    return ByteBufferImpl(capacity);
}

shared Buffer newByteBufferWithData(Integer... bytes){
    value seq = bytes.sequence;
    value buf = newByteBuffer(seq.size);
    for(Integer byte in seq){
        buf.put(byte);
    }
    buf.flip();
    return buf;
}
