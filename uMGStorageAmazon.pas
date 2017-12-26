unit uMGStorageAmazon;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Masks, Vcl.Forms,
  Data.Cloud.CloudAPI, Data.Cloud.AmazonAPI, Vcl.StdCtrls, System.StrUtils,
  HTTPApp, System.Types, System.IOUtils, uMGStorage;

  type

  TMGAmazonStorageService = class ( TAmazonStorageService )
    function InitHeaders(const BucketName: string): TStringList;
    procedure AddAndValidateHeaders(const defaultHeaders, customHeaders: TStrings);
    function GetACLTypeString(BucketACL: TAmazonACLType): string;
    procedure AddS3MetadataHeaders(Headers, Metadata: TStrings);
    function UploadObject(const BucketName, ObjectName: string; Content: TArray<Byte>; ReducedRedundancy: Boolean = false;
                          Metadata: TStrings = nil;
                          Headers: TStrings = nil; ACL: TAmazonACLType = amzbaNotSpecified;
                          ResponseInfo: TCloudResponseInfo = nil): Boolean;
    function BuildQueryParameterString(const QueryPrefix: string; QueryParameters: TStringList;
                                                         DoSort, ForURL: Boolean): string; override;
    constructor Create(const ConnectionInfo: TAmazonConnectionInfo);

 end;
 TMGAmazonConnection = class(TMGStorageService)
      fConnAmazon: TAmazonConnectionInfo;
      fStorageService: TMGAmazonStorageService;
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
    procedure GetFileListEx( Path, Mask: String; Dest: TStrings; IncSubfolders: Boolean );
    function GetFileList( Path, Mask: String; IncSubfolders: Boolean ): integer; override;
    procedure DeleteFile( Storagefilename: String ); override;
    function FileExists( StorageFilename: String ): boolean; override;
    procedure RenameFile( StorageFilenameOld, StorageFilenameNew: String ); override;
    procedure CopyFile( StorageFilenameOld, StorageFilenameNew: String ); override;

    function CalcFileURL( StorageFilename: String ) : String; override;
  end;


implementation

{ TMGFTPConnection }
{ TMGAmazonStorageService }
// This class is mostly copied from Data.Cloud.AmazonAPI, with some tweaks to fix object names
procedure TMGAmazonStorageService.AddAndValidateHeaders(const defaultHeaders,
  customHeaders: TStrings);
var
  IsInstanceOwner: Boolean;
  RequiredHeaders: TStrings;
  I: Integer;
begin
  RequiredHeaders :=  GetRequiredHeaderNames(IsInstanceOwner);
  for I := 0 to customHeaders.Count - 1 do
  begin
    if not (RequiredHeaders.IndexOfName(customHeaders.Names[I]) > -1) then
       defaultHeaders.Append(customHeaders[I]);
  end;
  if IsInstanceOwner then
    FreeAndNil(RequiredHeaders);
end;

// copied from Data.Cloud.AmazonAPI
procedure TMGAmazonStorageService.AddS3MetadataHeaders(Headers,
  Metadata: TStrings);
var
  I, Count: Integer;
  MetaName: string;
begin
  //add the specified metadata into the headers, prefixing each
  //metadata header name with 'x-ms-meta-' if it wasn't already.
  if (MetaData <> nil) and (Headers <> nil) then
  begin
    Count := MetaData.Count;
    for I := 0 to Count - 1 do
    begin
      MetaName := MetaData.Names[I];
      if not AnsiStartsText('x-amz-meta-', MetaName) then
        MetaName := 'x-amz-meta-' + MetaName;
      Headers.Values[MetaName] := MetaData.ValueFromIndex[I];
    end;
  end;
end;

function TMGAmazonStorageService.BuildQueryParameterString(
  const QueryPrefix: string; QueryParameters: TStringList; DoSort,
  ForURL: Boolean): string;
var
  Count: Integer;
  I: Integer;
  lastParam, nextParam: string;
  QueryStartChar, QuerySepChar, QueryKeyValueSepChar: Char;
  CurrValue: string;
  CommaVal: string;
