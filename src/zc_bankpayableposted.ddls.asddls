@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Posted Bank Payable'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZC_BANKPAYABLEPOSTED   
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
  AccountingDocument,
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
where IsPosted = 'X' and IsDeleted = ''
