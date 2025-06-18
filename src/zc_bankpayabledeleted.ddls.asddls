@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DELETED BANK PAYABLE'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_BANKPAYABLEDELETED provider contract transactional_query
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
where IsPosted = '' and IsDeleted = 'X'
