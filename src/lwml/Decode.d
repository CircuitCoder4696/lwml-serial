module lwml.serial.Decode;

/**
This is a user-defined-attribute, meant to help determine which fields to serialize and which ones not too.  
**/

public enum Decode {none,Head16,Head32,Head64,Body16,Body32,Body64};
