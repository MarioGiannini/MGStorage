unit uConnection;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  ComObj, ActiveX, AxCtrls, Classes,
  MGStorage_TLB, StdVcl, SysUtils, uMGStorage;

type
  TConnection = class(TAutoObject, IConnectionPointContainer, IConnection)
  private
    { Private declarations }
    FConnectionPoints: TConnectionPoints;
    FConnectionPoint: TConnectionPoint;
    FEvents: IConnectionEvents;
    { note: FEvents maintains a *single* event sink. For access to more
      than one event sink, use FConnectionPoint.SinkList, and iterate
      through the list of sinks. }
    fStorageService: TMGStorageService;
  public
    procedure Initialize; override;
    destructor Destroy; override;
    procedure AssertInitialized( MustBeConnected: Boolean );
  protected
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
    function GetFileList(const Path, Mask: WideString; IncludeSubfolders: WordBool): LongWord;
          safecall;
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
    procedure GetFile(const Storagefilename, DestLocalFilename: WideString); safecall;
    procedure PutFile(const Localfilename, DestStorageFilename: WideString); safecall;
    procedure DeleteFile(const Storagefilename: WideString); safecall;
    procedure RenameFile(const StorageFilenameOld, StorageFilenameNew: WideString); safecall;
    procedure CopyFile(const StorageFilenameOld, StorageFilenameNew: WideString); safecall;
    function GetProperty(const Key: WideString): WideString; safecall;
    procedure SetProperty(const Key, Value: WideString); safecall;
    function GetPath(const StorageFilename: WideString): WideString; safecall;




    { Protected declarations }
    property ConnectionPoints: TConnectionPoints read FConnectionPoints
      implements IConnectionPointContainer;
    procedure EventSinkChanged(const EventSink: IUnknown); override;

  end;

implementation

uses ComServ;

destructor TConnection.Destroy;
begin
  FreeAndNil( fStorageService );
  inherited;
end;

procedure TConnection.EventSinkChanged(const EventSink: IUnknown);
begin
  FEvents := EventSink as IConnectionEvents;
end;

procedure TConnection.Initialize;
begin
  fStorageService := nil;
  inherited Initialize;
  FConnectionPoints := TConnectionPoints.Create(Self);
  if AutoFactory.EventTypeInfo <> nil then
    FConnectionPoint := FConnectionPoints.CreateConnectionPoint(
      AutoFactory.EventIID, ckSingle, EventConnect)
  else FConnectionPoint := nil;
end;


function TConnection.Get_ConnectionString: WideString;
begin
  if( fStorageService <> nil ) then
    Result := fStorageService.GetConnectionString
  else
    raise Exception.Create( 'Error: Not properly initialized' )
end;

procedure TConnection.Set_ConnectionString(const Value: WideString);
begin
  if( fStorageService <> nil ) then
    FreeAndNil( fStorageService );
  fStorageService := TMGStorageService.MGCreateStorageService( Value );
end;

procedure TConnection.AssertInitialized( MustBeConnected: Boolean );
begin
  if( fStorageService = nil ) then
    raise Exception.Create( 'Error: Not properly initialized' )
  else if( MustBeConnected) and (fStorageService.Connected = false ) then
    fStorageService.RaiseError( 'Not connected to provider' );
end;

procedure TConnection.Connect;
begin
  AssertInitialized( false );
  fStorageService.Connect
end;


function TConnection.Get_Connected: WordBool;
begin
  AssertInitialized( false );
  Result := fStorageService.Connected
end;

function TConnection.Get_SupportsContainers: WordBool;
begin
  AssertInitialized( true );
  Result := fStorageService.SupportsContainers
end;

function TConnection.ContainerExists(const Container: WideString): WordBool;
begin
  AssertInitialized( true );
  Result := fStorageService.ContainerExists( Container )
end;

procedure TConnection.CreateContainer(const Container: WideString);
begin
  AssertInitialized( true );
  fStorageService.CreateContainer( Container )
end;

function TConnection.GetContainerList: Integer;
begin
  AssertInitialized( true );
  Result := fStorageService.GetContainerList;
end;

function TConnection.GetContainerName(Index: Integer): WideString;
begin
  AssertInitialized( true );
  Result := fStorageService.GetContainerName( Index );
end;

procedure TConnection.SelectContainer(const Container: WideString);
begin
  AssertInitialized( true );
  fStorageService.SelectContainer( Container );
end;

function TConnection.GetFileList(const Path, Mask: WideString; IncludeSubfolders: WordBool): LongWord;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFileList( Path, Mask, IncludeSubFolders );
end;

function TConnection.GetContainerCount: Integer;
begin
  AssertInitialized( true );
  Result := fStorageService.GetContainerCount;

end;

function TConnection.GetFileCount: Integer;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFileCount;

end;

function TConnection.GetFileName(Index: Integer): WideString;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFileName( Index );
end;

function TConnection.GetFileFullPath(Index: Integer): WideString;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFileFullPath( Index );
end;

function TConnection.GetFileSize(Index: Integer): LongWord;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFileSize( Index );
end;

function TConnection.GetFileDate(Index: Integer): TDateTime;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFileDate( Index );
end;

function TConnection.IsFile(Index: Integer): WordBool;
begin
  AssertInitialized( true );
  Result := fStorageService.IsFile( Index );

end;

function TConnection.GetFolder: WideString;
begin
  AssertInitialized( true );
  Result := fStorageService.GetFolder;
end;

procedure TConnection.SetFolder(const Folder: WideString);
begin
  AssertInitialized( true );
  fStorageService.SetFolder( Folder );
end;

procedure TConnection.DeleteFolder(const Folder: WideString; Recursive: WordBool);
begin
  AssertInitialized( true );
  fStorageService.DeleteFolder( Folder, Recursive );
end;

function TConnection.FileExists(const StorageFilename: WideString): WordBool;
begin
  AssertInitialized( true );
  Result := fStorageService.FileExists( StorageFilename );
end;

procedure TConnection.GetFile(const Storagefilename, DestLocalFilename: WideString);
begin
  AssertInitialized( true );
  fStorageService.GetFile( Storagefilename, DestLocalFilename );
end;

procedure TConnection.PutFile(const Localfilename, DestStorageFilename: WideString);
begin
  AssertInitialized( true );
  fStorageService.PutFile( Localfilename, DestStorageFilename );
end;

procedure TConnection.DeleteFile(const Storagefilename: WideString);
begin
  AssertInitialized( true );
  fStorageService.DeleteFile( Storagefilename );
end;

procedure TConnection.RenameFile(const StorageFilenameOld, StorageFilenameNew: WideString);
begin
  AssertInitialized( true );
  fStorageService.RenameFile( StorageFilenameOld, StorageFilenameNew );
end;

procedure TConnection.CopyFile(const StorageFilenameOld, StorageFilenameNew: WideString);
begin
  AssertInitialized( true );
  fStorageService.CopyFile( StorageFilenameOld, StorageFilenameNew );
end;

function TConnection.GetProperty(const Key: WideString): WideString;
begin
  AssertInitialized( true );
  Result := fStorageService.GetProperty( Key );
end;

procedure TConnection.SetProperty(const Key, Value: WideString);
begin
  AssertInitialized( true );
  fStorageService.SetProperty( Key, Value );
end;

function TConnection.GetPath(const StorageFilename: WideString): WideString;
begin
  AssertInitialized( true );
  Result := fStorageService.GetPath( StorageFilename );
end;

initialization
  TAutoObjectFactory.Create(ComServer, TConnection, Class_Connection,
    ciMultiInstance, tmApartment);
end.
