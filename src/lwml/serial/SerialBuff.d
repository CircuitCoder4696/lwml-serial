module lwml.serial.SerialBuff;
import impl.memory;
import impl.lwml.Console;
import impl.lwml.Conv;
import lwml.core;
import lwml.serial.Serializable;

public class SerialBuff(AddrT=uint) {
    public static size_t getTotalSize(SerialBuff self) {
        return BuffImpl.buff(self.memoryIdentity).size;
    };
    public bool keepLogical= true;
    public int mode;
    public enum:int {none,READ,WRITE};
    private uint memoryIdentity;
    public this(uint size, string modulePath= __MODULE__) {
        assert(!__ctfe, "Serial-buffers cannot be used at compile-time.  The constructor is being called from "~modulePath~".  ");
        this.mode= WRITE;
        this.memoryIdentity= BuffImpl(size).identity;
    };
    public this(void[] data) {
        this.mode= READ;
        this.memoryIdentity= BuffImpl(cast(void[]) data).identity;
    };
    public ulong reader()@property=> BuffImpl.buff(this.memoryIdentity).reader;
    public void reader(ulong val)@property { BuffImpl.buff(this.memoryIdentity).reader= val; };
    public ulong writer()@property=> BuffImpl.buff(this.memoryIdentity).writer;
    public void writer(ulong val)@property { BuffImpl.buff(this.memoryIdentity).writer= val; };
    public void[] content()@property {
        void[] result= BuffImpl.buff(this.memoryIdentity).content();
        BuffImpl.buff(this.memoryIdentity).reader= BuffImpl.buff(this.memoryIdentity).writer;
        return result;
    };
    public T gVal(T)(ref T v) {
        T* ptr= BuffImpl.buff(this.memoryIdentity).readPtr!T;
        v= *ptr;
        return v;
    };
    public T sVal(T)(ref T v) {
        T* ptr= BuffImpl.buff(this.memoryIdentity).writePtr!T;
        *ptr= v;
        return v;
    };
    public T val(T)(ref T v) {
        switch(this.mode) {
            case READ:
                this.gVal(v);
                break;
            case WRITE:
                this.sVal(v);
                break;
            default:
        };
        return v;
    };
    public T[] arr(T)(ref T[] d) {
        switch(this.mode) {
            case READ:
                if(this.keepLogical) assert((BuffImpl.buff(this.memoryIdentity).reader + d.length * T.sizeof) <= BuffImpl.buff(this.memoryIdentity).size, "You're not allowed to read data past the data itself.  ");
                (cast(void[]) d)[0 .. $]= BuffImpl.buff(this.memoryIdentity).read(d.length * T.sizeof);
                return d;
            case WRITE:
                BuffImpl.buff(this.memoryIdentity).write(cast(void[]) d);
                break;
            default:
        };
        return d;
    };
    public string arr(T)(ref string d) {
        switch(this.mode) {
            case READ:
                size_t s= d.length;
                (cast(void[]) this.data[this.reader .. (this.reader + s)])= cast(void[]) d[];
                this.reader += s;
                return d;
            case WRITE:
                break;
            default:
        };
        return d;
    };
    public void voidArr(T)(ref T size, ref void[] data) {
        switch(this.mode) {
            case READ:
                data= GC.malloc(size)[0 .. size];
                this.arr(data);
                break;
            case WRITE:
                this.arr(data);
                size= cast(T) BuffImpl.buff(this.memoryIdentity).size;
                break;
            default:
        };
        return d;
    };
    public T[] allocLen(T= void)(uint len) {
        ulong es= T.sizeof;
        assert((len * es) <= (BuffImpl.buff(this.memoryIdentity).size - BuffImpl.buff(this.memoryIdentity).reader), "You've just been caught, the buffer's allocator is to allocate arrays to deserialize data into, not for making arrays for the sake of it.  This just stopped you from making a giant-array by accident.  ");
        static if(is(T == void))es= 1;
        void[] result= GC.malloc((cast(ulong) len) * es)[0 .. (cast(ulong) len) * es];
        return cast(T[]) result;
    };
    public void[] alloc(size_t size) {
        void[] result= GC.malloc(size)[0 .. size];
        return result;
    };
    public void allocLen(T= void)(ref T[] field, ref uint len) {
        switch(this.mode) {
            case READ:
                ulong es= T.sizeof;
                static if(is(T == void))es= 1;
                void[] result= GC.malloc((cast(ulong) len) * es)[0 .. (cast(ulong) len) * es];
                field= cast(T[]) result;
                break;
            case WRITE:
                len= field.length;
                break;
            default:
        };
    };
    public void arrLen(L= AddrT, T)(ref T[] d) {
        switch(this.mode) {
            case READ:
                d.length= cast(size_t) *(cast(L*) BuffImpl.buff(this.memoryIdentity).readPtr!L);
                return;
            case WRITE:
                *(BuffImpl.buff(this.memoryIdentity).writePtr!L)= cast(L) d.length;
                return;
            default:
        };
        assert(0);
    };
    public void arrSize(S= AddrT, T)(ref T[] d) {
        switch(this.mode) {
            case READ:
                d.length= cast(size_t) *(BuffImpl.buff(this.memoryIdentity).readPtr!S) / T.sizeof;
                return;
            case WRITE:
                *(BuffImpl.buff(this.memoryIdentity).writePtr!S)= cast(S) (d.length * T.sizeof);
                return;
            default:
        };
        assert(0);
    };
    public int setOpcode(int opcode) {
        return cast(int) *(BuffImpl.buff(this.memoryIdentity).writePtr!int);
    };
    public ubyte BYTE()@property {
        ubyte result;
        this.gVal(result);
        return result;
    };
    public void BYTE(ubyte value)@property {
        this.sVal(value);
    };
    public ushort WORD()@property {
        ushort result;
        this.gVal(result);
        return result;
    };
    public void WORD(ushort value)@property {
        this.sVal(value);
    };
    public uint DWORD()@property {
        uint result;
        this.gVal(result);
        return result;
    };
    public void DWORD(uint value)@property {
        this.sVal(value);
    };
    public ulong QWORD()@property {
        ulong result;
        this.gVal(result);
        return result;
    };
    public void QWORD(ulong value)@property {
        this.val(value);
    };
    public string hexString()@property @trusted {
        char[] result= new char[0];
        if(BuffImpl.buff(this.memoryIdentity).reader == BuffImpl.buff(this.memoryIdentity).writer)return cast(string) result;
        result.length += 2;
        result ~= Conv.hexOf(*(BuffImpl.buff(this.memoryIdentity).readPtr!ubyte));
        if((BuffImpl.buff(this.memoryIdentity).reader - BuffImpl.buff(this.memoryIdentity).writer) == 1)return cast(string) result;
        BuffImpl buff= BuffImpl.buff(this.memoryIdentity);
        foreach(i; (buff.reader +1) .. buff.writer) {
            result ~= "_"~Conv.hexOf(*(buff.readPtr!ubyte));
        };
        return cast(string) result;
    };
};

public alias serial16= SerialBuff!ushort;
public alias serial32= SerialBuff!uint;
public alias serial64= SerialBuff!ulong;
public alias serial= serial32;