begin
  //if there aren't any parameters, just return the prefix
  if (QueryParameters = nil) or (QueryParameters.Count = 0) then
    Exit(QueryPrefix);

  if ForURL then
  begin
    //If the query parameter string is beign created for a URL, then
    //we use the default characters for building the strings, as will be required in a URL
    QueryStartChar := '?';
    QuerySepChar := '&';
    QueryKeyValueSepChar := '=';
  end
  else
  begin
    //otherwise, use the characters as they need to appear in the signed string
    QueryStartChar := FQueryStartChar;
    QuerySepChar := FQueryParamSeparator;
    QueryKeyValueSepChar := FQueryParamKeyValueSeparator;
  end;

  if DoSort and not QueryParameters.Sorted then
    SortQueryParameters(QueryParameters, ForURL);

  Count := QueryParameters.Count;

  lastParam := QueryParameters.Names[0];
  CurrValue := Trim(QueryParameters.ValueFromIndex[0]);

  //URL Encode the firs set of params
  URLEncodeQueryParams(ForURL, lastParam, CurrValue);

  Result := QueryPrefix + QueryStartChar + lastParam + QueryKeyValueSepChar + CurrValue;

  //in the URL, the comma character must be escaped. In the StringToSign, it shouldn't be.
  //this may need to be pulled out into a function which can be overridden by individual Cloud services.
  if ForURL then
    CommaVal := '%2c'
  else
    CommaVal := ',';

  //add the remaining query parameters, if any
  for I := 1 to Count - 1 do
  begin
    nextParam := Trim(QueryParameters.Names[I]);
    CurrValue := QueryParameters.ValueFromIndex[I];

    URLEncodeQueryParams(ForURL, nextParam, CurrValue);

    //match on key name only if the key names are not empty string.
    //if there is a key with no value, it should be formatted as in the else block
    if (lastParam <> EmptyStr) and (AnsiCompareText(lastParam, nextParam) = 0) then
      Result := Result + CommaVal + CurrValue
    else begin
      if (not ForURL) or (nextParam <> EmptyStr) then
        Result := Result + QuerySepChar + nextParam + QueryKeyValueSepChar + CurrValue;
      lastParam := nextParam;
    end;
  end;
end;

constructor TMGAmazonStorageService.Create(
  const ConnectionInfo: TAmazonConnectionInfo);
begin
  inherited;
end;

// copied from Data.Cloud.AmazonAPI
function TMGAmazonStorageService.GetACLTypeString(
  BucketACL: TAmazonACLType): string;
begin
  case BucketACL of
    amzbaPrivate: Result := 'private';
    amzbaPublicRead: Result := 'public-read';
    amzbaPublicReadWrite: Result := 'public-read-write';
    amzbaAuthenticatedRead: Result := 'authenticated-read';
    amzbaBucketOwnerRead: Result := 'bucket-owner-read';
    amzbaBucketOwnerFullControl: Result := 'bucket-owner-full-control';
  end;
end;

