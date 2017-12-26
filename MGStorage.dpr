library MGStorage;

uses
  ComServ,
  MGStorage_TLB in 'MGStorage_TLB.pas',
  uMGStorage in 'uMGStorage.pas',
  uMGStorageAmazon in 'uMGStorageAmazon.pas',
  uMGStorageAzure in 'uMGStorageAzure.pas',
  uMGStorageFile in 'uMGStorageFile.pas',
  uMGStorageFTP in 'uMGStorageFTP.pas',
  uConnection in 'uConnection.pas' {Connection: CoClass};

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  DllInstall;

{$R *.TLB}

{$R *.RES}

begin
end.
