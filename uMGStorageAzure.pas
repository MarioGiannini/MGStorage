unit uMGStorageAzure;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Masks,
  System.Generics.Collections,
  Data.Cloud.CloudAPI, Data.Cloud.AzureAPI, Vcl.StdCtrls, System.StrUtils,
  HTTPApp, System.Types, System.IOUtils, NetEncoding, uMGStorage;

  type
  TMGAzureConnection = class(TMGStorageService)
      fConnAzure: TAzureConnectionInfo;
      fBlobService: TAzureBlobService;
      fReducedRedundancy: Boolean;
      fPublicRead: Boolean;
  protected
    procedure PropertiesChanged; override;
  public
    constructor Create( ConnectionString: String );
    destructor Destroy; override;
    procedure Connect; override;
    function ContainerExists( ContainerName: String ) : Boolean ; override;
    procedure SelectContainer( ContainerName: String ); override;
    function GetContainerList: integer; override;
    procedure CreateContainer( ContainerName: String ); override;

    procedure DeleteFolder( Folder: String; Recursive: Boolean ); override;

    procedure PutFile( Localfilename, DestStorageFilename: String ); override;
    procedure GetFile( Storagefilename, DestLocalFilename: String ); override;
    function GetFileList( Path, Mask: String; IncSubfolders: Boolean ): integer; override;
    procedure DeleteFile( Storagefilename: String ); override;
    function FileExists( StorageFilename: String ): boolean; override;
    procedure RenameFile( StorageFilenameOld, StorageFilenameNew: String ); override;
    procedure CopyFile( StorageFilenameOld, StorageFilenameNew: String ); override;
    function CalcFileURL( StorageFilename: String ) : String; override;
  end;

implementation

{ TMGAzureConnection }


function TMGAzureConnection.CalcFileURL(StorageFilename: String): String;
begin
  AssertConnected;
  Result :=  fConnAzure.AccountName + '.blob.core.windows.net/'+fContainername + EFP('', StorageFilename, false, true );
end;

