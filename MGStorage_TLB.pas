unit MGStorage_TLB;

// ************************************************************************ //
// WARNING
// -------
// The types declared in this file were generated from data read from a
// Type Library. If this type library is explicitly or indirectly (via
// another type library referring to this type library) re-imported, or the
// 'Refresh' command of the Type Library Editor activated while editing the
// Type Library, the contents of this file will be regenerated and all
// manual modifications will be lost.
// ************************************************************************ //

// $Rev: 52393 $
// File generated on 12/26/2017 2:42:34 PM from Type Library described below.

// ************************************************************************  //
// Type Lib: D:\Down\MGStorage\MGStorage (1)
// LIBID: {B5DCF7D2-F32B-41B6-8438-DEEF84C467CC}
// LCID: 0
// Helpfile:
// HelpString:
// DepndLst:
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers.
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, System.Classes, System.Variants, System.Win.StdVCL, Vcl.Graphics, Vcl.OleServer, Winapi.ActiveX;


// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:
//   Type Libraries     : LIBID_xxxx
//   CoClasses          : CLASS_xxxx
//   DISPInterfaces     : DIID_xxxx
//   Non-DISP interfaces: IID_xxxx
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  MGStorageMajorVersion = 1;
  MGStorageMinorVersion = 0;

  LIBID_MGStorage: TGUID = '{B5DCF7D2-F32B-41B6-8438-DEEF84C467CC}';

  IID_IConnection: TGUID = '{47F0971A-9C54-4CBF-85A9-87B106485CA8}';
  DIID_IConnectionEvents: TGUID = '{21735F7D-3731-48A5-BC8F-8901B72B73E2}';
  CLASS_Connection: TGUID = '{3254ED36-DDE9-4C1D-BFA4-7D59CE38C38E}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary
// *********************************************************************//
  IConnection = interface;
  IConnectionDisp = dispinterface;
  IConnectionEvents = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library
// (NOTE: Here we map each CoClass to its Default Interface)
// *********************************************************************//
  Connection = IConnection;


// *********************************************************************//
// Interface: IConnection
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {47F0971A-9C54-4CBF-85A9-87B106485CA8}
// *********************************************************************//
  IConnection = interface(IDispatch)
    ['{47F0971A-9C54-4CBF-85A9-87B106485CA8}']
    function Get_ConnectionString: WideString; safecall;
    procedure Set_ConnectionString(const Value: WideString); safecall;
    procedure Connect; safecall;
    function Get_Connected: WordBool; safecall;
    function Get_SupportsContainers: WordBool; safecall;
    function ContainerExists(const Container: WideString): WordBool; safecall;
    procedure CreateContainer(const Container: WideString); safecall;
    function GetContainerList: Integer; safecall;
    function GetContainerName(Index: Integer): WideString; safecall;
    procedure SelectContainer(const Container: WideString); safecall;
    function GetFileList(const Path: WideString; const Mask: WideString; IncludeSubfolders: WordBool): LongWord; safecall;
    function GetContainerCount: Integer; safecall;
    function GetFileCount: Integer; safecall;
    function GetFileName(Index: Integer): WideString; safecall;
    function GetFileFullPath(Index: Integer): WideString; safecall;
    function GetFileSize(Index: Integer): LongWord; safecall;
    function GetFileDate(Index: Integer): TDateTime; safecall;
    function IsFile(Index: Integer): WordBool; safecall;
    function GetFolder: WideString; safecall;
    procedure SetFolder(const Folder: WideString); safecall;
    procedure DeleteFolder(const Folder: WideString; Recursive: WordBool); safecall;
    function FileExists(const StorageFilename: WideString): WordBool; safecall;
    procedure GetFile(const Storagefilename: WideString; const DestLocalFilename: WideString); safecall;
    procedure PutFile(const Localfilename: WideString; const DestStorageFilename: WideString); safecall;
    procedure DeleteFile(const Storagefilename: WideString); safecall;
    procedure RenameFile(const StorageFilenameOld: WideString; const StorageFilenameNew: WideString); safecall;
    procedure CopyFile(const StorageFilenameOld: WideString; const StorageFilenameNew: WideString); safecall;
    function GetProperty(const Key: WideString): WideString; safecall;
    procedure SetProperty(const Key: WideString; const Value: WideString); safecall;
    function GetPath(const StorageFilename: WideString): WideString; safecall;
    property ConnectionString: WideString read Get_ConnectionString write Set_ConnectionString;
    property Connected: WordBool read Get_Connected;
    property SupportsContainers: WordBool read Get_SupportsContainers;
  end;

