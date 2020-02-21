unit uMGStorageFile;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Masks, Vcl.Forms,
  System.IOUtils, uMGStorage;

  type

  TMGFileConnection = class(TMGStorageService)
      fNetResource, fUsername, fPassword, fBaseFolder: String; // Always ends in '/'
      fTinyFiles: Boolean;
  private
  protected
    procedure PropertiesChanged; override;
    function WP( S: String ) : String; // Windows Path (uses '\' seperator)
    function MyEFP( Base, Path: String; Delimit: Boolean = false ) : String; // Evaluate Full path
    function GetFileListEx( Path, Mask: String; IncSubfolders: Boolean  ): integer;
    function ConnectIfNeeded: boolean;
    procedure DisConnectIfNeeded;


  public
    constructor Create( ConnectionString: String );
    destructor Destroy; override;

    procedure Connect; override;
    procedure DeleteFolder( Folder: String; Recursive: Boolean ); override;

    procedure PutFile( Localfilename, DestStorageFilename: String ); override;
    procedure GetFile( Storagefilename, DestLocalFilename: String ); override;
    function GetFileList( Path, Mask: String; IncSubfolders: Boolean  ): integer; override;
    procedure DeleteFile( Storagefilename: String ); override;
    function FileExists( StorageFilename: String ): boolean; override;
    function CalcFileURL( StorageFilename: String ) : String; override;
    procedure RenameFile( StorageFilenameOld, StorageFilenameNew: String ); override;
    procedure CopyFile( StorageFilenameOld, StorageFilenameNew: String ); override;
  end;


implementation

{ TMGFileConnection }

function TMGFileConnection.CalcFileURL(StorageFilename: String): String;
begin
  AssertConnected;
  Result := 'file://' + EFP( fBaseFolder, StorageFilename );
end;

procedure TMGFileConnection.Connect;
begin
  if ConnectIfNeeded = false then
    RaiseError( 'Error connecting');

  if( fBaseFolder = '' ) or ( Not DirectoryExists(  fBaseFolder ) ) then
    RaiseError( 'Folder does not exist');
  fConnected := true;
end;

function TMGFileConnection.ConnectIfNeeded: Boolean;
var
   NetResource: TNetResource;
   P: integer;
   LastErr: Cardinal;
   LastErrStr: String;
   ConnRes: Cardinal;

