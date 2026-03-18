module lwml.serial.Serializer;
import lwml.serial.Serial;
import lwml.serial.SerialBuff;
import std.conv;
import std.stdio;
import lwml.traits;

public enum Bitness:int {none,bit08,bit16,bit32,bit64};
public enum Direction:int {none,decode,encode};

public static struct Serializer(T, bool dataInHeader) {
    static if(is(T == class)) T t= new T();
    static if(is(T == struct)) T t= T();
    public static string genCode_serialHeader(bool dataInHeader, int bitness, int direction)() {
        string code= "";
        string type,et,fieldSym;
        bool decoded, encoded;
        static foreach(i, v; __traits(allMembers, T))static foreach(a; __traits(getAttributes, __traits(getMember, T, v))) {
            fieldSym= __traits(getMember, T, v).stringof;
            type= typeof(mixin("t."~v)).stringof;
            if(type[($ -2) .. $] == "[]") {
                et= type[0 .. ($ -2)];
            } else {
                et= type;
            };
            decoded= hasUDA!(__traits(getMember, T, v), Decode) || hasUDA!(__traits(getMember, T, v), Serial);
            encoded= hasUDA!(__traits(getMember, T, v), Encode) || hasUDA!(__traits(getMember, T, v), Serial);
            if(direction==Direction.decode)if(decoded) {
                switch(arrayForm!(typeof(mixin("t."~v)))) {
                    case 0:
                        if(dataInHeader)code ~= "    buff.val!"~et~"(this."~v~");   //   A '"~v~":"~et~"'.  \n";
                        break;
                    case 1:
                        if(dataInHeader)code ~= "    //   B '"~v~":"~et~"'.  \n";
                        break;
                    case 2:
                        switch(type) {
                            case "string":
                                code ~= "    char[] tmp___"~v~"= buff.allocLen!char(buff."~[null,"BYTE","WORD","DWORD","QWORD"][bitness]~");   //   C1 '"~v~":"~et~"'.  \n";
                                break;
                            case "void[]":
                                code ~= "    //   C2 '"~v~":"~et~"'.  \n";
                                ASSERT(false, "Field '"~v~"' of type 'void[]' is not supported in serial-buffers.  Use 'ubyte[]' instead.  ");
                                break;
                            default:
                                code ~= "    this."~v~"= buff.allocLen!"~et~"(buff."~[null,"BYTE","WORD","DWORD","QWORD"][bitness]~");   //   C0 '"~v~":"~et~"'.  \n";
                        };
                        break;
                    default:
                };
            };
            if(direction==Direction.encode)if(encoded) {
                switch(arrayForm!(typeof(mixin("t."~v)))) {
                    case 0:
                        if(dataInHeader)code ~= "    buff.val(this."~v~");   //   D '"~v~":"~et~"'.  \n";
                        break;
                    case 1:
                        if(dataInHeader)code ~= "    //   E '"~v~":"~et~"'.  \n";
                        break;
                    case 2:
                        code ~= "    buff."~[null,"BYTE","WORD","DWORD","QWORD"][bitness]~"= cast("~[null,"ubyte","ushort","uint","ulong"][bitness]~") this."~v~".length;   //   F '"~v~":"~et~"'.  \n";
                        break;
                    default:
                };
            };
        };
        return code;
    };
    public static string genCode_serialBody(bool dataInBody, int bitness, int direction)() {
        string code= "";
        string type,et;
        static foreach(i, v; __traits(allMembers, T))static foreach(a; __traits(getAttributes, __traits(getMember, T, v))) {
            type= typeof(mixin("t."~v)).stringof;
            if(type[($ -2) .. $] == "[]") {
                et= type[0 .. ($ -2)];
            } else {
                et= type;
            };
            if(direction==Direction.decode)switch(arrayForm!(typeof(mixin("t."~v)))) {
                case 0:
                    if(dataInBody)code ~= "    //   G '"~v~":"~et~"'.  \n";
                    break;
                case 1:
                    if(dataInBody)code ~= "    //   H '"~v~":"~et~"'.  \n";
                    break;
                case 2:
                    switch(type) {
                        case "string":
                            code ~= "    buff.arr!char(tmp___"~v~");   this."~v~"= cast(string) tmp___"~v~";   //   I1 '"~v~":"~et~"'.  \n";
                            break;
                        case "void[]":
                            code ~= "    //   I2 '"~v~":"~et~"'.  \n";
                            break;
                        default: switch(type) {
                            case "ubyte[]","byte[]","bool[]","ushort[]","short[]","char[]","uint[]","int[]","float[]","ulong[]","long[]","double[]":
                                code ~= "    buff.arr!"~et~"(this."~v~");   //   I0a '"~v~":"~et~"'.  \n";
                                break;
                            default: code ~= "    //   I0b '"~v~":"~et~"'.  Type is `"~et~"`.  \n";
                        };
                    };
                    break;
                default:
            };
            if(direction==Direction.encode)switch(arrayForm!(typeof(mixin("t."~v)))) {
                case 0:
                    if(dataInBody)code ~= "    //   J '"~v~":"~et~"'.  \n";
                    break;
                case 1:
                    if(dataInBody)code ~= "    //   N '"~v~":"~et~"'.  \n";
                    break;
                case 2:
                    switch(type) {
                        case "string":
                            code ~= "    buff.arr(this."~v~");   //   L1 '"~v~":"~et~"', the type is a string.  \n";
                            break;
                        case "void[]":
                            code ~= "    //   L2 '"~v~":"~et~"'.  \n";
                            break;
                        default:
                            if(struct_traitsOf!T.isFieldPrimitive!v)
                                code ~= "    buff.arr!"~et~"("~v~");   //   L0a '"~v~":"~et~"'.  \n";
                            else code ~= "    //   L0b '"~v~":"~et~"'.  \n";
                    };
                    break;
                default:
            };
        };
        return code;
    };
    public static string genDecoder(int bitness)() {
        string code= "";
        code ~= "public void __decode(SerialBuff!"~[null,"ubyte","ushort","uint","ulong"][bitness]~" buff) {\n    int mode= buff.mode;\n    buff.mode= buff.READ;\n";
        code ~= Serializer!(T,dataInHeader).genCode_serialHeader!(dataInHeader,bitness,Direction.decode);
        code ~= Serializer!(T,dataInHeader).genCode_serialBody!(!dataInHeader,bitness,Direction.decode);
        code ~= "    buff.mode= mode;\n};";
        return code;
    };
    public static string genEncoder(int bitness)() {
        string code= "";
        code ~= "public void __encode(SerialBuff!"~[null,"ubyte","ushort","uint","ulong"][bitness]~" buff) {\n    int mode= buff.mode;\n    buff.mode= buff.WRITE;\n";
        code ~= Serializer!(T,dataInHeader).genCode_serialHeader!(dataInHeader,bitness,Direction.encode);
        code ~= Serializer!(T,dataInHeader).genCode_serialBody!(!dataInHeader,bitness,Direction.encode);
        code ~= "    buff.mode= mode;\n};";
        return code;
    };
    public static string genCode_serial(bool dataInHeader, int bitness, int direction)() {
        string code= "";
        code ~= genCode_serialHeader!(dataInHeader,bitness,direction);
        code ~= genCode_serialBody!(!dataInHeader,bitness,direction);
        return code;
    };
};

unittest {
    import std.stdio;
    // writeln("/----- ",__MODULE__);
    struct Foo {
        public int a;
        @Serial public float b;
        @Serial public float[] c;
        mixin(Serializer!(Foo,true).genEncoder!3);
        mixin(Serializer!(Foo,true).genDecoder!3);
    };
    Foo foo= Foo();
    foo.a= 123;
    foo.b= 4.56f;
    foo.c= [7.89f, 0.12f];
    serial buff= new serial(200);
    foo.__encode(buff);
    Foo bar= Foo();
    bar.__decode(buff);
    assert(bar.a == foo.a);
    assert(bar.b == foo.b);
    assert(bar.c.length == foo.c.length);
    foreach(i; 0 .. bar.c.length)assert(bar.c[i] == foo.c[i]);
    // writeln("\\----- ",__MODULE__);
};
