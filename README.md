# MGStorage
A COM component for interfacing to Azure, Amazon, FTP, or file systems, for storing and retrieving files.  It provides basic operations for tasks like getting files lists, uploading, downloading, and deleting files from whatever backend is specificied in a generic and common manner.

For example, the 'PutFile' command is the same command whether the COM server is connected to a file system, FTP server, Amazon S3 provider or Azure BLOB provider, and will upload a file to the back end.

## Providers
The selection of a service (Azure, Amazon, FTP, File system) depends on the *Connection* string property.  The Connection property is a series of semicolon-seperated key values, usually starting with a 'provider=' definition.  Example defining Azure BLOB storage as the back end:

`obj.connection = 'provider=azureblob;'`

The *provider* value can be one of the following:
- azureblob
- amazons3
- file
- ftp

Each back-end provider may have certain attributes unique to it, but ignored by other providers.  These attribute names (but not their values) are case-insensitive.

---
### AzureBlob Backend Connection Properties

These values can appear in the connection properties for an Azure BLOB connection.  For example:

`obj.ConnectionString := 'provider=azureblob;accountname=myaccoount;';`


**AccountName**

The account name, as defined in the Access Keys menu item from your Azure S3 resource.

**AccountKey**

The account key, as defined in the Access Keys menu item from your Azure S3 resource.

**Container**

The container name from your Azure Storage resource (under Data Storage menu item).

**CaseSensitive**

Ignored for Azure Storage, as BLOB names are case sensitive

**PublicRead**

When creating a new container, this setting is 'yes' for new containers to be public-accessible, or 'no' (default) to be private.

---

### AmazonS3 Backend Connection Properties

These values can appear in the connection properties for an Amazon S3 connection.  For example:

`obj.ConnectionString := 'provider=amazons3;accountname=myaccoount;';`


**AccountName**

This is actually the Access Key from your Amazon S3 console for a user.

**AccountKey**

This is the *Secret access key* that can only be seen when you create a new Access Key in your AWS console.

**Container**

This is your bucket name.

**PublicRead**

If 'yes', then new files and containes are publicly accessible.  If 'no' (default), then files and containers are no publicly accessible.

---

### File Backend Connection Properties


These values can appear in the connection properties for a File connection.  For example:

`obj.ConnectionString := 'provider=file;username=myusername;';`

**Username**