begin
   Result := true;
   P := Pos( '//', fBaseFolder );
   if( P < 1 ) then
      exit;
   if( P = 1 ) then
   begin
      fNetResource := StringReplace( fBaseFolder, '/', '\', [rfReplaceAll] );
      P := Pos( '\', fNetResource, 3 );
      if P > 1 then
         fNetResource := Copy( fNetResource, 1, p-1 )
      else
         fNetResource := '';
   end;


   try
      if( fNetResource <> '') then
      begin
         ZeroMemory(@NetResource, sizeof(TNetResource));
         with NetResource do begin
           dwType      :=  RESOURCETYPE_ANY;
           lpLocalName  :=  nil;
           lpProvider  :=  nil;
           lpRemoteName :=  PChar( fNetResource );
         end;
         ConnRes := WNetAddConnection2(NetResource, pchar(fPassword), pchar(fUsername), 0);

         if ConnRes = ERROR_SESSION_CREDENTIAL_CONFLICT  then
         begin
            WNetCancelConnection2(PChar( fNetResource ), 0, false);
            ConnRes := WNetAddConnection2(NetResource, pchar(fPassword), pchar(fUsername), 0);
         end;

         if( ConnRes <> NO_ERROR ) then
         begin
            LastErr := GetLastError;
            LastErrStr :=SysErrorMessage( LastErr );
            Result := false;
         end
         else
            fConnected := true;
      end;
   except on E:Exception do
      begin
         fError := 'Error: ' + E.Message;
         Result := false;
      end;
   end;
end;

procedure TMGFileConnection.CopyFile(StorageFilenameOld,
  StorageFilenameNew: String);
var
  SrcFile, DestFile: String;
begin
  AssertConnected;
  SrcFile := MyEFP( fBaseFolder, StorageFilenameOld );
  DestFile := MyEFP( fBaseFolder, StorageFilenameNew );
  if WinAPI.Windows.CopyFile( @SrcFile[1], @DestFile[1], false ) = false then
    RaiseCopyError( StorageFilenameOld, StorageFilenameNew );
end;

constructor TMGFileConnection.Create( ConnectionString: String);
begin
  inherited;
  fConnected := false;
  fBaseFolder :='';
  fTinyFiles := false;
  fServer := '';
  fUsername := '';
  fPassword := '';
  SetConnectionString( ConnectionString );
end;

procedure TMGFileConnection.DeleteFile(Storagefilename: String);
var
  S: String;
begin
  AssertConnected;
  S := MyEFP( fBaseFolder, StorageFilename );
  if( System.sysUtils.FileExists( S ) ) then
    if System.SysUtils.DeleteFile( S ) = false then
      RaiseDeleteFileError( StorageFilename );
end;

procedure TMGFileConnection.DeleteFolder(Folder: String; Recursive: Boolean);
  procedure MyDeleteFolder(const Name: string; Recursive: Boolean);
  var
    F: TSearchRec;
  begin
    if FindFirst(Name + '\*', faAnyFile, F) = 0 then begin
      try
        repeat
          if (F.Attr and faDirectory <> 0) then begin
            if (F.Name <> '.') and (F.Name <> '..') then
            begin
              if( Recursive ) then
              begin
                MyDeleteFolder(Name + '\' + F.Name, Recursive);
              end
              else
                 RaiseDeleteFolderNotEmptyError( Folder);
            end;
          end
          else
          begin
            if( Recursive ) then
            begin
              if not System.SysUtils.DeleteFile( WP( Name + '\' + F.Name) ) then
                RaiseDeleteFolderNoDeleteError( F.Name, Name );
            end
            else
              RaiseDeleteFolderNotEmptyError( Folder);
          end;
        until FindNext(F) <> 0;
      finally
        FindClose(F);
      end;
      if( RemoveDir(Name) = false ) then
        RaiseDeleteFolderNoDeleteError( '', Name );
    end;
  end;
begin
  AssertConnected;
  if IsRootFolder(Folder) then
    RaiseDeleteFolderRootError;
  Folder := MyEFP( fBaseFolder, Folder, false );
  if( System.SysUtils.DirectoryExists( Folder  ) ) then
    MyDeleteFolder( Folder, Recursive )
end;

destructor TMGFileConnection.Destroy;
begin
  inherited;
  DisconnectIfNeeded;
end;

procedure TMGFileConnection.DisConnectIfNeeded;
begin
   if( fConnected ) then
   begin
      WNetCancelConnection2(PChar( fNetResource ), 0, false);
      fConnected := false;
   end;
end;

procedure TMGFileConnection.GetFile(Storagefilename,
  DestLocalFilename: String);
var
  SrcFile: String;
begin
  AssertConnected;
  SrcFile := MyEFP( fBaseFolder, Storagefilename );
  if( Not System.SysUtils.FileExists( SrcFile ) ) then
    raise exception.Create('File not found: ' + Storagefilename );
  ForceDirectories( ExtractFilePath( DestLocalFilename ) );
  if WinAPI.Windows.Copyfile( @SrcFile[1], @DestLocalFilename[1], false ) = false then
      raise Exception.Create('Error getting file: ' + DestLocalFilename );
end;

function TMGFileConnection.FileExists(StorageFilename: String): boolean;
begin
  AssertConnected;
  Result := System.SysUtils.FileExists( MyEFP( fBaseFolder, StorageFilename  ) );
end;

function TMGFileConnection.GetFileList(Path, Mask: String; IncSubfolders: Boolean ): integer;
begin
  AssertConnected;
  fItemList.Clear;
  GetFileListEx( MyEFP( fBaseFolder, Path, true ), Mask, IncSubFolders );
  fItemList.Sort;
  Result := fItemList.Count;
end;

function TMGFileConnection.GetFileListEx(Path, Mask: String;
  IncSubfolders: Boolean): integer;
var
  Srch: TSearchRec;
  RelPath: String;
begin
  try
    if FindFirst(Path+'*', faAnyFile, Srch) = 0 then
    begin
      RelPath := '/' + StringReplace( StringReplace( Path, '\', '/', [rfReplaceAll]), fBaseFolder, '', [rfIgnoreCase] );
      repeat
        if (Srch.Attr and faDirectory) = faDirectory then
        begin
          if( Srch.Name <> '.' ) and (Srch.Name <> '..') then
          begin
            if( FileMatches( Srch.Name, Mask ) ) then
              fItemList.Add( TMGListItem.Create( RelPath+Srch.Name, 0, Srch.TimeStamp, mgitFolder), false );
            if IncSubFolders then
              GetFileListEx( Path + Srch.Name+'/', Mask, true );
          end;
        end
        else
        begin
          if( FileMatches( Srch.Name, Mask ) ) then
            fItemList.Add( TMGListItem.Create( RelPath+Srch.Name, srch.Size, Srch.TimeStamp, mgitFile), false );
        end;
      until FindNext(Srch) <> 0;
      FindClose(Srch);
    end;
    Result := fItemList.Count;
  except on E:Exception do
    begin
      raise Exception.Create( E.Message + ': ' + Path );
    end;
  end;

end;

function TMGFileConnection.MyEFP(Base, Path: String; Delimit: Boolean): String;
var
   Pre: String;
begin
   if( Pos( '//', Base ) > 0 ) then
      Pre := '\\'
   else
      Pre := '';

   Result := Pre + StringReplace( EFP( Base, Path, Delimit, false ), '/', '\', [rfReplaceAll] );
end;

procedure TMGFileConnection.PropertiesChanged;
begin
  fUsername := fProperties.Values['Username'];
  fPassword := fProperties.Values['Password'];

  fBaseFolder := IncludeTrailingPathDelimiter( fProperties.Values['Basefolder'] );
  if( fBaseFolder = '' ) then
    fBaseFolder := ExtractFilePath( Application.ExeName );
  fBaseFolder := StringReplace( fBaseFolder, '\', '/', [rfReplaceAll] );
  fTinyFiles := SameText(fProperties.Values['TinyFiles'], 'yes' );
end;

procedure TMGFileConnection.RenameFile(StorageFilenameOld,
  StorageFilenameNew: String);
var
  SrcFile, DestFile: String;
begin
  AssertConnected;
  SrcFile := MyEFP( fBaseFolder, StorageFilenameOld );
  DestFile := MyEFP( fBaseFolder, StorageFilenameNew );
  try
    TFile.Move( SrcFile, DestFile);
  except on E:Exception do
    RaiseRenameError( StorageFilenameOld, StorageFilenameNew );
  end;
end;

function TMGFileConnection.WP(S: String): String;
begin
  Result := StringReplace( S, '/', '\', [rfReplaceAll] );
end;

procedure TMGFileConnection.PutFile(Localfilename,
  DestStorageFilename: String );
var
  DestFile: String;
  SL: TStringList;
begin
  AssertConnected;
  AssertLocal( Localfilename );

  DestFile := MyEFP(fBaseFolder, DestStorageFilename, false);
  if( fTinyFiles ) then
  begin
    SL := TStringList.Create;
    try
      SL.Add( 'Src: ' + Localfilename );
      SL.Add( 'Dst: ' + DestFile);
      ForceDirectories( ExtractFilePath( DestFile ) );
      SL.SaveToFile( DestFile );
    finally
      SL.Free;
    end;
  end
  else
  begin
    ForceDirectories( ExtractFilePath( DestFile ) );
    if WinAPI.Windows.CopyFile( @Localfilename[1], @DestFile[1], false ) = false then
      raise Exception.Create('Error putting file ' + DestStorageFilename );
  end;
end;

end.
