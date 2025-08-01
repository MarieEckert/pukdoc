# PµK Syscall Interface
## 0. Introduction

Syscalls are the main interface with which a user-space program can talk to
the kernel. The syscall interface which PµK provides is intended to be slim
and simple. It is focused on filesystem interactions and process management.

## 1. Syscall Listing

1. ordered list test
2. second item
  - note on the second item
3. third item

1) second ordered list test
2) enough

* bullet list (stars)
  * sub bullet
* another thing

- bullet list (dashes)
  - sub bullet
- enough

Preliminary list of syscalls.
```
  Files/Filesystem
    I/O
      $00 open(String path, TFileMode mode)
      $01 close(int fd)
          tclose(int fd, int status)
      $02 read(int fd, PBytes dest, int amount)
      $03 write(int fd, PBytes src, int amount)
      $04 seek(int fd, int offset, TSeekOption option)

    Metadata
      $05 stat(String path, PStat dest)
      $06 write_stat(String path, PStat data)
      $07 fstat(int fd, PStat dest)
      $08 fwrite_stat(int fd, PStat data)

    Other
      $09 remove(String path)
      $0a path(int fd, PString dest) - get path of filedescriptor
      $0b chdir(String dir)

  Namespaces
    $0c mount
    $0d unmount
    $0e bind

  Process Management
    $0f fork
    $10 exec(String name, ^String args)
    $11 exit(int code)

  IPC
    $12 pipe(int fd1, int fd2)

  Memory Management
    $13 pmap(ulong addr, ulong size, int flags)
    $14 fmap(ulong addr, ulong size, int flags, int fd)
```

## 2. Syscall Specification
### 2.1. Calling Convetion

| ARCH  | ID  | return  | arg1 | arg2 | arg3 | arg4 | arg5 | arg6  |
| ----- | --- | ------- | ---- | ---- | ---- | ---- | ---- | ----- |
| x64   | rax | rax:rdx | rdi  | rsi  | rdx  | rcx  | r8   | r9    |

The values for the parameters are usually directly within the appropriate
registers. In case a parameter does not fit, like a String or a record type,
the direct address to the value is expected.

### 2.2. Datatypes

```
  "String"
    The String datatype is a structured, or "fat", datatype containing metadata
    about it. This String datatype corresponds to the AnsiString type from
    freepascal.

    When a String is passed as an argument, the pointer that is actually passed
    should point to the first character in the String.

      TODO: explain exactly why this is done. the main reason is that you would
            have to write `@myString[1] - sizeof(TAnsiRec)` instead of simply
            `@myString[1]`.
            NOTE: `@myString` gives a pointer to a pointer. String types are
                  also just pointer types. This would mean that we would have to
                  translate two addresses (yuck).

    For clarity this document also contains the structure of such an AnsiString:

      In essence, an AnsiString is just a C-Style String prefixed with a
      metadata/header record. This record type is defined as follows:

        type
          TAnsiRec = record
            CodePage    : TSystemCodePage; { Type alias to datatype `UInt16` }
            ElementSize : UInt16;
          {$ifdef CPU64}
            Dummy       : UInt32; { used for alignment on 64 bit cpus }
          {$endif}
            Ref         : UInt64;
            Len         : UInt64;
          end;

  "TFileMode"
    The TFileMode type is a set type of the TFileModeFlags enumeration.

    Declaration:

      type
        TFileModeFlag = (fmfRead, fmfWrite, fmfExec, fmfTrunc);
        TFileMode = set of TFileModeFlag;

    The fmfRead and fmfWrite flags ask for read and write permissions
    respectively, both can be set at the same time to request read and write
    permissions. The fmfExec flag can be set to open the file with the
    permissions to execute it. The fmfTrunc flag says to truncate the file to
    zero-length before openiong it. The fmfTrunc and fmfExec flags are mutually
    exclusive.

  "TSeekOption"
    The TSeekOption type is an enumeration.

    Declaration:

      type
        TSeekOption = (soBegin, soEnd, soPos);

    The soBegin option says that the seek should be executed relative to the
    first byte of the file, the soEnd option says that it should be relative to
    the end of the file, the soPos option says that it should be relative to the
    current position in the file.

  "PStat" / "TStat"
    The PStat type is the pointer type for the TStat record type. This record
    type is used to store all metadata about a file which the kernel supports
    and is stored on the file system. If executed on an open file it also gives
    metadata specific to the file descriptor.

    Declaration:

      type
        { TODO: This is pulled out of my ass, need feedback! }
        TStat = record
          size       : UInt64; { total filesize in bytes }
          createTime : UInt64; { creation time }
          modTime    : UInt64; { last modification time }
          accTime    : UInt64; { last access time }
          mode       : TMode; { TODO!!! essentially file permissions }
          { owner information goes here, if we have some user concept }
          { todo: further metadata? }
        end;

        PStat = ^TStat;
```

### 2.3. Return Values

PµK specifies a number of return values/status codes for completed syscalls.
Status codes which have their highest bit set (this can be interpreted as a
negative signed integer) are exclusively used for errors.

| VALUE | NAME       | DESCRIPTION                                              |
| ----- | ---------- | -------------------------------------------------------- |
| $0000 | Ok         | Success                                                  |
| $8001 | NoEntry    | No such file or directory                                |
| $8002 | Busy       | File/Resource is busy/cant handle operations currently   |
| $8003 | TimeOut    | The operation took to long and was aborted               |
| $8004 | InvalidArg | One of the provided arguments was invalid                |
| $8005 | NotOpen    | The given descriptor does not reference an open resource |