{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
procedure TMGAzureConnection.Connect;
var
  S: String;
  P: integer;
begin
  if( fBlobService <> nil ) then
    FreeAndNil( fBlobService );
  fBlobService := TAzureBlobService.Create(fConnAzure);
  S := fBlobService.ListContainersXML;
  if( Pos( '<Containers>', S )> 0 ) then
  begin
    if( fContainerName = '' ) then
    begin
      P := Pos( '</Name', S );
      if( P > 0 ) then
      begin
        S := Copy( S, 1, P-1 );
        P := Pos( '<Name>', S );
        S := Copy( S, P+6 );
        if( fContainerName = '' ) then
          fContainerName := S;
      end;
    end;
    fConnected := true;
  end
  else
  begin
    fConnected := false;
      RaiseError('Unable to connect');
  end;
end;
{$else}
procedure TMGAzureConnection.Connect;
var
  ResponseXML, NextMarker: String;
  Container: TAzureContainerItem;
  Containers: TArray<TAzureContainerItem>;

begin
  if( fBlobService <> nil ) then
    FreeAndNil( fBlobService );
  fBlobService := TAzureBlobService.Create(fConnAzure);

  fContainers.Clear;
  Containers := fBlobService.ListContainers( false, '', '', 100000, NextMarker, ResponseXML, nil );
  for Container in Containers do
    fContainers.Add( Container.Name );

  if( fContainers.Count > 0 ) then
  begin
    if (fContainerName = '' ) then
      fContainerName := fContainers[0];
    fConnected := true;
  end
  else
  begin
    fConnected := false;
    RaiseError('Unable to connect');
  end;

end;
{$endif}

function TMGAzureConnection.ContainerExists(ContainerName: String): Boolean;
var
  Container: String;
begin
  AssertConnected;
  Result := false;
  for Container in fContainers do
  begin
    if( SameText( Container, Containername ) ) then
    begin
      Result := true;
      break;
    end;
  end;
end;

{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
procedure TMGAzureConnection.CopyFile(StorageFilenameOld,
  StorageFilenameNew: String);
var
  Conditional: TBlobActionConditional;
begin
  AssertConnected;
  Conditional := TBlobActionConditional.Create;
  StorageFilenameOld := EFP('',StorageFilenameOld, false, false );
  StorageFilenameNew := EFP('',StorageFilenameNew, false, false );
  If not fBlobService.CopyBlob(fContainerName, StorageFilenameNew,
    fContainerName, StorageFilenameOld, Conditional, '', nil, nil ) then
    RaiseCopyError( StorageFilenameOld, StorageFilenameNew );
end;
{$else}
procedure TMGAzureConnection.CopyFile(StorageFilenameOld,
  StorageFilenameNew: String);
var
  Conditional: TBlobActionConditional;
  Metadata: TArray<TPair<string, string>>;
begin
  AssertConnected;
  Conditional := TBlobActionConditional.Create;
  MetaData := TArray<TPair<string, string>>.Create();
  StorageFilenameOld := EFP('',StorageFilenameOld, false, false );
  StorageFilenameNew := EFP('',StorageFilenameNew, false, false );
  try
    if not fBlobService.CopyBlob( fContainerName, StorageFilenameNew, fContainerName, StorageFilenameOld,
        '', Conditional,  Metadata,  nil ) then
      RaiseCopyError( StorageFilenameOld, StorageFilenameNew );
  finally
    FreeAndNil( Conditional );
    FreeAndNil( MetaData );
  end;

end;
{$endif}

constructor TMGAzureConnection.Create(ConnectionString: String);
begin
  fConnAzure := TAzureConnectionInfo.Create( nil );
  fConnAzure.Protocol := 'https';
  fPublicRead := false;
  inherited;
  fSupportsContainers := true;
end;
{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
procedure TMGAzureConnection.CreateContainer(ContainerName: String);
begin
  AssertConnected;
  if( Not fBlobService.CreateContainer( ContainerName ) ) then
    RaiseError('Unable to create container ' + ContainerName );
end;
{$else}
procedure TMGAzureConnection.CreateContainer(ContainerName: String);
var
  Access: TBlobPublicAccess;
  Metadata: TArray< TPair<string, string> >;
  ResponseInfo: TCloudResponseInfo;
begin
  AssertConnected;

  if( fPublicRead ) then
    Access := bpaContainer
  else
    Access := bpaPrivate;
  Metadata := nil;
  ResponseInfo := nil;
  if Not fBlobService.CreateContainer( ContainerName, Metadata, Access, ResponseInfo ) then
    RaiseError('Unable to create container ' + ContainerName );
  GetContainerList;
end;
{$endif}

procedure TMGAzureConnection.DeleteFile(Storagefilename: String);
begin
  AssertConnected;
  if( self.FileExists( StorageFilename ) ) then
  begin
    if not fBlobService.DeleteBlob( fContainerName, EFP('',Storagefilename, false, false ), false, '', nil ) then
      RaiseDeleteFileError( StorageFilename );
  end;
end;

{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
procedure TMGAzureConnection.DeleteFolder(Folder: String; Recursive: Boolean);
var
  BlobList: TList<TAzureBlob>;
  BlobItem: TAzureBlob;
  BlobName, NextMarker: String;
  OptionalParams : TStrings;
  ToDelete: TStringList;
begin
  AssertConnected;
  if IsRootFolder(Folder) then
    RaiseDeleteFolderRootError;
  OptionalParams := TStringList.Create;
  try
    ToDelete := fTmpSL;
    ToDelete.Clear;
    Folder := EFP( '', Folder, true, false );
    NextMarker := '';
    OptionalParams.Values['prefix'] := Folder;
    repeat
      if( NextMarker <> '' ) then
        OptionalParams.Values['marker'] := NextMarker;
      BlobList := fBlobService.ListBlobs( fContainerName, NextMarker, OptionalParams );
      if( Recursive = false ) and ( BlobList.Count > 0 ) then
        RaiseDeleteFolderNotEmptyError( Folder );
      for BlobItem in BlobList do
        ToDelete.Add( BlobItem.Name );
      FreeAndNil( BlobList );
    until NextMarker='';
    for BlobName in ToDelete do
    begin
      if Not fBlobService.DeleteBlob( fContainerName, BlobName ) then
        RaiseDeleteFolderNoDeleteError( BlobName, Folder );
    end;
    // If you delete the last item in an Azure 'folder', the folder disappears.
  finally
    FreeAndNil( OptionalParams );
  end;
end;
{$else}
procedure TMGAzureConnection.DeleteFolder(Folder: String; Recursive: Boolean);
var
  BlobArray: TArray<TAzureBlobItem>;
  BlobPrefix: TArray<string>;
  ResponseXML: String;

  BlobItem: TAzureBlobItem;
  BlobName, NextMarker: String;
  ToDelete: TStringList;
begin
  AssertConnected;
  if IsRootFolder(Folder) then
    RaiseDeleteFolderRootError;
  ToDelete := fTmpSL;
  ToDelete.Clear;
  Folder := EFP( '', Folder, true, false );
  NextMarker := '';

  repeat
    BlobPrefix := nil;
    BlobArray := fBlobService.ListBlobs( fContainerName, Folder, '', '',
      1000, [bdsMetadata], NextMarker, BlobPrefix, ResponseXML, nil);
    if( Recursive = false ) and ( Length( BlobArray ) > 0 ) then
      RaiseDeleteFolderNotEmptyError( Folder );
    for BlobItem in BlobArray do
      ToDelete.Add( BlobItem.Name );
  until NextMarker='';

  for BlobName in ToDelete do
  begin
    if not fBlobService.DeleteBlob( fContainerName, BlobName, false, '', nil ) then
      RaiseDeleteFolderNoDeleteError( BlobName, Folder );
  end;
  // If you delete the last item in an Azure 'folder', the folder disappears.
end;
{$endif}

destructor TMGAzureConnection.Destroy;
begin
  FreeAndNil( fBlobService );
  FreeAndNil( fConnAzure );
  inherited;
end;

{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
function TMGAzureConnection.FileExists(StorageFilename: String): boolean;
var
  SL: TStrings;
begin
  AssertConnected;
  SL := nil;
  Result := fBlobService.GetBlobProperties(fContainerName, EFP( '', StorageFilename, false, false), SL, '', '', nil );
end;
function TMGAzureConnection.GetContainerList: integer;
var
  NextMarker: String;
  AC: TAzureContainer;
  CL: TList<TAzureContainer>;
begin
  AssertConnected;
  fContainers.Clear;
  NextMarker := '';
  fTmpSL.Clear;
  repeat
    if( NextMarker <> '' ) then
      fTmpSL.values['marker'] := NextMarker;
    CL := fBlobService.ListContainers( NextMarker, fTmpSL );
    for AC in CL do
      fContainers.Add( AC.Name );
    CL.Free;
  until NextMarker='';
  Result := fContainers.Count;
end;
procedure TMGAzureConnection.GetFile(Storagefilename,
  DestLocalFilename: String);
var
  Stream: TFileStream;
begin
  AssertConnected;
  try
    Stream := TFileStream.Create( DestLocalFilename, fmCreate or fmOpenWrite );
    if Not fBlobService.GetBlob( fContainerName, EFP( '', Storagefilename, false, false ), Stream ) then
      RaiseGetFileError( Storagefilename, DestLocalFilename );
  finally
    FreeAndNil( Stream );
  end;

end;
{$else}
function TMGAzureConnection.FileExists(StorageFilename: String): boolean;
var
  BlobArray: TArray<TAzureBlobItem>;
  BlobPrefix: TArray<string>;
  FullPath, NextMarker, ResponseXML: String;
begin
  AssertConnected;
  FullPath := EFP( '', StorageFilename, false, false);
  BlobPrefix := TArray<String>.Create();
  BlobArray := fBlobService.ListBlobs( fContainerName, FullPath, '', '', 1000,
    [bdsMetadata],  NextMarker, BlobPrefix, ResponseXML, nil );
  Result := Length( BlobArray ) = 1;
end;
function TMGAzureConnection.GetContainerList: integer;
var
  NextMarker,ResponseXML: String;
  Container: TAzureContainerItem;
  Containers: TArray<TAzureContainerItem>;
begin
  AssertConnected;

  fContainers.Clear;
  Containers := fBlobService.ListContainers( false, '', '', 100000, NextMarker, ResponseXML, nil );
  for Container in Containers do
    fContainers.Add( Container.Name );
  Result := fContainers.Count;
end;

procedure TMGAzureConnection.GetFile(Storagefilename,
  DestLocalFilename: String);
var
  Stream: TFileStream;
  Properties, Metadata: TArray<TPair<string, string>>;
  ResponseInfo: TCloudResponseInfo;
begin
  AssertConnected;
  try
    ForceDirectories( ExtractFilePath( DestLocalFilename ) );
    Stream := TFileStream.Create( DestLocalFilename, fmCreate or fmOpenWrite );
    Properties := nil;//TArray<TPair<string, string>>.Create;
    Metadata := nil; // TArray<TPair<string, string>>.Create;
    ResponseInfo := TCloudResponseInfo.Create;

    if( Not fBlobService.GetBlob( fContainerName, EFP( '', Storagefilename, false, false ),
      '', 0, 0, false, Properties, Metadata, Stream, ResponseInfo ) ) then
      RaiseGetFileError( Storagefilename, DestLocalFilename );
  finally
    FreeAndNil( Stream );
    FreeAndNil( ResponseInfo );
  end;

end;
{$endif}

{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
function TMGAzureConnection.GetFileList(Path, Mask: String; IncSubfolders: Boolean): integer;
var
  BlobList: TList<TAzureBlob>;
  BlobItem: TAzureBlob;
  NextMarker: String;
  OptionalParams : TStrings;
  Foldername, Filename: String;
  IsFolder: Boolean;

begin
  AssertConnected;
  fItemList.Clear;
  OptionalParams := TStringList.Create;
  try
    Path := EFP( '', Path, true, false );
    if( Path = '/' ) then
      Path := '';
    OptionalParams.Values['prefix'] := Path;
    if( Not IncSubfolders ) then
      OptionalParams.Values['delimiter'] := '/';
    NextMarker := '';
    repeat
      if( NextMarker <> '' ) then
        OptionalParams.Values['marker'] := NextMarker;
      BlobList := fBlobService.ListBlobs( fContainerName, NextMarker, OptionalParams );
      for BlobItem in BlobList do
      begin
        Filename := BlobItem.Name;
        // When no delimiter, there are no folder indicators, only files
        // Folder/Folder2/Folder3/Zest.txt
        // When there is a delimiter, then folders have a terminating /
        if( IncSubFolders ) then
        begin
          FolderName  := ExtractCloudPath( BlobItem.Name );
          Filename := ExtractCloudName( FolderName );
          if( FileMatches( Filename, Mask ) ) then
          begin
            fItemList.Add( TMGListItem.Create(
              '/' + FolderName,
              0,
              ParseDate( BlobItem.Properties.Values['Last-Modified'] ),
              mgitFolder ), true )
          end;
        end;
        Filename := BlobItem.Name;

        if( BlobItem.Name<>'' ) and (BlobItem.Name[ Length( BlobItem.Name ) ] = '/' ) then
        begin
          IsFolder := true;
          Filename := Copy(Filename, 1, Length( Filename )-1 );
        end
        else
        begin
          IsFolder := false;
        end;
        FolderName := ExtractCloudPath( Filename );
        Filename := StringReplace( Filename, FolderName+'/', '', [] );
        if( FileMatches( Filename, Mask ) ) then
        begin
          if( IsFolder ) then
          fItemList.Add( TMGListItem.Create(
            '/' + BlobItem.Name,
            0,
            PArseDate( BlobItem.Properties.Values['Last-Modified'] ),
            mgitFolder ), true )
          else
          fItemList.Add( TMGListItem.Create(
            '/' + BlobItem.Name,
            StrToIntDef( BlobItem.Properties.Values['Content-Length'], 0 ),
            ParseDate( BlobItem.Properties.Values['Last-Modified'] ),
            mgitFile ), true );
        end;
      end;
      FreeAndNil( BlobList );
    until NextMarker='';
    fItemList.Sort;
  finally
    FreeAndNil( OptionalParams );
  end;
  Result := fItemList.Count;
end;
{$else}
function TMGAzureConnection.GetFileList(Path, Mask: String; IncSubfolders: Boolean): integer;
var
  BlobArray: TArray<TAzureBlobItem>;
  BlobItem: TAzureBlobItem;
  BlobPrefix: TArray<string>;
  NextMarker, ResponseXML: String;
  SubName, ThisFolderPath, ThisFolderName, LastFolderPath: String;

  OptionalParams : TStrings;
  Filename: String;
  function GetProp( BlobItem: TAzureBlobItem; Prop: String ) : String;
  var
    Pair: TPair<string, string>;
  begin
    Result := '';
    for Pair in BlobItem.Properties do
    begin
      if( SameText( Pair.Key, Prop ) ) then
      begin
        Result := Pair.Value;
        break;
      end;

    end;
  end;
  function Depth( Src: String ) : integer;
  var
    i: integer;
  begin
    Result := 0;
    for i := 1 to Length( Src ) do
      if( Src[i] = '/' ) then
        Inc(Result);
  end;
begin
  AssertConnected;
  fItemList.Clear;
  OptionalParams := TStringList.Create;
  try
    Path := EFP( '', Path, true, false );
    if( Path = '/' ) then
      Path := '';
    OptionalParams.Values['prefix'] := Path;
    if( Not IncSubfolders ) then
      OptionalParams.Values['delimiter'] := '/';
    NextMarker := '';
    repeat
      if( NextMarker <> '' ) then
        OptionalParams.Values['marker'] := NextMarker;

      BlobPrefix := TArray<String>.Create();
      BlobArray := fBlobService.ListBlobs( fContainerName,
        Path, '', '', 1000, [bdsMetadata],  NextMarker,
        BlobPrefix, ResponseXML, nil );

      for BlobItem in BlobArray do
      begin
        Filename := BlobItem.Name;

        ThisFolderPath := ExtractCloudPath( BlobItem.Name );
        if( IncSubfolders ) then
          ThisFolderName := ExtractCloudPathParent( StringReplace( BlobItem.Name, Path, '', [rfIgnoreCase] ) )
        else
        begin
          // If this folder is a sub-sub folder, and IncSubFolder is false, ignore it.
          if( Depth( StringReplace( ThisFolderPath, Path, '', [rfIgnoreCase] ) ) > 0 ) then
            ThisFolderName := ''
          else
            ThisFolderName  := ExtractCloudPathRoot( StringReplace( BlobItem.Name, Path, '', [rfIgnoreCase] ) );
        end;
        if( ThisFolderPath <> LastFolderPath ) and (ThisFolderName <> '' ) then
        begin

          if( FileMatches( ThisFolderName, Mask ) ) then
          begin
            fItemList.Add( TMGListItem.Create(
              '/' + ThisFolderPath,
              0,
              0, //PArseDate( BlobItem.Properties['Last-Modified'] ),
              mgitFolder ), true )
          end;
          LastFolderPath := ThisFolderPath;
        end;

        if( IncSubFolders ) then
        begin
          Filename := ExtractCloudName( BlobItem.Name );
          if( FileMatches( Filename, Mask ) ) then
          begin
            fItemList.Add( TMGListItem.Create(
              '/' + BlobItem.Name,
              0,
              ParseDate( GetProp(BlobItem, 'Last-Modified' ) ),
              mgitFile ), true )
          end;
        end
        else
        begin
          Filename := ExtractCloudName( BlobItem.Name );
          SubName := StringReplace( BlobItem.Name, Path, '', [rfIgnoreCase] );

          if ( FileMatches( Filename, Mask ) ) and
          ( IncSubFolders or (Pos( '/', SubName)<1) ) then
          begin
            fItemList.Add( TMGListItem.Create(
              '/' + BlobItem.Name,
              StrToIntDef( GetProp( BlobItem, 'Content-Length'), 0 ),
              ParseDate( GetProp( BlobItem, 'Last-Modified' ) ),
              mgitFile ), true );
          end;
        end;

      end;
    until NextMarker='';
    fItemList.Sort;
  finally
    FreeAndNil( OptionalParams );
  end;
  Result := fItemList.Count;
end;
{$endif}

procedure TMGAzureConnection.PropertiesChanged;
begin
  fConnAzure.AccountName := fProperties.Values['AccountName'];
  fConnAzure.AccountKey := fProperties.Values['AccountKey'];
  fContainerName := fProperties.Values['Container'];
  fCaseSensitive := (fProperties.Values['CaseSensitive']='') or SameText(fProperties.Values['CaseSensitive'],'yes');
  fPublicRead := SameText( fProperties.Values['PublicRead'], 'yes' );
end;

// MG 2020-01-29: Previous version used PutBlockBlob which would cause errors on large files.
procedure TMGAzureConnection.PutFile(Localfilename,
  DestStorageFilename: String);
var
  Ar: TArray<Byte>;
  SrcStream: TFileStream;
  Buffer: TBytes;
  BlockNum, LastSize, ThisRead: integer;
  BlockNumStr, BlobName, BlockID: String;

  BlockList: TList<TAzureBlockListItem>;
  Base64: TBase64Encoding;
const
  BUFSIZE = 3999999; // So disappointed.  Delphi's 2019 still uses pre-"2016-05-31" REST API. That means 195GB limit
begin
  AssertConnected;
  if( LocalFileSize( Localfilename ) >  199999950000 ) then
    RaisePutFileError( DestStorageFilename + '" (too large)' );

  LastSize := -1;
  BlockNum := 0;
  SrcStream := nil;
  BlockList := nil;
  Base64 := TBase64Encoding.Create;


  try
    BlockList := TList<TAzureBlockListItem>.Create;
    SrcStream := TFileStream.Create( LocalFilename, fmOpenRead or fmShareDenyNone );
    SetLength( Buffer, BUFSIZE );
    BlobName := EFP( '', DestStorageFilename, false, false );

    repeat
      if( BlockNum > 50000 ) then // REST API limit
        RaisePutFileError( DestStorageFilename );
      ThisRead := SrcStream.Read( Buffer, BUFSIZE );
      if( ThisRead > 0 ) then
      begin
        if( LastSize <> ThisRead ) then
        begin
          SetLength( Ar, ThisRead );
          LastSize := ThisRead;
        end;
        Move( Buffer[0], Ar[0], ThisRead );   // OMG, I switched the order?!?!?
        BlockNumStr := Format('%.9d', [BlockNum] );
        BlockId := Base64.Encode( BlockNumStr );
        //If Not fBlobService.PutBlock( fContainerName, BlobName, BlockId, Ar ) then
{$if CompilerVersion = 30 } // 30 = Seattle(10.0), 31=Berlin (10.1), 32=Tokyo(10.2), 33=Rio(10.3), 34=Sydney(10.4)
        If Not fBlobService.PutBlock( fContainerName, BlobName, BlockId, Ar,
          '',  '', nil ) then
{$else}
        If Not fBlobService.PutBlock( fContainerName, BlobName, '', BlockId, Ar,
          '',  nil ) then
{$endif}
          RaisePutFileError( DestStorageFilename );
        BlockList.Add( TAzureBlockListItem.Create( BlockID, abtUncommitted ) );
        Inc( BlockNum );
      end;
    until ThisRead = 0;
    if fBlobService.PutBlockList(fContainerName, BlobName, BlockList) = false then
          RaisePutFileError( DestStorageFilename );
  finally
    FreeAndNil( Base64 );
    FreeAndNil( BlockList );
    FreeAndNil( SrcStream );
  end;

end;

procedure TMGAzureConnection.RenameFile(StorageFilenameOld,
  StorageFilenameNew: String);
begin
  AssertConnected;
  try
    if( Self.FileExists( StorageFilenameNew ) ) then
      RaiseRenameExistsError( StorageFilenameNew );
    self.CopyFile(StorageFilenameOld, StorageFilenameNew );
    self.DeleteFile( StorageFilenameOld );
  Except on E:Exception do
    RaiseRenameError( StorageFilenameOld, StorageFilenameNew );
  end;

end;

procedure TMGAzureConnection.SelectContainer(ContainerName: String);
begin
  AssertConnected;
  Containername := LowerCase( ContainerName );
  if( Not ContainerExists( ContainerName ) ) then
    RaiseError('Container doesn''t exist: ' + ContainerName );
  fContainerName := ContainerName;
end;

end.
