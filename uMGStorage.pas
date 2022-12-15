unit uMGStorage;
{
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

Please do not remove the following 2 lines from this source code:
Copyright 2016-2017 Mario Giannini
http://www.mariogiannini.com
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Masks, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IPPeerClient, Data.Cloud.CloudAPI,
  Data.Cloud.AmazonAPI, Vcl.StdCtrls, System.StrUtils, HTTPApp, System.Types, System.IOUtils,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdFTP, DateUtils,
  RegularExpressions;


  type
  TMGItemType = (mgitFolder, mgitFile, mgitOther);
  TMGListItem = class( TObject )
      FullPath, Name: String;
      Size: int64;
      UTCDate, Date: TDateTime;
      ItemType: TMGItemType;
      private procedure Init( aFullPath, aName: String; aSize: int64; aDate: TDateTime; aItemType: TMGItemType );
    public
//      Constructor Create( aFullPath, aName: String; aSize: int64; aDate: TDateTime; aItemType: TMGItemType ); overload;
      Constructor Create( aFullPath: String; aSize: int64; aDate: TDateTime; aItemType: TMGItemType ); overload;
  end;
  TMGListItems = class( TObject )
    private
      fItems: TList;
      function GetItemValue(Index: Integer): TMGListItem;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      procedure Add( aItem: TMGListItem; CaseSensitive: Boolean );
      procedure Delete( Index: integer );
      property Values[ItemIndex: integer]: TMGListItem read GetItemValue; default;
      function Count: integer;
      function Find( FullPath: String; CaseSensitive: Boolean ) : TMGListItem;
      procedure Sort;
  end;

  TMGStorageService = class( TObject )
  protected
    fContainerName: String;
    fConnectionString: String;
    fConnected: Boolean;
    fFileURL: String;
    fServerProtocol: String;
    fServer: String;
    fItemList: TMGListItems;
    fFileIndex: Integer;
    fProperties: TStringList;
    fContainers: TStringList;
    fTmpSL: TStringList;
    fSupportsContainers: Boolean;
    fCurFolder: String; // Must always end in '/'
    fCaseSensitive: Boolean;
    fError: String;
  private
//    procedure RaiseErrorDeleteFolderNoDelete(Filename, Folder: String);
//    procedure RaiseErrorDeleteFolderNotEmpty(Folder: String);
  protected
    procedure PropertiesChanged; virtual; abstract;
    function FileMatches( Filename, Mask: String ) : boolean;
    procedure FileToArray( Localfilename: String; var Ar: TArray<Byte> );
    procedure RaisePutFileError( CloudFilename: String );
    procedure RaiseGetFileError( CloudFilename, LocalFilename: String );
    procedure RaiseDeleteFileError(CloudFilename: String );
    procedure RaiseRenameError( StorageFilenameOld, StorageFilenameNew: String );
    procedure RaiseRenameExistsError( StorageFilenameNew: String );
    procedure RaiseCopyError( StorageFilenameOld, StorageFilenameNew: String );
    procedure RaiseDeleteFolderNotEmptyError( Folder: String );
    procedure RaiseDeleteFolderNoDeleteError( Filename, Folder: String );
    procedure RaiseDeleteFolderRootError;
    procedure AssertConnected;
    function IsRootFolder( Folder: String ): Boolean;
    function ParseDate( Str: String ) : TDateTime;
    function ExtractCloudName( aPath: String ) : String;
    function ExtractCloudPath( aPath: String ) : String;
    function ExtractCloudPathRoot( aPath: String ) : String;
    function ExtractCloudPathParent( aPath: String ) : String;
    function ExtractCloudFolder( aPath: String ) : String;
    function IncludeTrailing( aPath: String ) : String;
    function CountCloudDepth( aPath: String ) : integer;
    procedure AddItem( aRelPath, aMask, aFullPath: String; aSize: int64; aDate: TDateTime );
    procedure ForceDirectories( Path: String );
    function LocalFileSize( LocalFile: String ) : int64;

  public
    constructor Create( ConnectionString: String );
    destructor Destroy; override;
    procedure RaiseError( GeneralMsg : String );
    function GetConnectionString: String;
    function GetContainer: String;
    procedure SetSSL( UseSSL: Boolean );
    function GetSSL: Boolean;
    function GetProperty( Propertyname: String ) : String;
    procedure SetProperty( Propertyname, Value: String );
    function GetFileURL: String;
    procedure AssertLocal( Localfilename: String );
    function EFP( Base, Path: String; Delimit: Boolean = false; Leading: Boolean=true ) : String; // Evaluate Full path

    procedure SetConnectionString( ConnectionString: String ); virtual;
    procedure Connect; virtual; Abstract;

    function SupportsContainers: Boolean;
    function ContainerExists( ContainerName: String ) : Boolean ; virtual;
    function GetContainerList: integer; virtual;
    procedure CreateContainer( ContainerName: String ); virtual;
    procedure SelectContainer( ContainerName: String ); virtual;
    function GetContainerName( Index: integer ): String;
    function GetContainerCount: Integer;

    function GetFolder: String;
    procedure SetFolder( NewFolder: String );
    procedure DeleteFolder( Folder: String; Recursive: Boolean ); virtual; abstract;

    function GetPath( CloudName: String ) : string;
    procedure PutFile( Localfilename, DestStorageFilename: String ); virtual; abstract;
    procedure GetFile( Storagefilename, DestLocalFilename: String ); virtual; abstract;
    procedure DeleteFile( Storagefilename: String ); virtual; abstract;
    procedure RenameFile( StorageFilenameOld, StorageFilenameNew: String ); virtual; abstract; // Fails if exists
    procedure CopyFile( StorageFilenameOld, StorageFilenameNew: String ); virtual; abstract; // Replaces if dest exists
    function FileExists( StorageFilename: String ): boolean; virtual; abstract;
    function CalcFileURL( StorageFilename: String ) : String; virtual; abstract;
    function GetFileList( Path, Mask: String; IncSubfolders: Boolean  ): integer; virtual; abstract;
    // Lists Folders and files that match Mask.
    // Full Path always includes '/' prefix
    function GetFileCount: integer;
    // ItemsList contains files and folders.
    function GetFileName( Index: Integer ): String;
    function GetFileFullPath( Index: Integer ): String;
    function GetFileSize( Index: Integer ): integer;
    function GetFileDate( Index: Integer ): TDateTime;
    function IsFile( Index: Integer ): Boolean;


    property Connected: Boolean read fConnected;
    class function MGCreateStorageService( ConnectionString: String ) : TMGStorageService;
  end;

implementation


uses uMGStorageFile, uMGStorageFTP, uMGStorageAmazon, uMGStorageAzure; // Sorry, but My base knows it's children, for MGCreateStorageService

function TzSpecificLocalTimeToSystemTime(lpTimeZoneInformation: PTimeZoneInformation;
  var lpLocalTime, lpUniversalTime: TSystemTime): BOOL; stdcall; external kernel32 name 'TzSpecificLocalTimeToSystemTime';
{$EXTERNALSYM TzSpecificLocalTimeToSystemTime}

procedure ParseSemi( Src: String; Dest: TStrings );
var
  Tmp: TStringList;
  S, K, V: String;
  P: integer;
begin
  Tmp := TStringList.Create;
  ExtractStrings( [';'], [], @Src[1], Tmp );
  while( Tmp.Count > 0 ) do
  begin
    S := Tmp[0];
    P := Pos( '=', S );
    K := Copy( S, 1, P-1 );
    V := Copy( S, P+1 );
    if( Length( V ) > 1 ) and (V[1]='"') and (V[Length(V)] = '"') then
      V := Copy( V, 2, Length(V)-2);
    V := StringReplace( V, '""', '"', [rfReplaceAll] );
    Dest.Values[K] := V;
    Tmp.Delete(0);
  end;
end;


{ TMGStorageService }
procedure TMGStorageService.AddItem(aRelPath, aMask, aFullPath: String; aSize: int64; aDate: TDateTime );
begin
  // Is
end;

procedure TMGStorageService.AssertConnected;
begin
  if( fConnected = false ) then
    RaiseError( 'Not connected' );
end;

procedure TMGStorageService.AssertLocal(Localfilename: String);
begin
  if( Not System.SysUtils.FileExists( Localfilename ) ) then
      RaiseError('File not found ' + Localfilename );
end;

function TMGStorageService.IsRootFolder(Folder: String): Boolean;
begin
  Folder := StringReplace( fCurFolder + Folder, '\', '/', [rfReplaceAll] );
  Result := ( Folder = '/' ) or (Folder = '//') or (Folder = '' );
end;

function TMGStorageService.LocalFileSize(LocalFile: String): int64;
var
   info: TWin32FileAttributeData;
begin
   if GetFileAttributesEx(PWideChar(LocalFile), GetFileExInfoStandard, @info) then
      result := Int64(info.nFileSizeLow) or Int64(info.nFileSizeHigh shl 32)
   else
      Result := -1;
end;

function TMGStorageService.ContainerExists(ContainerName: String): Boolean;
begin
  Result := false;
  RaiseError('Containers not supported');
end;

function TMGStorageService.CountCloudDepth(aPath: String): integer;
begin
  if( aPath <> '' ) and  ( aPath[1]='/' ) then
    aPath := Copy( aPath, 2 );
  Result := Length( aPath ) - Length( StringReplace( aPath, '/', '', [rfReplaceAll] ) );
end;

constructor TMGStorageService.Create( ConnectionString: String );
begin
  fCaseSensitive := false;
  fSupportsContainers := false;
  fContainerName := '';
  fServerProtocol := 'https';
  fItemList := TMGListItems.Create;
  fFileIndex := 0;
  fConnected := false;
  fProperties := TStringList.Create;
  fProperties.CaseSensitive := false;
  fTmpSL := TStringList.Create;
  fCurFolder := '/';
  fContainers := TStringList.create;
  SetConnectionString( ConnectionString );
end;

procedure TMGStorageService.CreateContainer(ContainerName: String);
begin
  RaiseError('Containers not supported');
end;

destructor TMGStorageService.Destroy;
begin
  FreeAndNil( fItemList );
  FreeAndNil( fProperties );
  FreeAndNil( fTmpSL );
  FreeAndNil( fContainers );
end;

function TMGStorageService.EFP(Base, Path: String; Delimit: Boolean; Leading: Boolean ): String;
begin
  Path := StringReplace( Path, '\', '/', [rfReplaceAll] );
  if( Path <> '' ) and (Path[1]='/') then
    Result := Base + Path
  else
    Result := Base + fCurFolder + Path;
  if( Delimit ) then
    Result := Result + '/';
  while( Pos( '//', Result ) > 0 ) do
    Result := StringReplace( Result, '//', '/', [rfReplaceAll] );
  Result := StringReplace( Result, '\', '/', [rfReplaceAll] );
  if( Leading = false ) and (Result <> '' ) and (Result[1]='/' ) then
    Result := Copy( Result, 2 );
  if( Delimit = false ) and (Result <> '' ) and (Result[Length(Result)]='/' ) then
    Result := Copy( Result, 1, Length( Result )-1 );
  if( Delimit = true ) and ( (Result = '') or (Result[Length(Result)]<>'/' )) then
    Result := Result + '/';
end;

function TMGStorageService.ExtractCloudFolder(aPath: String): String;
var
  P: integer;
begin
  if( aPath <> '' ) and  ( aPath[1]='/' ) then
    aPath := Copy( aPath, 2 );
  P := Pos( '/', aPath );
  if( P > 0 ) then
    Result := Copy( aPath, 1, P-1 )
  else
    Result := '';
end;

function TMGStorageService.ExtractCloudName(aPath: String): String;
var
  P: integer;
begin
  P := LastDelimiter( '/', aPath );
  if( P > 0 ) then
    Result := Copy( aPath, P+1 )
  else
    Result := aPath;
end;


function TMGStorageService.ExtractCloudPath(aPath: String): String;
var
  P: integer;
begin
  if( aPath <> '' ) and  ( aPath[1]='/' ) then
    aPath := Copy( aPath, 2 );
  P := LastDelimiter( '/', aPath );
  if( P > 0 ) then
    Result := Copy( aPath, 1, P-1 )
  else
    Result := '';
end;


function TMGStorageService.ExtractCloudPathParent(aPath: String): String;
var
  P: integer;
begin
  Result := '';
  if( aPath <> '' ) and  ( aPath[1]='/' ) then
    aPath := Copy( aPath, 2 );
  P := Pos( '/', aPath );
  while( P > 0 ) do
  begin
    Result := Copy( aPath, 1, P-1 );
    aPath := Copy( aPath, P+1 );
    P := Pos( '/', aPath );
  end;
end;

function TMGStorageService.ExtractCloudPathRoot(aPath: String): String;
var
  P: integer;
begin
  if( aPath <> '' ) and  ( aPath[1]='/' ) then
    aPath := Copy( aPath, 2 );
  P := Pos( '/', aPath );
  if( P > 0 ) then
    Result := Copy( aPath, 1, P-1 )
  else
    Result := '';
end;

function TMGStorageService.GetFileCount: integer;
begin
  Result := fItemList.Count;
end;

procedure TMGStorageService.FileToArray( Localfilename: String; var Ar: TArray<Byte>);
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    Stream.LoadFromFile( Localfilename );
    SetLength( Ar, Stream.Size );
    Stream.Position := 0;
    Stream.Read( Ar, Stream.Size);
  except on E:Exception do
    begin
      FreeAndNil( Stream );
      SetLength( Ar, 0 );
      RaiseError( 'Unable to access local file ' + Localfilename + ': ' + E.Message );
    end;
  end;
  FreeAndNil( Stream );
end;

procedure TMGStorageService.ForceDirectories(Path: String);
begin
  if( Path <> '' ) then
    System.SysUtils.ForceDirectories( Path );
end;

function TMGStorageService.GetConnectionString: String;
begin
  Result := fConnectionString;
end;

function TMGStorageService.GetContainer: String;
begin
  Result := fContainerName;
end;

function TMGStorageService.GetContainerCount: Integer;
begin
  Result := 0;
  if( fSupportsContainers = false ) then
    RaiseError('Containers not supported')
  else
    Result := fContainers.Count;
end;

function TMGStorageService.GetContainerList: integer;
begin
  Result := 0;
  RaiseError('Containers not supported');
end;

function TMGStorageService.GetContainerName(Index: integer): String;
begin
  if( fSupportsContainers = false ) then
    RaiseError('Containers not supported');
  if( Index < fContainers.Count ) then
    Result := fContainers[Index]
  else
    Result := '';
end;

function TMGStorageService.GetFileDate(Index: Integer): TDateTime;
begin
  if( Index < fItemList.Count ) then
    Result := fItemList[Index].Date
  else
    Result := 0;

end;

function TMGStorageService.GetFileFullPath(Index: Integer): String;
begin
  if( Index < fItemList.Count ) then
    Result := fItemList[Index].FullPath
  else
    Result := '';
end;

function TMGStorageService.GetFileName(Index: Integer): String;
begin
  if( Index < fItemList.Count ) then
    Result := fItemList[Index].Name
  else
    Result := '';
end;

function TMGStorageService.GetFileSize(Index: Integer): integer;
begin
  if( Index < fItemList.Count ) then
    Result := fItemList[Index].Size
  else
    Result := 0;
end;

function TMGStorageService.GetFileURL: String;
begin
  Result := fFileURL;
end;

function TMGStorageService.GetFolder: String;
begin
  Result := fCurFolder;
end;

function TMGStorageService.GetPath(CloudName: String): string;
begin
  Result := EFP( '', CloudName, false, true );
end;

function TMGStorageService.GetProperty(Propertyname: String): String;
begin
  Result := fProperties.Values[ Propertyname ];
end;

function TMGStorageService.GetSSL: Boolean;
begin
  Result := fServerProtocol = 'https';
end;

function TMGStorageService.IncludeTrailing(aPath: String): String;
begin
  Result := StringReplace( aPath + '/', '//', '/', [rfReplaceAll] );
end;

function TMGStorageService.IsFile(Index: Integer): Boolean;
begin
  if( Index < fItemList.Count ) then
    Result := fItemList[Index].ItemType = mgitFile
  else
    Result := false;
end;

function TMGStorageService.FileMatches(Filename, Mask: String): boolean;
begin
  Result := MatchesMask( Filename, Mask );
end;

class function TMGStorageService.MGCreateStorageService(
  ConnectionString: String): TMGStorageService;
var
  SL: TStringList;
begin

  SL := TStringList.Create;
  try
    ParseSemi( ConnectionString, SL );
    if( SameText( SL.Values['provider'], 'azureblob' ) ) then
      Result := TMGStorageService( TMGAzureConnection.Create( ConnectionString ) )
    else if( SameText( SL.Values['provider'], 'amazons3' ) ) then
      Result := TMGStorageService( TMGAmazonConnection.Create( ConnectionString ) )
    else
    if( SameText( SL.Values['provider'], 'file' ) ) then
      Result := TMGStorageService( TMGFileConnection.Create(  ConnectionString  ))
    else if( SameText( SL.Values['provider'], 'ftp' ) ) then
    begin
      Result := TMGStorageService( TMGFTPConnection.Create( ConnectionString ) );
    end
    else
      raise Exception.Create('Invalid provider: ' + QuotedStr( SL.Values['provider'] ) );
  finally
    SL.Free;
  end;
end;


function TMGStorageService.ParseDate(Str: String): TDateTime;
var
  UTCTime, LocalTime: SYSTEMTIME;
begin
  Result := 0;
  if( Str = '' ) then
    exit;
  // MM/DD/YY HH:MM:SS
  if( Length( Str ) = 29 ) then // Mon, 04 Dec 2017 21:58:26 GMT'
  begin
    Str := StringReplace( Str, ' Jan ', ' 01 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Feb ', ' 02 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Mar ', ' 03 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Apr ', ' 04 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' May ', ' 05 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Jun ', ' 06 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Jul ', ' 07 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Aug ', ' 08 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Sep ', ' 09 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Oct ', ' 10 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Nov ', ' 11 ', [rfIgnoreCase] );
    Str := StringReplace( Str, ' Dec ', ' 12 ', [rfIgnoreCase] );
    Str := Copy( Str, 9, 2 ) + '/' + Copy( Str, 6, 2 ) + '/' + Copy( Str, 12, 4 ) + ' ' + Copy( Str, 17, 12 );
    Result := StrToDateTime( Str );
  end
  else if( Length( Str ) =  24 ) then// '2017-12-14T21:02:39.000Z'
  begin
    Result := EncodeDateTime( StrToInt( Copy( Str, 1, 4 ) ), StrToInt( Copy( Str, 6, 2 ) ), StrToInt( Copy( Str, 9, 2 ) ),
      StrToInt( Copy( Str, 12, 2 ) ), StrToInt( Copy( Str, 15, 2 ) ), StrToInt( Copy( Str, 18, 2 ) ),StrToInt( Copy( Str, 21, 3 ) ));
  end;

  DateTimeToSystemTime( Result, UTCTime );
  SystemTimeToTzSpecificLocalTime( nil, UTCTime, LocalTime );
  Result := SystemTimeToDateTime( LocalTime);
end;

procedure TMGStorageService.RaiseCopyError(StorageFilenameOld,
  StorageFilenameNew: String);
begin
  RaiseError( 'Unable to copy ' + StorageFilenameOld + ' to ' + StorageFilenameNew );
end;

procedure TMGStorageService.RaiseDeleteFileError(CloudFilename: String);
begin
  RaiseError( 'Unable to delete file ' + CloudFilename  );
end;


procedure TMGStorageService.RaiseDeleteFolderNoDeleteError(Filename,
  Folder: String);
begin
  RaiseError( 'Unable to delete file ' + Filename + ' in ' + Folder  );
end;

procedure TMGStorageService.RaiseDeleteFolderNotEmptyError(Folder: String);
begin
  RaiseError( 'Unable to delete folder (not empty) '+ Folder  );
end;

procedure TMGStorageService.RaiseDeleteFolderRootError;
begin
  RaiseError( 'Can''t delete root folder');
end;

procedure TMGStorageService.RaiseError(GeneralMsg: String);
begin
  fError := 'Error: ' + GeneralMsg;
  raise Exception.Create( fError  );
end;

{procedure TMGStorageService.RaiseErrorDeleteFolderNoDelete(Filename,
  Folder: String);
begin
  if( Filename <> '' ) then
    RaiseError( 'Unable to delete ' + Filename + ' during DeleteFolder ' + Folder )
  else
    RaiseError( 'Unable to delete folder ' + Folder );
end;

procedure TMGStorageService.RaiseErrorDeleteFolderNotEmpty(Folder: String);
begin
  RaiseError( 'Can''t delete populated folder without recursive option: '+ Folder)
end;
}
procedure TMGStorageService.RaiseGetFileError(CloudFilename,
  LocalFilename: String);
begin
  RaiseError( 'Unable to get file ' + CloudFilename + ' to ' + LocalFilename  );

end;

procedure TMGStorageService.RaisePutFileError(CloudFilename: String);
begin
  RaiseError( 'Unable to put file to ' + CloudFilename  );
end;

procedure TMGStorageService.RaiseRenameError(StorageFilenameOld,
  StorageFilenameNew: String);
begin
  RaiseError( 'Unable to rename ' + StorageFilenameOld + ' to ' + StorageFilenameNew );
end;

procedure TMGStorageService.RaiseRenameExistsError(StorageFilenameNew: String);
begin
  RaiseError( 'Rename destination exists: ' + StorageFilenameNew );
end;

procedure TMGStorageService.SelectContainer(ContainerName: String);
begin
  RaiseError('Containers not supported');
end;

procedure TMGStorageService.SetConnectionString(ConnectionString: String);
begin
  fConnectionString := ConnectionString;
  ParseSemi( ConnectionString, fProperties );
  PropertiesChanged;
end;

procedure TMGStorageService.SetFolder(NewFolder: String);
begin
  fCurFolder := EFP( '', NewFolder, true );
end;

procedure TMGStorageService.SetProperty(Propertyname, Value: String);
begin
  fProperties.Values[ Propertyname ] := Value;
  PropertiesChanged;
end;

procedure TMGStorageService.SetSSL( UseSSL: Boolean);
begin
  if( UseSSL ) then
    fServerProtocol := 'https'
  else
    fServerProtocol := 'http';
end;

function TMGStorageService.SupportsContainers: Boolean;
begin
    Result := fSupportsContainers;
end;



{ TMGListItems }

procedure TMGListItems.Add( aItem: TMGListItem; CaseSensitive: Boolean);
var
  Item: TMGListItem;
  i: integer;

begin
  for i := 0 to fItems.Count-1 do
  begin
    Item := fItems[i];
    if ( CaseSensitive and (Item.FullPath = aItem.FullPath ) )
    or ( (Not CaseSensitive) and SameText( Item.FullPath, aItem.FullPath ) ) then // Don't store duplicates
    begin
      aItem.Free;
      exit;
    end;
  end;
  fItems.Add( aItem );
end;

procedure TMGListItems.Clear;
var
  i: integer;
begin
  for i := 0 to fItems.Count-1 do
    TMGListItem( fItems[ i ] ).Free;
  fItems.Clear;
end;

function TMGListItems.Count: integer;
begin
  Result := fItems.Count;
end;

constructor TMGListItems.Create;
begin
  fItems := TList.Create;
end;

procedure TMGListItems.Delete(Index: integer);
begin
  TMGListItem( fItems[ Index ] ).Free;
  fItems.Delete( Index );
end;

destructor TMGListItems.Destroy;
var
  i: integer;
begin
  for i := 0 to fItems.Count-1 do
    TMGListItem( fItems[ i ] ).Free;
  FreeAndNil( fItems );
end;

function TMGListItems.Find(FullPath: String; CaseSensitive: Boolean): TMGListItem;
var
  i: integer;
begin
  for i := 0 to fItems.Count-1 do
  begin
    Result := fItems[i];
    if( Result.FullPath = FullPath ) then
      exit;
  end;
  Result := nil;
end;


function TMGListItems.GetItemValue(Index: Integer): TMGListItem;
begin
  Result := fItems[ Index ];
end;

function MyItemCompare(Item1, Item2: Pointer): Integer;
begin
  Result := AnsiCompareStr( TMGListItem(Item1).FullPath, TMGListItem( Item2).FullPath );
  if( Result < 0 ) then
    Result := -1
  else if Result > 0  then
    Result := 1
end;

procedure TMGListItems.Sort;
begin
  fItems.Sort( MyItemCompare );
end;

{ TMGListItem }

{Constructor TMGListItem.Create( aFullPath, aName: String; aSize: int64; aDate: TDateTime; aItemType: TMGItemType );
begin
  Init( aFullPath, aName, aSize, aDate, aItemType );
end;
}
constructor TMGListItem.Create(aFullPath: String; aSize: int64; aDate: TDateTime; aItemType: TMGItemType);
var
  P: integer;
begin
  aFullPath := StringReplace( aFullPath, '\', '/', [rfReplaceAll] );
  P := LastDelimiter( '/', aFullPath );
  if( P > 0 ) then
    Init( aFullPath, Copy( aFullPath, P+1 ), aSize, aDate, aItemType )
  else
    Init( aFullPath, aFullPath, aSize, aDate, aItemType )
end;


procedure TMGListItem.Init(aFullPath, aName: String; aSize: int64;
  aDate: TDateTime; aItemType: TMGItemType);
var
  UTCTime, LocalTime: SYSTEMTIME;
  TZI:TTimeZoneInformation;
begin
  FullPath := StringReplace( aFullPath, '\', '/', [rfReplaceAll] );
  Name := aName;
  Size := aSize;
  Date:= aDate;
  DateTimeToSystemTime(aDate,LocalTime);
  GetTimeZoneInformation(tzi);
  TzSpecificLocalTimeToSystemTime(@tzi,LocalTime,UTCTime);
  UTCDate := SystemTimeToDateTime(UTCTime);
  ItemType := aItemType;

end;

end.
