import ceylon.io.buffer { newByteBuffer, newByteBufferWithData }
import ceylon.io.charset { Charset, utf8 }

void testDecoder(Charset charset, String expected, Integer... bytes){
    // we put it in a buffer of 2 so we can test multiple calls to decode
    // with 3-4 byte chars split between buffers
    value buf = newByteBuffer(2);
    value iter = bytes.iterator;
    value decoder = utf8.newDecoder();
    
    while(true){
        // put as much as fits
        while(buf.hasAvailable){
            if(is Integer byte = iter.next()){
                buf.put(byte);
            }else{
                break;
            }
        }
        if(buf.position == 0){
            break;
        }
        buf.flip();
        decoder.decode(buf);
        buf.clear();
    }
    assertEquals(expected, decoder.done());
    print("Decoded " expected " OK");
}


void testUTF8Decoder(){
    // samples from http://en.wikipedia.org/wiki/UTF-8
    // hexa: 24
    testDecoder(utf8, "$", 36);
    // hexa: C2 A2
    testDecoder(utf8, "¢", 194, 162);
    // hexa: E2 82 AC
    testDecoder(utf8, "€", 226, 130, 172);
    // hexa: F0 A4 AD A2
    testDecoder(utf8, "𤭢", 240, 164, 173, 162);

    value buffer = newByteBufferWithData(36, 194, 162, 226, 130, 172, 240, 164, 173, 162);
    assertEquals("$¢€𤭢", utf8.decode(buffer));
}