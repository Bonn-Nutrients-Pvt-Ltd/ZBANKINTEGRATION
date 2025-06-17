@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_BANKPAYABLE
  provider contract transactional_query
  as projection on ZR_BANKPAYABLE
{
  key Vutdate,
  key Unit,
  key Vutacode,
  key Createdtime,
  Vutatag,
  TransType,
  Vutaacode,
  Vutamt,
  Custref,
  Vutref,
  Vutnart,
  Vutcostcd,
  Vutbgtcd,
  Vutloccd,
  Vutemail,
  UTR,            
  PostingDate,          
  PayStatus,
  Log,        
  InstructionRefNum,
  UniqTracCode,
  UploadFileName,
  CreatedBy,
  CreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt
}
where IsPosted = ''