// *********************************************************************//
// DispIntf:  IConnectionDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {47F0971A-9C54-4CBF-85A9-87B106485CA8}
// *********************************************************************//
  IConnectionDisp = dispinterface
    ['{47F0971A-9C54-4CBF-85A9-87B106485CA8}']
    property ConnectionString: WideString dispid 201;
    procedure Connect; dispid 202;
    property Connected: WordBool readonly dispid 203;
    property SupportsContainers: WordBool readonly dispid 204;
    function ContainerExists(const Container: WideString): WordBool; dispid 205;
    procedure CreateContainer(const Container: WideString); dispid 206;
    function GetContainerList: Integer; dispid 207;
    function GetContainerName(Index: Integer): WideString; dispid 208;
    procedure SelectContainer(const Container: WideString); dispid 209;
    function GetFileList(const Path: WideString; const Mask: WideString; IncludeSubfolders: WordBool): LongWord; dispid 210;
    function GetContainerCount: Integer; dispid 211;
    function GetFileCount: Integer; dispid 212;
    function GetFileName(Index: Integer): WideString; dispid 213;
    function GetFileFullPath(Index: Integer): WideString; dispid 214;
    function GetFileSize(Index: Integer): LongWord; dispid 215;
    function GetFileDate(Index: Integer): TDateTime; dispid 216;
    function IsFile(Index: Integer): WordBool; dispid 217;
    function GetFolder: WideString; dispid 218;
    procedure SetFolder(const Folder: WideString); dispid 219;
    procedure DeleteFolder(const Folder: WideString; Recursive: WordBool); dispid 220;
    function FileExists(const StorageFilename: WideString): WordBool; dispid 221;
    procedure GetFile(const Storagefilename: WideString; const DestLocalFilename: WideString); dispid 222;
    procedure PutFile(const Localfilename: WideString; const DestStorageFilename: WideString); dispid 223;
    procedure DeleteFile(const Storagefilename: WideString); dispid 224;
    procedure RenameFile(const StorageFilenameOld: WideString; const StorageFilenameNew: WideString); dispid 225;
    procedure CopyFile(const StorageFilenameOld: WideString; const StorageFilenameNew: WideString); dispid 226;
    function GetProperty(const Key: WideString): WideString; dispid 227;
    procedure SetProperty(const Key: WideString; const Value: WideString); dispid 228;
    function GetPath(const StorageFilename: WideString): WideString; dispid 229;
  end;

// *********************************************************************//
// DispIntf:  IConnectionEvents
// Flags:     (0)
// GUID:      {21735F7D-3731-48A5-BC8F-8901B72B73E2}
// *********************************************************************//
  IConnectionEvents = dispinterface
    ['{21735F7D-3731-48A5-BC8F-8901B72B73E2}']
  end;

// *********************************************************************//
// The Class CoConnection provides a Create and CreateRemote method to
// create instances of the default interface IConnection exposed by
// the CoClass Connection. The functions are intended to be used by
// clients wishing to automate the CoClass objects exposed by the
// server of this typelibrary.
// *********************************************************************//
  CoConnection = class
    class function Create: IConnection;
    class function CreateRemote(const MachineName: string): IConnection;
  end;

implementation

uses System.Win.ComObj;

class function CoConnection.Create: IConnection;
begin
  Result := CreateComObject(CLASS_Connection) as IConnection;
end;

class function CoConnection.CreateRemote(const MachineName: string): IConnection;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_Connection) as IConnection;
end;

end.