If Basefolder is a UNC path (i.e., //server/sharename), then this is the username used to connect to the given share.  If the path is already connected, no new connection is created.

**Password**

If Basefolder is a UNC path (i.e., //server/sharename), then this is the password used to connect to the given share.   If the path is already connected, no new connection is created.

**Basefolder**

This designates the full folder path to be used as the base path for all operations.  It can be a UNC share path, where Username and Password are then also used.

**TinyFiles**

This is a testing/debuggin option.  When 'yes', then all files placed into the destination folder are really just very small text files.  For production, and by default, this value is 'no', which will store all files with their original content.

--

### FTP Backend Connection Properties

These values can appear in the connection properties for an FTP connection.  For example:

`obj.ConnectionString := 'provider=ftp;username=myusername;';`

**AllowLeading**

If 'yes' (default), then paths that start with a / will retain their leading /.  If 'no' then the leading / will be removed.  

**Username**

The FTP account username.

**Password**

The FTP account password.

**Port**

The FTP port, defaults to 21.

**Server**

The FTP server host name or IP address.

**Passive**

If 'yes' (default), then the FTP connection is a passice connection, if 'no' then it's an active connection.

**TransferMode**

ASCII or Binary (def)

**CaseSensitive**
    
If 'yes' (default) then lists of files will contain names that vary only by case.  If 'no', then names will be unique regardless of case.

**tls**

Indicates TLS support level. 'NoTLSSupport' means that TLS is not enabled.  A 'yes' value (default) implies that TLS is enabled, and the *ssllevel* option has a value.


**ssllevel** 

This selects the ssl level and can be one of the following:
SSLv2, SSLv23, SSLv3, TLSv1, sslvTLSv1_1, sslvTLSv1_2 (default);

**usetls**

Defines to use TLS in one of the following methods: ImplicitTLS, RequireTLS, ExplicitTLS (default).

### Using TLS/SSL

In order to TLS or SSL features, OpenSSL version 1u, as well as the Visual Studio 2017 distrubition package must be installed, and accessible in either a system folder, a PATH folder, or the same folder as your executable.

### Methods

**Connect**

Establishes connection to the back end.

**ContainerExists( ContainerName: String ) : Boolean**

Returns true if the given *ContainerName* container/bucket exists.

**CopyFile( StorageFilenameOld, StorageFilenameNew: String );**

Copies file on backend from *StorageFilenameOld* to *StorageFilenameNew*.

**CreateContainer( ContainerName: String );**

Creates a new container on the back end named *ContainerName*.

**procedure DeleteFile( Storagefilename: String ); virtual; abstract;**

Deletes the object named *Storagefilename* from the back end.


**procedure DeleteFolder( Folder: String; Recursive: Boolean );**

Deletes the folder named *Folder* from the back end.  Will not delete the folder if it isn't empty, unless *Recursive* is true.

**function FileExists( StorageFilename: String ): boolean;**

Returns true if *StoreageFilename* exists in the back end.


**GetContainerCount: integer;**

Returns the count of containers found on the back end.

**GetContainerList: integer;**

Populates an internal list of container names, and returns the count of containers found.

**GetContainerName( Index: integer ): String;**

Returns a the container name from the internal list of containers as a string (after calling GetContainerList).

**GetFile( Storagefilename, DestLocalFilename: String );**

Retrieves a file from the back end named *StorageFilename* and stores it locally in a file named *DestLocalFilename*.


**GetFileCount: integer;**

Retrieves the count of files in the internal file list, as retreived by calling *GetFileList*.


**GetFileDate( Index: Integer ): TDateTime;**

Returns the date of the file at position *Index* in the internal file list, as retreived by calling *GetFileList*.

**GetFileFullPath( Index: Integer ): String;**

Returns the full back end path of the file at position *Index* in the internal file list, as retreived by calling *GetFileList*.

**GetFileList( Path, Mask: String; IncSubfolders: Boolean  ): integer;**

Populates an internal file list with items from the back end.  *Path* indicates the folder path, while *Mask* indicates wild cards (asterisks) for matching files.  Set the *IncSubFolders* paramter to truie to include sub folders.

**GetFileName( Index: Integer ): String;**

Returns the base filename of the file at position *Index* in the internal file list, as retreived by calling *GetFileList*.


**GetFileSize( Index: Integer ): integer;**

Returns the file size of the file at position *Index* in the internal file list, as retreived by calling *GetFileList*.

**GetFolder: String;**

Retrieves the current folder on the back end.

**GetPath(CloudName: String): string;**

Returns the full cloud path for an object named *CloudName* from the back end.

**GetProperty( Propertyname: String ) : String;**

Retrieves the value is a specific property attribute.  These are normally set in the *ConnectionString* property but can be accessed individually.


**IsFile( Index: Integer ): Boolean;**

Returns true if the element *Index* from the internal file list (from *GetFileList*) is a file, or false if it's a folder.

**PutFile( Localfilename, DestStorageFilename: String );**

Uploads a local file named *Localfilename* to the back end, naming it *DestStorageFilename*.

**RenameFile( StorageFilenameOld, StorageFilenameNew: String );**

Renames the back end file named *StorageFilenameOld* to *StorageFilenameNew*.


**SelectContainer( ContainerName: String );**

Selects the back end container  named *ContainerName* as the current container.

**SetFolder( NewFolder: String );**

Sets the current back end folder to *NewFolder*.

**SetProperty( Propertyname, Value: String );**

Sets the value of a specific property attribute.  These are normally set in the *ConnectionString* property but can be accessed individually. 

### Properties

**ConnectionString: String;**

Specifies the connection string with the specific back-end provider and it's attributes.

**Connected: Boolean;**

Returns true if currently connected to a back end, false if not.

**SupportsContainers: Boolean;**

Returns true if the back end supports containers/buckets.  This is normally not true for things like the File and FTP providers, and true for S3 and 

---
Written in Delphi.
http://www.mariogiannini.com