// copied from Data.Cloud.AmazonAPI
function TMGAmazonStorageService.InitHeaders(
  const BucketName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := false;
  Result.Duplicates := TDuplicates.dupIgnore;
  Result.Values['host'] := GetConnectionInfo.VirtualHost(BucketName);
  Result.Values['x-amz-content-sha256'] := 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'; //empty string
  Result.Values['x-amz-date'] := ISODateTime_noSeparators;
end;

// copied from Data.Cloud.AmazonAPI with minor tweak
function TMGAmazonStorageService.UploadObject(const BucketName,
  ObjectName: string; Content: TArray<Byte>; ReducedRedundancy: Boolean;
  Metadata, Headers: TStrings; ACL: TAmazonACLType;
  ResponseInfo: TCloudResponseInfo): Boolean;
var
  url: string;
  LHeaders: TStringList;
  QueryPrefix: string;
  Response: TCloudHTTP;
  contentStream: TBytesStream;
  responseStr: string;
  ContentLength: Integer;
  function MyURLEncode( ASrc: String ) : String;
  var
    Ch: Char;
  begin
    Result := '';
    for Ch in ASrc do
    begin
      if ( Pos( Ch, '*#%<> []''' )>0) or ( Ch <=' ') or ( Ch > 'z') then
        Result := Result + '%' + IntToHex(Ord( Ch ), 2)
      else
        Result := Result + Ch;
    end;
  end;

const
  CLASS_REDUCED_REDUNDANCY = 'REDUCED_REDUNDANCY';
begin
  if (BucketName = EmptyStr) or (ObjectName = EmptyStr) then
    Exit(False);
  // MG Modified to call MyURLEncode:
  url := GetConnectionInfo.StorageURL(BucketName) + '/' + MyURLEncode( ObjectName );

  LHeaders := InitHeaders(BucketName);
  //if unspecified amazon sets content-type to 'binary/octet-stream';

  if ReducedRedundancy then
    LHeaders.Values['x-amz-storage-class'] := CLASS_REDUCED_REDUNDANCY;

  if ACL <> amzbaNotSpecified then
    LHeaders.Values['x-amz-acl'] := GetACLTypeString(ACL);

  if Headers <> nil then
    AddAndValidateHeaders(LHeaders,Headers);

  AddS3MetadataHeaders(LHeaders, Metadata);

  QueryPrefix := Format('/%s/%s', [BucketName, ObjectName]);

  contentStream := TBytesStream.Create(Content);
  contentStream.position := 0;
  ContentLength := contentStream.Size;

  if ContentLength > 0 then
    LHeaders.Values['x-amz-content-sha256'] :=  TCloudSHA256Authentication.GetStreamToHashSHA256Hex(contentStream);
  LHeaders.Values['Content-Length'] := IntToStr(ContentLength);

  Response := nil;
  try
    Response := IssuePutRequest(url, LHeaders, nil, QueryPrefix, ResponseInfo, contentStream, responseStr);
    ParseResponseError(ResponseInfo, responseStr);
    Result := (Response <> nil) and ((Response.ResponseCode = 200) or (Response.ResponseCode = 100));
  finally
    if Assigned(Response) then
      FreeAndNil(Response);
    FreeAndNil(LHeaders);
    FreeAndNil(contentStream);
  end;
end;

{ TMGAmazonConnection }
function TMGAmazonConnection.CalcFileURL(StorageFilename: String): String;
begin
    Result := fServerProtocol + '://'+fServer+'/' + fContainerName + '/' + EFP( '', StorageFilename, false, false );
end;

procedure TMGAmazonConnection.Connect;
var
  SL: TStrings;
begin
  if( fStorageService <> nil ) then
    FreeAndNil( fStorageService );
  fStorageService := TMGAmazonStorageService(TAmazonStorageService.Create(fConnAmazon));
  SL := fStorageService.ListBuckets;
  if( SL <> nil ) then
  begin
    fConnected := true;
    FreeAndNil( SL );
  end
  else
  begin
    fConnected := false;
    raise Exception.Create('Connection Error');
  end;
end;

function TMGAmazonConnection.ContainerExists(ContainerName: String): Boolean;
var
  SL: TStrings;
  S: String;
  I, P: integer;
begin
  SL := Nil;
  Result := false;
  try
    SL := fStorageService.ListBuckets;
    for I := 0 to SL.Count-1 do
    begin
      S := SL[i];
      P := Pos( '=', S );
      if( P > 0 ) then
        Result := SameText( ContainerName, Copy( S, 1, P-1 ) )
      else
        Result := SameText( ContainerName, S );
      if( Result ) then
        break;
    end;
  finally
    if( SL <> nil ) then
      FreeAndNil( SL );
  end;

end;

procedure TMGAmazonConnection.CopyFile(StorageFilenameOld,
  StorageFilenameNew: String);
begin
  if Not fStorageService.CopyObject( fContainerName, EFP( '', StorageFilenameNew, false, false ), fContainerName, EFP( '', StorageFilenameOld, false, false ) ) then
    RaiseCopyError( StorageFilenameOld, StorageFilenameNew );
end;

constructor TMGAmazonConnection.Create( ConnectionString: String);
begin
    fConnAmazon  := TAmazonConnectionInfo.Create( nil );
    fPublicRead := false;
    inherited;
    fSupportsContainers := true;
    fStorageService := nil;
end;

procedure TMGAmazonConnection.CreateContainer(ContainerName: String);
begin
  ContainerName := LowerCase( ContainerName );
  if( Not fStorageService.CreateBucket( ContainerName ) ) then
    raise Exception.Create('Unable to create bucket ' + ContainerName );
end;

procedure TMGAmazonConnection.DeleteFile(Storagefilename: String);
begin
  if( self.FileExists( StorageFilename ) ) then
  if Not fStorageService.DeleteObject( fContainerName, EFP( '', StorageFilename, false, false )) then
        RaiseDeleteFileError( StorageFilename );
end;

procedure TMGAmazonConnection.DeleteFolder(Folder: String; Recursive: Boolean);
var
  ToDelete: TStringList;
  Filename: String;
begin
  if IsRootFolder(Folder) then
    RaiseDeleteFolderRootError;
  ToDelete := TStringList.Create;
  try
    GetFileListEx( EFP( '', Folder, false, false ), '*', ToDelete, true );
    if( Recursive = false ) and ( ToDelete.Count > 0 ) then
        RaiseDeleteFolderNotEmptyError( Folder );
    for Filename in ToDelete  do
    begin
      if Not fStorageService.DeleteObject( fContainerName, Filename ) then
        RaiseDeleteFileError( Filename );
    end;
  finally
    ToDelete.Free;
  end;


end;

destructor TMGAmazonConnection.Destroy;
begin
  FreeAndNil( fStorageService );
  FreeAndNil( fConnAmazon );
  inherited;
end;

procedure TMGAmazonConnection.GetFile(Storagefilename,
  DestLocalFilename: String);
var
  Stream: TMemoryStream;
  ResponseInfo: TCloudResponseInfo;
begin
  Stream := TMemoryStream.Create;
  try
    ResponseInfo := TCloudResponseInfo.Create;
    fStorageService.GetObject( fContainerName, EFP( '', Storagefilename, false, false ), Stream, ResponseInfo );
    if( ResponseInfo.StatusCode = 404 ) then
      raise Exception.Create( ResponseInfo.StatusMessage );
    if( Pos( '\', DestLocalFilename ) > 0 ) or (Pos( '/', DestLocalFilename )>0 ) then
      ForceDirectories( ExtractFilePath( DestLocalFilename ) );
    Stream.SaveToFile( DestLocalFilename );
  finally
    FreeAndNil( Stream );
  end;

end;

function TMGAmazonConnection.FileExists( StorageFilename: String): boolean;
var
  SL: TStrings;
begin
  SL := fStorageService.GetObjectMetadata( fContainerName, EFP( '', StorageFilename ) );
  Result := SL <> nil;
  FreeAndNil( SL );
end;

function TMGAmazonConnection.GetContainerList: integer;
var
  SL: TStrings;
  S: String;
  I, P: integer;
begin
  fContainers.Clear;
  SL := Nil;
  try
    SL := fStorageService.ListBuckets;
    for I := 0 to SL.Count-1 do
    begin
      S := SL[i];
      P := Pos( '=', S );
      if( P > 0 ) then
        fContainers.Add( Copy( S, 1, P-1 ) )
      else
        fContainers.Add( S );
    end;
  finally
    if( SL <> nil ) then
      FreeAndNil( SL );
  end;
  Result := fContainers.Count;
end;

function TMGAmazonConnection.GetFileList(Path, Mask: String; IncSubfolders: Boolean): integer;
begin
  fItemList.Clear;
  GetFileListEx( EFP( '', Path, false, false ), Mask, nil, IncSubfolders );
  Result := fItemList.Count;
end;

procedure TMGAmazonConnection.GetFileListEx(Path, Mask: String; Dest: TStrings; IncSubfolders: Boolean);
var
  SL: TStringList;
  RelName,  Foldername, Filename: String;
  Res: TAmazonBucketResult;
  Obj: TAmazonObjectResult;
  cd, i: integer;
begin
  SL := TStringList.Create;
  try
    SL.Values['prefix'] := Path;
  // I have found that when you add more than one item to Amazon options, it seems to
  // fail with an invalid signature.  This is sort of a work-around, instead of creating my own
  // interface classe.  Things like delimiter, marker, max-keys, etc.
    Repeat
      Res := fStorageService.GetBucket( fContainerName, SL );
      if( Res = nil ) then
        RaiseError( 'Unexpected error getting list' );
      if( Res.Objects.Count > 0 ) then
        SL.Values['marker'] := Res.Objects[ Res.Objects.Count-1 ].Name;
      SL.Values['prefix'] := '';
      for i := 0 to Res.Objects.Count-1 do
      begin
        Obj := Res.Objects[i];
        if( Path = '' ) or ( Pos( Path, Obj.Name ) = 1 ) then
        begin
          RelName := StringReplace( Obj.Name, Path, '', [] );
          FolderName := ExtractCloudFolder( RelName );
          if( FolderName <> '' ) and (FileMatches( FolderName, Mask ) ) and (Dest = nil ) then
            fItemList.Add( TMGListItem.Create(
              IncludeTrailing( '/'+Path ) + FolderName,
              0,
              ParseDate( Obj.LastModified ),
              mgitFolder ), true );
          cd := CountCloudDepth( RelName );
          if( IncSubfolders = false ) and ( cd > 0 ) then
            continue;
          FolderName  := ExtractCloudPath( RelName );
          Filename := ExtractCloudName( FolderName );
          if( Filename <> '' ) and ( FileMatches( Filename, Mask ) ) and ( Dest = nil ) then
          begin
            fItemList.Add( TMGListItem.Create(
              '/' + FolderName,
              0,
              ParseDate( Obj.LastModified ),
              mgitFolder ), true )
          end;
          if( Dest = nil ) then
          begin
            if( FileMatches( ExtractCloudName( RelName ), Mask ) ) then
              fItemList.Add( TMGListItem.Create( '/'+Obj.Name, Obj.Size, ParseDate( Obj.LastModified ), mgitFile  ), fCaseSensitive)
          end
          else
            Dest.Add(Obj.Name);

        end
        else
          break;
      end;
    Until Res.IsTruncated = false;
    fItemList.Sort;
    FreeAndNil( Res );
  finally
    SL.Free;
  end;
end;


procedure TMGAmazonConnection.PropertiesChanged;
begin
  fConnAmazon.AccountName := fProperties.Values['AccountName'];
  fConnAmazon.AccountKey := fProperties.Values['AccountKey'];
  fContainerName := fProperties.Values['Container'];
  fReducedRedundancy := SameText( fProperties.Values['ReducedRedundancy'], 'yes' );
  fPublicRead := SameText( fProperties.Values['PublicRead'], 'yes' );
end;

procedure TMGAmazonConnection.RenameFile(StorageFilenameOld, StorageFilenameNew: String);
begin
  try
    if( Self.FileExists( StorageFilenameNew ) ) then
      RaiseRenameExistsError( StorageFilenameNew );
    self.CopyFile(StorageFilenameOld, StorageFilenameNew );
    self.DeleteFile( StorageFilenameOld );
  Except on E:Exception do
    RaiseRenameError( StorageFilenameOld, StorageFilenameNew );
  end;
end;

procedure TMGAmazonConnection.SelectContainer(ContainerName: String);
var
  Region: String;
  P: integer;
begin
  ContainerName := LowerCase( ContainerName );
  Region := fStorageService.GetBucketLocationXML( ContainerName );
  P := Pos( '<LocationConstraint', Region );
  if( P > 0 ) then
  begin
    Region := Copy( Region, P+1 );
    P := Pos( '>', Region );
    Region := Copy( Region, P+1 );
    P := Pos( '</LocationConstraint>', Region );
    if( P > 0 ) then
      fServer := 's3' + '-' + Copy( Region, 1, p-1 )+'.amazonaws.com'
    else
      fServer := 's3.amazonaws.com'
  end;
  fContainerName := ContainerName;
end;

procedure TMGAmazonConnection.PutFile(Localfilename, DestStoragefilename: String );
var
  Ar: TArray<Byte>;
  ACL: TAmazonACLType;
  S: String;
begin
  try
    FileToArray( LocalFilename, Ar );
    if( fPublicRead ) then
      ACL := amzbaPublicRead
    else
      ACL := amzbaPrivate;
      S := EFP( '', DestStorageFilename, false, false );
    fStorageService.UploadObject( fContainerName, S, Ar, fReducedRedundancy, nil, nil, ACL, nil);
    fFileURL := fServerProtocol + '://'+fServer+'/' + fContainerName + '/' + S;
  finally
    SetLength( Ar, 0 );
  end;
end;

end.


