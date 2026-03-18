module lwml.serial.Serial;

/**
This is a user-defined-attribute, meant to help determine which fields to serialize and which ones not too.  
**/

public import lwml.serial.Decode;
public import lwml.serial.Encode;

public enum Serial {none,Head16,Head32,Head64,Body16,Body32,Body64};
