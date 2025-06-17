@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_BANKPAYABLE
  as select from zbankpayable
{
  key vutdate as Vutdate,
  key unit as Unit,
  key vutacode as Vutacode,
  key createdtime as Createdtime,
  vutatag as Vutatag,
  trans_type as TransType,
  vutaacode as Vutaacode,
  vutamt as Vutamt,
  custref as Custref,
  vutref as Vutref,
  vutnart as Vutnart,
  vutcostcd as Vutcostcd,
  vutbgtcd as Vutbgtcd,
  vutloccd as Vutloccd,
  vutemail as Vutemail,
  utr as UTR,            
  postingdate as PostingDate,          
  instructionrefnum as InstructionRefNum,
  uniqtraccode as UniqTracCode,
  paymentstat as PayStatus,
  log  as Log,                
  uploadfilename as UploadFileName, 
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt
  
}
